# 🚀 Quick Start Guide - SCP Dynamic Controls

## ⚡ Deploy Rápido (5 minutos)

### Passo 1: Extrair o módulo
```bash
tar -xzf scp-deny-public-access-v2.tar.gz
cd scp-deny-public-access
```

### Passo 2: Criar seu arquivo main.tf
```bash
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # Usar credenciais do Management Account
  # assume_role {
  #   role_arn = "arn:aws:iam::111111111111:role/OrganizationAdminRole"
  # }
}

module "scp_deny_public" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Production"
  environment = "production"

  # ===== CONFIGURE SEUS CONTROLES AQUI =====
  
  # Bloquear EC2 com IP público?
  deny_ec2_public_ip = true
  
  # Bloquear Elastic IPs?
  deny_elastic_ip_operations = true
  
  # Bloquear Security Groups públicos?
  deny_public_security_groups = true
  
  # Bloquear Load Balancers internet-facing?
  deny_internet_facing_lb = true
  
  # Bloquear LBs em subnets públicas?
  deny_lb_in_public_subnets = true
  
  # Bloquear mudanças no S3 Block Public Access?
  deny_s3_public_access_changes = true

  # ===== CONFIGURAÇÕES =====
  
  # IDs das subnets públicas (necessário se deny_lb_in_public_subnets = true)
  public_subnet_ids = [
    "subnet-XXXXXXXXX",  # Substituir
    "subnet-YYYYYYYYY"   # Substituir
  ]

  # Targets: OU IDs ou Account IDs
  target_ids = [
    "ou-xxxx-yyyyyyyy"  # Substituir com seu OU ID
  ]

  tags = {
    Team       = "Security"
    ManagedBy  = "Terraform"
    Environment = "Production"
  }
}

# Outputs úteis
output "policy_id" {
  value = module.scp_deny_public.policy_id
}

output "enabled_controls" {
  value = module.scp_deny_public.enabled_controls
}
EOF
```

### Passo 3: Inicializar e aplicar
```bash
# Inicializar Terraform
terraform init

# Ver o que será criado
terraform plan

# Aplicar as mudanças
terraform apply
```

## 📋 Configurações por Cenário

### Cenário 1: Máxima Segurança (Production)
```hcl
deny_ec2_public_ip            = true
deny_elastic_ip_operations    = true
deny_public_security_groups   = true
deny_internet_facing_lb       = true
deny_lb_in_public_subnets     = true
deny_s3_public_access_changes = true
```

### Cenário 2: Desenvolvimento Flexível
```hcl
deny_ec2_public_ip            = false  # Permite testes
deny_elastic_ip_operations    = false  # Permite testes
deny_public_security_groups   = true   # Mantém segurança básica
deny_internet_facing_lb       = false
deny_lb_in_public_subnets     = false
deny_s3_public_access_changes = true   # Sempre proteger S3
```

### Cenário 3: Apenas Essenciais
```hcl
deny_ec2_public_ip            = false
deny_elastic_ip_operations    = false
deny_public_security_groups   = true   # ✅ Essencial
deny_internet_facing_lb       = false
deny_lb_in_public_subnets     = false
deny_s3_public_access_changes = true   # ✅ Essencial
```

## 🎯 Obter IDs Necessários

### Encontrar OU ID
```bash
# Listar todas as OUs
aws organizations list-organizational-units-for-parent \
  --parent-id r-xxxx

# Output: ou-xxxx-yyyyyyyy
```

### Encontrar Subnets Públicas
```bash
# Por tag
aws ec2 describe-subnets \
  --filters "Name=tag:Type,Values=Public" \
  --query 'Subnets[*].SubnetId' \
  --output table

# Por route table (subnets com IGW)
aws ec2 describe-route-tables \
  --filters "Name=route.destination-cidr-block,Values=0.0.0.0/0" \
  --query 'RouteTables[*].Associations[*].SubnetId' \
  --output table
```

### Verificar Account ID atual
```bash
aws sts get-caller-identity --query Account --output text
```

## ✅ Validação Pós-Deploy

```bash
# 1. Verificar que a policy foi criada
aws organizations list-policies --filter SERVICE_CONTROL_POLICY

# 2. Verificar attachments
terraform output

# 3. Ver controles habilitados
terraform output enabled_controls

# 4. Testar um controle (exemplo: EC2 public IP)
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.micro \
  --associate-public-ip-address
# Esperado: AccessDenied
```

## 🔧 Ajustes Comuns

### Desabilitar um controle temporariamente
```bash
# Editar main.tf e mudar de true para false
deny_internet_facing_lb = false

# Aplicar
terraform apply
```

### Adicionar mais targets
```bash
# Editar target_ids no main.tf
target_ids = [
  "ou-xxxx-yyyyyyyy",
  "123456789012",  # Novo account
  "ou-zzzz-wwwwww" # Nova OU
]

terraform apply
```

### Remover attachments (emergência)
```bash
# Opção 1: Via terraform
terraform apply -var='target_ids=[]'

# Opção 2: Via AWS CLI
aws organizations detach-policy \
  --policy-id p-xxxxx \
  --target-id ou-xxxx-yyyyyyyy
```

## 📊 Monitoramento

### Ver eventos bloqueados (CloudTrail)
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --max-results 10 \
  --query 'Events[?contains(CloudTrailEvent, `AccessDenied`)].CloudTrailEvent' \
  --output text
```

### Criar alarme para denials
```hcl
resource "aws_cloudwatch_log_metric_filter" "scp_denials" {
  name           = "SCPDenials"
  log_group_name = "/aws/cloudtrail/organization-trail"

  pattern = "{ $.errorCode = \"AccessDenied\" && $.errorMessage = \"*implicit deny*\" }"

  metric_transformation {
    name      = "SCPDenialCount"
    namespace = "Security/SCP"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "scp_denial_alarm" {
  alarm_name          = "scp-high-denial-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SCPDenialCount"
  namespace           = "Security/SCP"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors SCP denials"
}
```

## 🆘 Troubleshooting

### Problema: Terraform não encontra o módulo
```bash
# Verificar estrutura de diretórios
ls -la scp-deny-public-access/

# Deve conter: main.tf, variables.tf, outputs.tf, versions.tf
```

### Problema: "No valid credential sources found"
```bash
# Configurar credenciais AWS
aws configure

# Ou exportar variáveis
export AWS_ACCESS_KEY_ID="xxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxx"
export AWS_REGION="us-east-1"
```

### Problema: "Access Denied" ao criar SCP
```bash
# Verificar que está no management account
aws sts get-caller-identity

# Verificar permissões IAM
aws iam get-user
aws iam list-attached-user-policies --user-name SEU_USER
```

### Problema: Policy não está bloqueando
```bash
# 1. Verificar que está anexada
aws organizations list-policies-for-target \
  --target-id ou-xxxx-yyyyyyyy \
  --filter SERVICE_CONTROL_POLICY

# 2. Aguardar alguns minutos (propagação)

# 3. Verificar o conteúdo da policy
terraform output policy_content | jq
```

## 📚 Próximos Passos

1. **Revisar controles**: Ajuste baseado nas necessidades do seu ambiente
2. **Testar em Dev**: Aplique primeiro em OU de desenvolvimento
3. **Documentar exceções**: Crie processo para casos especiais
4. **Monitorar**: Configure alertas CloudWatch
5. **Revisar periodicamente**: Ajuste controles conforme maturidade

## 💡 Dicas Importantes

- ⚠️ **Sempre teste em ambiente de desenvolvimento primeiro**
- 📝 **Documente mudanças e comunique o time**
- 🔄 **Mantenha processo de rollback documentado**
- 🕐 **SCPs podem levar alguns minutos para propagar**
- 🎯 **Use tags para organizar e rastrear policies**
- 📊 **Monitore CloudTrail para denials inesperados**

## 📞 Suporte

Para mais exemplos e documentação detalhada, veja:
- `README.md` - Documentação completa
- `examples-dynamic-controls.md` - Exemplos de uso
- `TESTING.md` - Guia de testes e validação
- `examples.md` - Exemplos avançados
