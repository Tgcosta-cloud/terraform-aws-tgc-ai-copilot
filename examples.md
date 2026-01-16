# Exemplo de uso do módulo SCP Deny Public Access

## Estrutura de diretórios sugerida

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
└── modules/
    └── scp-deny-public-access/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── versions.tf
        └── policy.json.tpl
```

## Exemplo 1: Deploy para OU de Desenvolvimento

**File: environments/dev/main.tf**
```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "scp/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # Management Account credentials
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/OrganizationAdminRole"
  }
}

# Data source para obter subnets públicas
data "aws_subnets" "public_dev" {
  filter {
    name   = "vpc-id"
    values = ["vpc-dev123456"]
  }

  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

module "scp_deny_public_access_dev" {
  source = "../../modules/scp-deny-public-access"

  policy_name        = "DenyPublicAccess-Dev"
  policy_description = "SCP para bloquear acesso público em ambiente de desenvolvimento"
  environment        = "development"

  public_subnet_ids = data.aws_subnets.public_dev.ids

  target_ids = [
    var.dev_ou_id
  ]

  tags = {
    Team        = "Cloud Security"
    Environment = "Development"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
  }
}

output "scp_policy_id" {
  value = module.scp_deny_public_access_dev.policy_id
}

output "scp_policy_arn" {
  value = module.scp_deny_public_access_dev.policy_arn
}
```

**File: environments/dev/variables.tf**
```hcl
variable "dev_ou_id" {
  description = "Organization Unit ID para desenvolvimento"
  type        = string
}
```

**File: environments/dev/terraform.tfvars**
```hcl
dev_ou_id = "ou-xxxx-12345678"
```

## Exemplo 2: Deploy Multi-Ambiente

**File: environments/prod/main.tf**
```hcl
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "scp/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
  
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/OrganizationAdminRole"
  }
}

# Listar todas as subnets públicas em múltiplas VPCs
locals {
  vpc_ids = [
    "vpc-prod-us-east-1",
    "vpc-prod-us-west-2",
    "vpc-prod-eu-west-1"
  ]
}

data "aws_subnets" "public_all_vpcs" {
  for_each = toset(local.vpc_ids)

  filter {
    name   = "vpc-id"
    values = [each.value]
  }

  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

module "scp_deny_public_access_prod" {
  source = "../../modules/scp-deny-public-access"

  policy_name        = "DenyPublicAccess-Production"
  policy_description = "SCP restritiva para ambiente de produção - bloqueia todas as configurações de acesso público"
  environment        = "production"

  public_subnet_ids = flatten([
    for vpc_key, subnets in data.aws_subnets.public_all_vpcs : subnets.ids
  ])

  target_ids = [
    var.prod_ou_id,
    var.prod_account_id_1,
    var.prod_account_id_2
  ]

  tags = {
    Team        = "Cloud Security"
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "Infrastructure"
    Compliance  = "CIS-AWS,PCI-DSS"
    Critical    = "true"
  }
}

# Outputs
output "policy_details" {
  description = "Detalhes da SCP criada"
  value = {
    id              = module.scp_deny_public_access_prod.policy_id
    arn             = module.scp_deny_public_access_prod.policy_arn
    name            = module.scp_deny_public_access_prod.policy_name
    attached_to     = module.scp_deny_public_access_prod.attached_target_ids
    subnets_blocked = length(flatten([for vpc_key, subnets in data.aws_subnets.public_all_vpcs : subnets.ids]))
  }
}
```

**File: environments/prod/terraform.tfvars**
```hcl
prod_ou_id        = "ou-xxxx-87654321"
prod_account_id_1 = "222222222222"
prod_account_id_2 = "333333333333"
```

## Exemplo 3: Com Conditional Subnet Filtering

**File: environments/staging/main.tf**
```hcl
provider "aws" {
  region = "us-east-1"
}

# Buscar subnets públicas baseado em route tables
data "aws_route_tables" "public_routes" {
  vpc_id = var.vpc_id

  filter {
    name   = "route.destination-cidr-block"
    values = ["0.0.0.0/0"]
  }

  filter {
    name   = "route.gateway-id"
    values = ["igw-*"]
  }
}

data "aws_route_table" "public" {
  for_each = toset(data.aws_route_tables.public_routes.ids)
  
  route_table_id = each.value
}

locals {
  # Extrair subnet IDs de todas as route tables públicas
  public_subnet_ids = distinct(flatten([
    for rt_id, rt in data.aws_route_table.public : [
      for assoc in rt.associations : assoc.subnet_id
      if assoc.subnet_id != null
    ]
  ]))
}

module "scp_deny_public_access_staging" {
  source = "../../modules/scp-deny-public-access"

  policy_name        = "DenyPublicAccess-Staging"
  policy_description = "SCP para staging com subnet filtering automático"
  environment        = "staging"

  public_subnet_ids = local.public_subnet_ids

  target_ids = [var.staging_ou_id]

  tags = {
    Team        = "Cloud Security"
    Environment = "Staging"
    ManagedBy   = "Terraform"
  }
}
```

## Exemplo 4: Deploy Incremental (Safe Rollout)

**File: main.tf**
```hcl
# Fase 1: Criar a policy mas não anexar
module "scp_deny_public_phase1" {
  source = "./modules/scp-deny-public-access"

  policy_name       = "DenyPublicAccess-RolloutTest"
  environment       = "production"
  public_subnet_ids = var.public_subnets

  # Não anexar ainda
  target_ids = []

  tags = {
    Phase = "1-Testing"
  }
}

# Fase 2: Anexar a uma conta de teste
# module "scp_deny_public_phase2" {
#   source = "./modules/scp-deny-public-access"
#
#   policy_name       = "DenyPublicAccess-RolloutTest"
#   environment       = "production"
#   public_subnet_ids = var.public_subnets
#
#   target_ids = [
#     var.test_account_id
#   ]
#
#   tags = {
#     Phase = "2-SingleAccount"
#   }
# }

# Fase 3: Anexar à OU inteira após validação
# module "scp_deny_public_phase3" {
#   source = "./modules/scp-deny-public-access"
#
#   policy_name       = "DenyPublicAccess-Production"
#   environment       = "production"
#   public_subnet_ids = var.public_subnets
#
#   target_ids = [
#     var.production_ou_id
#   ]
#
#   tags = {
#     Phase = "3-FullRollout"
#   }
# }
```

## Exemplo 5: Com Breakglass Account Exception

Se você precisa de uma conta com exceção (breakglass), crie um módulo modificado:

**File: modules/scp-deny-public-access-with-exception/policy.json.tpl**
```json
{
  "Version": "2012-10-17",
  "Statement": [
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
          "aws:PrincipalAccount": ${exception_account_ids}
        }
      }
    }
  ]
}
```

**Usage:**
```hcl
module "scp_with_exception" {
  source = "./modules/scp-deny-public-access-with-exception"

  policy_name       = "DenyPublicAccess-WithException"
  environment       = "production"
  public_subnet_ids = var.public_subnets
  
  # Conta de breakglass
  exception_account_ids = ["999999999999"]
  
  target_ids = [var.production_ou_id]
}
```

## Deploy Commands

```bash
# 1. Inicializar
cd environments/dev
terraform init

# 2. Planejar
terraform plan -out=tfplan

# 3. Revisar o plano
terraform show tfplan

# 4. Aplicar
terraform apply tfplan

# 5. Validar outputs
terraform output

# 6. Testar a SCP (em uma conta afetada)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --associate-public-ip-address
# Deve retornar erro de Access Denied

# 7. Verificar attachments
aws organizations list-policies-for-target \
  --target-id ou-xxxx-12345678 \
  --filter SERVICE_CONTROL_POLICY
```

## Rollback Plan

Se precisar fazer rollback:

```bash
# 1. Remover attachments primeiro
terraform apply -var="target_ids=[]"

# 2. Depois destruir a policy
terraform destroy

# Ou fazer rollback completo
terraform destroy -auto-approve
```

## Monitoring

Crie alertas CloudWatch para monitorar tentativas bloqueadas:

```hcl
# CloudTrail Event Rule
resource "aws_cloudwatch_event_rule" "scp_denials" {
  name        = "scp-public-access-denials"
  description = "Captura eventos bloqueados pela SCP"

  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      errorCode = ["AccessDenied"]
      userIdentity = {
        principalId = [{
          exists = true
        }]
      }
    }
  })
}

# SNS para alertas
resource "aws_sns_topic" "scp_alerts" {
  name = "scp-denial-alerts"
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.scp_denials.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.scp_alerts.arn
}
```
