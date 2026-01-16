# Validação e Testes - SCP Dynamic Controls

## 🧪 Script de Validação Terraform

### validation.tf

Adicione este arquivo ao seu projeto para validar as configurações:

```hcl
# validation.tf

# Validar que public_subnet_ids é fornecido quando necessário
resource "null_resource" "validate_subnet_ids" {
  count = var.deny_lb_in_public_subnets && length(var.public_subnet_ids) == 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "ERROR: deny_lb_in_public_subnets is true but public_subnet_ids is empty"
      echo "Please provide at least one subnet ID or set deny_lb_in_public_subnets to false"
      exit 1
    EOT
  }
}

# Validar que pelo menos um controle está habilitado
locals {
  enabled_controls_count = (
    (var.deny_ec2_public_ip ? 1 : 0) +
    (var.deny_elastic_ip_operations ? 1 : 0) +
    (var.deny_public_security_groups ? 1 : 0) +
    (var.deny_internet_facing_lb ? 1 : 0) +
    (var.deny_lb_in_public_subnets ? 1 : 0) +
    (var.deny_s3_public_access_changes ? 1 : 0)
  )
}

resource "null_resource" "validate_controls" {
  count = local.enabled_controls_count == 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "WARNING: All controls are disabled. This SCP will have no effect."
      echo "Please enable at least one control."
    EOT
  }
}

# Output para validação
output "validation_summary" {
  value = {
    enabled_controls_count = local.enabled_controls_count
    has_subnet_ids         = length(var.public_subnet_ids) > 0
    lb_subnet_control      = var.deny_lb_in_public_subnets
    configuration_valid = (
      local.enabled_controls_count > 0 &&
      (!var.deny_lb_in_public_subnets || length(var.public_subnet_ids) > 0)
    )
  }
}
```

## 🔍 Pré-Deploy Checklist

Antes de aplicar a SCP, verifique:

```bash
# 1. Validar sintaxe Terraform
terraform validate

# 2. Verificar plan
terraform plan -out=tfplan

# 3. Revisar controles que serão aplicados
terraform plan | grep -A 20 "enabled_controls"

# 4. Verificar targets
terraform plan | grep -A 5 "target_ids"

# 5. Confirmar subnets (se aplicável)
terraform plan | grep -A 5 "public_subnet_ids"
```

## 🧪 Testes por Controle

### 1. Testar EC2 Public IP (deny_ec2_public_ip = true)

```bash
# Deve FALHAR
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id subnet-xxxxx \
  --associate-public-ip-address

# Erro esperado:
# An error occurred (UnauthorizedOperation) when calling the RunInstances operation: 
# You are not authorized to perform this operation.

# Deve FUNCIONAR (sem public IP)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id subnet-xxxxx \
  --no-associate-public-ip-address
```

### 2. Testar Elastic IP Operations (deny_elastic_ip_operations = true)

```bash
# Allocate - Deve FALHAR
aws ec2 allocate-address --domain vpc

# Associate - Deve FALHAR
aws ec2 associate-address \
  --instance-id i-xxxxx \
  --allocation-id eipalloc-xxxxx

# Release - Deve FALHAR
aws ec2 release-address --allocation-id eipalloc-xxxxx
```

### 3. Testar Public Security Groups (deny_public_security_groups = true)

```bash
# IPv4 0.0.0.0/0 - Deve FALHAR
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# IPv6 ::/0 - Deve FALHAR
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --ip-permissions IpProtocol=tcp,FromPort=443,ToPort=443,Ipv6Ranges='[{CidrIpv6=::/0}]'

# CIDR específico - Deve FUNCIONAR
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 10.0.0.0/16
```

### 4. Testar Internet-Facing Load Balancers (deny_internet_facing_lb = true)

```bash
# ALB internet-facing - Deve FALHAR
aws elbv2 create-load-balancer \
  --name test-alb-public \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxxxx \
  --scheme internet-facing \
  --type application

# NLB internet-facing - Deve FALHAR
aws elbv2 create-load-balancer \
  --name test-nlb-public \
  --subnets subnet-xxx subnet-yyy \
  --scheme internet-facing \
  --type network

# ALB internal - Deve FUNCIONAR
aws elbv2 create-load-balancer \
  --name test-alb-internal \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxxxx \
  --scheme internal \
  --type application
```

### 5. Testar LB in Public Subnets (deny_lb_in_public_subnets = true)

```bash
# LB em subnet pública (da lista) - Deve FALHAR
aws elbv2 create-load-balancer \
  --name test-lb-public-subnet \
  --subnets subnet-PUBLIC-1 subnet-PUBLIC-2 \
  --scheme internal

# LB em subnet privada - Deve FUNCIONAR
aws elbv2 create-load-balancer \
  --name test-lb-private-subnet \
  --subnets subnet-PRIVATE-1 subnet-PRIVATE-2 \
  --scheme internal
```

### 6. Testar S3 Block Public Access (deny_s3_public_access_changes = true)

```bash
# Tentar modificar - Deve FALHAR
aws s3control put-public-access-block \
  --account-id 123456789012 \
  --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Erro esperado:
# An error occurred (AccessDenied) when calling the PutPublicAccessBlock operation
```

## 📊 Script de Teste Automatizado

```bash
#!/bin/bash
# test-scp-controls.sh

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuração
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
TEST_SUBNET="subnet-xxxxx"  # Substituir
TEST_SG="sg-xxxxx"          # Substituir

echo "==================================="
echo "SCP Controls Test Suite"
echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo "==================================="

# Função para testar comando
test_command() {
    local test_name=$1
    local command=$2
    local should_fail=$3
    
    echo -n "Testing: $test_name ... "
    
    if eval $command &>/dev/null; then
        if [ "$should_fail" = "true" ]; then
            echo -e "${RED}FAIL${NC} (Expected to be denied but succeeded)"
            return 1
        else
            echo -e "${GREEN}PASS${NC}"
            return 0
        fi
    else
        if [ "$should_fail" = "true" ]; then
            echo -e "${GREEN}PASS${NC} (Correctly denied)"
            return 0
        else
            echo -e "${RED}FAIL${NC} (Expected to succeed but was denied)"
            return 1
        fi
    fi
}

# Test 1: EC2 Public IP
echo -e "\n${YELLOW}1. Testing EC2 Public IP Control${NC}"
test_command \
    "EC2 with public IP" \
    "aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 --instance-type t3.micro --subnet-id $TEST_SUBNET --associate-public-ip-address --dry-run" \
    "true"

# Test 2: Elastic IP
echo -e "\n${YELLOW}2. Testing Elastic IP Control${NC}"
test_command \
    "Allocate EIP" \
    "aws ec2 allocate-address --domain vpc --dry-run" \
    "true"

# Test 3: Public Security Group
echo -e "\n${YELLOW}3. Testing Public Security Group Control${NC}"
test_command \
    "SG rule 0.0.0.0/0" \
    "aws ec2 authorize-security-group-ingress --group-id $TEST_SG --protocol tcp --port 443 --cidr 0.0.0.0/0 --dry-run" \
    "true"

# Test 4: Internet-Facing LB
echo -e "\n${YELLOW}4. Testing Internet-Facing LB Control${NC}"
test_command \
    "Internet-facing ALB" \
    "aws elbv2 create-load-balancer --name test-alb-$(date +%s) --subnets $TEST_SUBNET --scheme internet-facing --dry-run" \
    "true"

# Test 5: S3 Public Access
echo -e "\n${YELLOW}5. Testing S3 Public Access Control${NC}"
test_command \
    "S3 Block Public Access" \
    "aws s3control put-public-access-block --account-id $ACCOUNT_ID --public-access-block-configuration BlockPublicAcls=false" \
    "true"

echo -e "\n==================================="
echo "Test Suite Complete"
echo "==================================="
```

## 📈 Monitoramento de Violações

### CloudWatch Query para buscar denials

```bash
# Query CloudTrail logs para encontrar eventos bloqueados pela SCP
aws logs start-query \
  --log-group-name /aws/cloudtrail/organization-trail \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, userIdentity.principalId, eventName, errorCode, errorMessage
| filter errorCode = "AccessDenied"
| filter errorMessage like /implicit deny/
| sort @timestamp desc
| limit 100'
```

### Dashboard CloudWatch

```hcl
resource "aws_cloudwatch_dashboard" "scp_monitoring" {
  dashboard_name = "SCP-Denial-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudTrail", "ErrorCount", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "SCP Denials (Last Hour)"
        }
      }
    ]
  })
}
```

## 🔄 Rollback Rápido

Se os controles causarem problemas:

```bash
# Opção 1: Desabilitar controle específico
terraform apply -var='deny_ec2_public_ip=false'

# Opção 2: Remover todos os attachments
terraform apply -var='target_ids=[]'

# Opção 3: Rollback completo
terraform destroy -target=aws_organizations_policy_attachment.attach_to_targets
```

## 📋 Checklist Pós-Deploy

- [ ] Verificar que a policy foi criada: `aws organizations list-policies --filter SERVICE_CONTROL_POLICY`
- [ ] Confirmar attachments: `aws organizations list-policies-for-target --target-id ou-xxxxx --filter SERVICE_CONTROL_POLICY`
- [ ] Executar suite de testes em uma conta de teste
- [ ] Verificar CloudTrail logs para denials esperados
- [ ] Documentar controles ativos para o time
- [ ] Criar runbook para exceções temporárias
- [ ] Configurar alertas para denials inesperados
- [ ] Agendar revisão trimestral dos controles

## 🚨 Troubleshooting

### Problema: "Access Denied" ao criar SCP

**Solução**: Verificar que está usando credenciais do management account:
```bash
aws sts get-caller-identity
# Deve retornar o ID do management account
```

### Problema: Controle não está bloqueando

**Solução**: Verificar que a policy está anexada ao target correto:
```bash
aws organizations list-policies-for-target \
  --target-id 123456789012 \
  --filter SERVICE_CONTROL_POLICY
```

### Problema: Terraform mostra "no changes"

**Solução**: SCPs podem ter delay. Aguardar alguns minutos e testar novamente.
```bash
# Forçar refresh do state
terraform refresh
terraform plan
```
