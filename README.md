# SCP - Deny Public Access (Dynamic Controls)

Este módulo Terraform cria e gerencia uma Service Control Policy (SCP) da AWS Organizations com **controles dinâmicos e configuráveis**. Cada controle pode ser habilitado ou desabilitado individualmente através de variáveis booleanas.

## 🎯 Controles Disponíveis

Todos os controles são **habilitados por padrão** e podem ser desabilitados conforme necessário:

| Controle | Variável | Padrão | Descrição |
|----------|----------|--------|-----------|
| **EC2 Public IP** | `deny_ec2_public_ip` | `true` | Bloqueia lançamento de EC2 com IP público |
| **Elastic IP Operations** | `deny_elastic_ip_operations` | `true` | Bloqueia alocação/associação de Elastic IPs |
| **Public Security Groups** | `deny_public_security_groups` | `true` | Bloqueia regras SG com 0.0.0.0/0 ou ::/0 |
| **Internet-facing LB** | `deny_internet_facing_lb` | `true` | Bloqueia criação de LB internet-facing |
| **LB in Public Subnets** | `deny_lb_in_public_subnets` | `true` | Bloqueia LB em subnets públicas específicas |
| **S3 Public Access Changes** | `deny_s3_public_access_changes` | `true` | Bloqueia alterações no S3 Block Public Access |

## Pré-requisitos

- AWS Organizations configurado
- Permissões para criar e anexar SCPs
- Terraform >= 1.0
- Provider AWS >= 5.0

## 🚀 Benefícios dos Controles Dinâmicos

### 1. **Flexibilidade por Ambiente**
Configure diferentes níveis de restrição para cada ambiente:
- **Sandbox**: Controles mínimos para experimentação
- **Development**: Flexibilidade moderada para desenvolvimento
- **Staging**: Preparação com controles semi-restritivos
- **Production**: Máxima segurança com todos os controles

### 2. **Rollout Progressivo**
Implemente controles gradualmente:
```hcl
# Semana 1: Apenas Security Groups
deny_public_security_groups = true

# Semana 2: Adicionar EC2 e EIP
deny_ec2_public_ip = true
deny_elastic_ip_operations = true

# Semana 3: Adicionar Load Balancers
deny_internet_facing_lb = true
```

### 3. **Compliance Específico**
Alinhe controles com frameworks de compliance:
- **CIS AWS**: Todos os controles habilitados
- **PCI-DSS**: Foco em network e data protection
- **HIPAA**: Configurações específicas para healthcare

### 4. **Gestão de Exceções**
Desabilite temporariamente controles específicos sem remover toda a policy:
```hcl
# Projeto especial precisa de Load Balancer público
deny_internet_facing_lb = false  # Temporariamente

# Resto dos controles permanece ativo
deny_public_security_groups = true
deny_s3_public_access_changes = true
```

### 5. **Testing e Validação**
Teste controles individuais antes do deployment completo:
```hcl
# Testar apenas bloqueio de Security Groups
deny_public_security_groups = true
# Outros controles desabilitados para teste isolado
```

## Pré-requisitos

- AWS Organizations configurado
- Permissões para criar e anexar SCPs
- Terraform >= 1.0
- Provider AWS >= 5.0

## Uso

### Exemplo Básico - Todos os Controles Habilitados

```hcl
module "scp_deny_public_access" {
  source = "./scp-deny-public-access"

  policy_name        = "DenyPublicAccessSCP"
  policy_description = "Nega configurações de acesso público"
  environment        = "production"

  # Todos os controles habilitados (padrão)
  deny_ec2_public_ip            = true
  deny_elastic_ip_operations    = true
  deny_public_security_groups   = true
  deny_internet_facing_lb       = true
  deny_lb_in_public_subnets     = true
  deny_s3_public_access_changes = true

  public_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2"
  ]

  target_ids = [
    "ou-xxxx-yyyyyyyy",  # OU ID
    "123456789012"       # Account ID
  ]

  tags = {
    Team        = "Security"
    CostCenter  = "Infrastructure"
    Compliance  = "CIS-AWS"
  }
}
```

### Exemplo - Ambiente de Desenvolvimento (Controles Seletivos)

```hcl
module "scp_dev_flexible" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Dev"
  environment = "development"

  # Permite EC2 com IP público e Elastic IPs para testes
  deny_ec2_public_ip         = false
  deny_elastic_ip_operations = false

  # Mantém controles de segurança críticos
  deny_public_security_groups   = true
  deny_internet_facing_lb       = true
  deny_lb_in_public_subnets     = false  # Permite LB em subnets públicas
  deny_s3_public_access_changes = true

  target_ids = ["ou-dev-12345678"]

  tags = {
    Environment = "Development"
    Flexibility = "Moderate"
  }
}
```

### Exemplo - Apenas Controles de Network Security

```hcl
module "scp_network_only" {
  source = "./scp-deny-public-access"

  policy_name = "NetworkSecuritySCP"
  environment = "production"

  # Desabilita controles de EC2/EIP/S3
  deny_ec2_public_ip            = false
  deny_elastic_ip_operations    = false
  deny_s3_public_access_changes = false

  # Habilita apenas controles de network
  deny_public_security_groups = true
  deny_internet_facing_lb     = true
  deny_lb_in_public_subnets   = true

  public_subnet_ids = var.public_subnet_ids
  target_ids        = ["ou-prod-87654321"]
}
```

### Exemplo com Múltiplas OUs

```hcl
module "scp_deny_public_access_dev" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccessSCP-Dev"
  environment = "development"

  public_subnet_ids = [
    "subnet-dev-public-1a",
    "subnet-dev-public-1b"
  ]

  target_ids = [
    "ou-dev-12345678"
  ]
}

module "scp_deny_public_access_prod" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccessSCP-Prod"
  environment = "production"

  public_subnet_ids = [
    "subnet-prod-public-1a",
    "subnet-prod-public-1b",
    "subnet-prod-public-1c"
  ]

  target_ids = [
    "ou-prod-87654321"
  ]
}
```

### Exemplo usando Data Sources para Subnets

```hcl
data "aws_subnets" "public" {
  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

module "scp_deny_public_access" {
  source = "./scp-deny-public-access"

  policy_name       = "DenyPublicAccessSCP"
  public_subnet_ids = data.aws_subnets.public.ids
  
  target_ids = [
    var.organization_root_id
  ]
}
```

## Inputs

### Configurações Básicas

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| policy_name | Nome da SCP policy | `string` | `"DenyPublicAccessSCP"` | no |
| policy_description | Descrição da SCP policy | `string` | `"SCP to deny public access configurations..."` | no |
| environment | Nome do ambiente | `string` | `"production"` | no |
| public_subnet_ids | Lista de IDs ou ARNs de subnets públicas | `list(string)` | `[]` | no* |
| target_ids | Lista de IDs de targets (Account IDs ou OU IDs) | `list(string)` | `[]` | no |
| tags | Tags adicionais para a policy | `map(string)` | `{}` | no |

\* **Nota**: `public_subnet_ids` é obrigatório apenas se `deny_lb_in_public_subnets = true`

### Controles de Segurança (Toggles)

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| deny_ec2_public_ip | Bloquear EC2 com IP público | `bool` | `true` | no |
| deny_elastic_ip_operations | Bloquear operações com Elastic IP | `bool` | `true` | no |
| deny_public_security_groups | Bloquear SG com acesso público | `bool` | `true` | no |
| deny_internet_facing_lb | Bloquear LB internet-facing | `bool` | `true` | no |
| deny_lb_in_public_subnets | Bloquear LB em subnets públicas | `bool` | `true` | no |
| deny_s3_public_access_changes | Bloquear alterações S3 Block Public Access | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_id | ID da SCP policy |
| policy_arn | ARN da SCP policy |
| policy_name | Nome da SCP policy |
| policy_content | Conteúdo JSON da SCP policy |
| attached_target_ids | Lista de target IDs onde a policy está anexada |
| attachment_ids | Map de target IDs para seus attachment IDs |
| enabled_controls | Summary dos controles habilitados e total de statements |

## O que a SCP Bloqueia

### 1. EC2 Public IPs
- **Ação Bloqueada**: `ec2:RunInstances` com `AssociatePublicIpAddress: true`
- **Impacto**: Instâncias EC2 não podem ser lançadas com IP público automático

### 2. Elastic IPs
- **Ações Bloqueadas**: 
  - `ec2:AllocateAddress`
  - `ec2:ReleaseAddress`
  - `ec2:AssociateAddress`
  - `ec2:DisassociateAddress`
- **Impacto**: Não é possível alocar, liberar ou associar Elastic IPs

### 3. Security Groups Públicos
- **Ação Bloqueada**: `ec2:AuthorizeSecurityGroupIngress` com CIDR `0.0.0.0/0` ou `::/0`
- **Impacto**: Não é possível criar regras de ingress com acesso público total

### 4. Load Balancers Internet-Facing
- **Ação Bloqueada**: `elasticloadbalancing:CreateLoadBalancer` com scheme `internet-facing`
- **Impacto**: Somente load balancers internos podem ser criados

### 5. Load Balancers em Subnets Públicas
- **Ação Bloqueada**: `elasticloadbalancing:CreateLoadBalancer` nas subnets especificadas
- **Impacto**: Load balancers não podem ser criados nas subnets públicas configuradas

### 6. S3 Block Public Access
- **Ação Bloqueada**: `s3:PutAccountPublicAccessBlock`
- **Impacto**: As configurações de Block Public Access da conta não podem ser alteradas

## Exceções e Breakglass

Se você precisar criar exceções temporárias:

1. **Remover attachment temporariamente**:
```hcl
module "scp_deny_public_access" {
  source = "./scp-deny-public-access"
  
  # Remover target_ids temporariamente
  target_ids = []
}
```

2. **Criar SCP com exceções** (exemplo):
Você pode modificar o `policy.json.tpl` para adicionar condições de exceção:

```json
{
  "Sid": "DenyEC2LaunchWithPublicIPv4",
  "Effect": "Deny",
  "Action": "ec2:RunInstances",
  "Resource": "*",
  "Condition": {
    "Bool": {
      "ec2:AssociatePublicIpAddress": "true"
    },
    "StringNotEquals": {
      "aws:PrincipalTag/BreakglassRole": "true"
    }
  }
}
```

## Obter IDs de Subnets Públicas

### Via AWS CLI
```bash
# Listar subnets públicas por tag
aws ec2 describe-subnets \
  --filters "Name=tag:Type,Values=Public" \
  --query 'Subnets[*].SubnetId' \
  --output json

# Listar subnets que possuem route para IGW
aws ec2 describe-route-tables \
  --filters "Name=route.destination-cidr-block,Values=0.0.0.0/0" \
  --query 'RouteTables[*].Associations[*].SubnetId' \
  --output json
```

### Via Terraform Data Source
```hcl
data "aws_route_tables" "public" {
  filter {
    name   = "route.destination-cidr-block"
    values = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "subnet-id"
    values = flatten([
      for rt in data.aws_route_tables.public.ids : 
        data.aws_route_table.rt[rt].associations[*].subnet_id
    ])
  }
}
```

## Teste da SCP

Após aplicar a SCP, teste se ela está funcionando:

```bash
# 1. Tentar lançar EC2 com IP público (deve falhar)
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.micro \
  --associate-public-ip-address

# 2. Tentar alocar Elastic IP (deve falhar)
aws ec2 allocate-address

# 3. Tentar criar security group com 0.0.0.0/0 (deve falhar)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# 4. Tentar criar ALB internet-facing (deve falhar)
aws elbv2 create-load-balancer \
  --name test-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --scheme internet-facing
```

## Troubleshooting

### Erro: "You have exceeded the limit of SCPs"
- Limite padrão: 5 SCPs por target
- Solução: Consolidar múltiplas SCPs ou solicitar aumento de limite

### Erro: "Access Denied" ao aplicar SCP
- Verifique se você está usando credenciais do management account
- Confirme permissões: `organizations:*`

### Subnet IDs não estão bloqueando Load Balancers
- Verifique se os IDs das subnets estão corretos
- SCPs usam IDs, não ARNs (a menos que especificado)
- Teste com: `aws ec2 describe-subnets --subnet-ids subnet-xxxxx`

## Segurança

⚠️ **IMPORTANTE**: Esta SCP é restritiva e pode impactar operações existentes.

**Recomendações**:
1. Teste primeiro em uma OU de desenvolvimento
2. Comunique as mudanças para os times
3. Documente processos de exceção
4. Monitore CloudTrail para eventos bloqueados
5. Mantenha um processo de breakglass documentado

## Compliance

Esta SCP ajuda a atender diversos controles de compliance:

- **CIS AWS Foundations Benchmark**: 
  - 5.1 (Network Access Control)
  - 2.1.5 (S3 Block Public Access)
  
- **AWS Well-Architected Framework**:
  - Security Pillar - Infrastructure Protection

- **PCI-DSS**:
  - Requirement 1 (Network Security Controls)

## 📊 Matriz de Controles Recomendados

### Por Ambiente

| Controle | Sandbox | Dev | Staging | Production |
|----------|---------|-----|---------|------------|
| 🌐 EC2 Public IP | ❌ | ❌ | ✅ | ✅ |
| 🔌 Elastic IP Ops | ❌ | ❌ | ⚠️ | ✅ |
| 🔒 Public SG | ❌ | ✅ | ✅ | ✅ |
| 🌍 Internet-facing LB | ❌ | ❌ | ✅ | ✅ |
| 📍 LB in Public Subnets | ❌ | ❌ | ⚠️ | ✅ |
| 🪣 S3 Public Access | ✅ | ✅ | ✅ | ✅ |

✅ = Recomendado Habilitar  
⚠️ = Considerar baseado no caso de uso  
❌ = Pode manter desabilitado

### Por Framework de Compliance

| Controle | CIS AWS | PCI-DSS | HIPAA | SOC 2 |
|----------|---------|---------|-------|-------|
| EC2 Public IP | ✅ | ✅ | ✅ | ✅ |
| Elastic IP Ops | ✅ | ✅ | ✅ | ✅ |
| Public SG | ✅ | ✅ | ✅ | ✅ |
| Internet-facing LB | ✅ | ✅ | ⚠️* | ✅ |
| LB in Public Subnets | ✅ | ✅ | ⚠️* | ✅ |
| S3 Public Access | ✅ | ✅ | ✅ | ✅ |

\* HIPAA pode requerer LBs públicos com TLS/SSL adequado

### Por Nível de Maturidade de Segurança

| Controle | Básico | Intermediário | Avançado |
|----------|--------|---------------|----------|
| EC2 Public IP | ❌ | ✅ | ✅ |
| Elastic IP Ops | ❌ | ⚠️ | ✅ |
| Public SG | ✅ | ✅ | ✅ |
| Internet-facing LB | ❌ | ✅ | ✅ |
| LB in Public Subnets | ❌ | ⚠️ | ✅ |
| S3 Public Access | ✅ | ✅ | ✅ |

## 🎯 Cenários de Uso Comuns

### Cenário 1: Startup em Crescimento
```hcl
# Começando simples, mas seguro
deny_public_security_groups   = true  # Primeira linha de defesa
deny_s3_public_access_changes = true  # Proteger dados
# Resto desabilitado para flexibilidade inicial
```

### Cenário 2: Empresa Enterprise
```hcl
# Todos os controles habilitados
deny_ec2_public_ip            = true
deny_elastic_ip_operations    = true
deny_public_security_groups   = true
deny_internet_facing_lb       = true
deny_lb_in_public_subnets     = true
deny_s3_public_access_changes = true
```

### Cenário 3: SaaS com Multi-Tenancy
```hcl
# Permitir LBs públicos (necessário para API pública)
deny_internet_facing_lb   = false
deny_lb_in_public_subnets = false

# Bloquear acesso direto a instâncias
deny_ec2_public_ip         = true
deny_elastic_ip_operations = true
deny_public_security_groups = true
deny_s3_public_access_changes = true
```

## Compliance

Esta SCP ajuda a atender diversos controles de compliance:

- **CIS AWS Foundations Benchmark**: 
  - 5.1 (Network Access Control)
  - 2.1.5 (S3 Block Public Access)
  
- **AWS Well-Architected Framework**:
  - Security Pillar - Infrastructure Protection

- **PCI-DSS**:
  - Requirement 1 (Network Security Controls)

## Referências

- [AWS Organizations SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [SCP Examples](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html)
- [Terraform AWS Organizations Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy)

## License

MIT

## Autor

Criado para gerenciamento de segurança em ambientes AWS multi-account.
