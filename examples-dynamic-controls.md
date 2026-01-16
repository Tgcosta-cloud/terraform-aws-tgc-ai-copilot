# Exemplos de Uso - Controles Dinâmicos

## Exemplo 1: Todos os Controles Habilitados (Padrão)

```hcl
module "scp_full_protection" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Full"
  environment = "production"

  # Todos os controles habilitados por padrão
  deny_ec2_public_ip            = true
  deny_elastic_ip_operations    = true
  deny_public_security_groups   = true
  deny_internet_facing_lb       = true
  deny_lb_in_public_subnets     = true
  deny_s3_public_access_changes = true

  public_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ]

  target_ids = ["ou-prod-12345678"]

  tags = {
    Environment = "Production"
    Compliance  = "Full"
  }
}
```

## Exemplo 2: Ambiente de Desenvolvimento - Controles Flexíveis

```hcl
module "scp_dev_relaxed" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Dev"
  environment = "development"

  # Permite EC2 com IP público e Elastic IPs para testes
  deny_ec2_public_ip         = false
  deny_elastic_ip_operations = false

  # Mantém controles de segurança críticos
  deny_public_security_groups   = true
  deny_internet_facing_lb       = true
  deny_lb_in_public_subnets     = true
  deny_s3_public_access_changes = true

  public_subnet_ids = [
    "subnet-dev-public-1a"
  ]

  target_ids = ["ou-dev-87654321"]

  tags = {
    Environment = "Development"
    Flexibility = "Moderate"
  }
}
```

## Exemplo 3: Staging - Bloqueio Progressivo

```hcl
module "scp_staging_progressive" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Staging"
  environment = "staging"

  # Fase 1: Apenas Security Groups e S3
  deny_ec2_public_ip            = false
  deny_elastic_ip_operations    = false
  deny_public_security_groups   = true
  deny_internet_facing_lb       = false
  deny_lb_in_public_subnets     = false
  deny_s3_public_access_changes = true

  target_ids = ["ou-staging-11111111"]
}

# Fase 2 (após validação): Adicionar mais controles
# Descomentar e aplicar quando pronto
# module "scp_staging_full" {
#   source = "./scp-deny-public-access"
#
#   policy_name = "DenyPublicAccess-Staging"
#   environment = "staging"
#
#   deny_ec2_public_ip            = true
#   deny_elastic_ip_operations    = true
#   deny_public_security_groups   = true
#   deny_internet_facing_lb       = true
#   deny_lb_in_public_subnets     = true
#   deny_s3_public_access_changes = true
#
#   public_subnet_ids = ["subnet-staging-public"]
#   target_ids        = ["ou-staging-11111111"]
# }
```

## Exemplo 4: Sandbox - Mínimo de Restrições

```hcl
module "scp_sandbox_minimal" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-Sandbox"
  environment = "sandbox"

  # Desabilita quase todos os controles
  deny_ec2_public_ip            = false
  deny_elastic_ip_operations    = false
  deny_public_security_groups   = false
  deny_internet_facing_lb       = false
  deny_lb_in_public_subnets     = false
  
  # Mantém apenas proteção S3
  deny_s3_public_access_changes = true

  target_ids = ["ou-sandbox-99999999"]

  tags = {
    Environment = "Sandbox"
    Purpose     = "Testing"
  }
}
```

## Exemplo 5: Security Hardening - Apenas Load Balancers

```hcl
module "scp_lb_only" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicLB-Only"
  environment = "production"

  # Desabilita outros controles
  deny_ec2_public_ip            = false
  deny_elastic_ip_operations    = false
  deny_public_security_groups   = false
  deny_s3_public_access_changes = false

  # Foco apenas em Load Balancers
  deny_internet_facing_lb   = true
  deny_lb_in_public_subnets = true

  public_subnet_ids = [
    "subnet-prod-public-1a",
    "subnet-prod-public-1b",
    "subnet-prod-public-1c"
  ]

  target_ids = ["123456789012"]
}
```

## Exemplo 6: Uso com Variáveis de Ambiente

**File: terraform.tfvars (dev)**
```hcl
environment = "development"

# Controles flexíveis para dev
controls = {
  deny_ec2_public_ip            = false
  deny_elastic_ip_operations    = false
  deny_public_security_groups   = true
  deny_internet_facing_lb       = false
  deny_lb_in_public_subnets     = false
  deny_s3_public_access_changes = true
}

target_ids = ["ou-dev-12345678"]
```

**File: terraform.tfvars (prod)**
```hcl
environment = "production"

# Controles restritivos para prod
controls = {
  deny_ec2_public_ip            = true
  deny_elastic_ip_operations    = true
  deny_public_security_groups   = true
  deny_internet_facing_lb       = true
  deny_lb_in_public_subnets     = true
  deny_s3_public_access_changes = true
}

public_subnet_ids = [
  "subnet-prod-pub-1a",
  "subnet-prod-pub-1b"
]

target_ids = ["ou-prod-87654321"]
```

**File: main.tf**
```hcl
variable "controls" {
  description = "Map of control toggles"
  type = object({
    deny_ec2_public_ip            = bool
    deny_elastic_ip_operations    = bool
    deny_public_security_groups   = bool
    deny_internet_facing_lb       = bool
    deny_lb_in_public_subnets     = bool
    deny_s3_public_access_changes = bool
  })
}

module "scp_dynamic" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-${var.environment}"
  environment = var.environment

  # Passar controles dinamicamente
  deny_ec2_public_ip            = var.controls.deny_ec2_public_ip
  deny_elastic_ip_operations    = var.controls.deny_elastic_ip_operations
  deny_public_security_groups   = var.controls.deny_public_security_groups
  deny_internet_facing_lb       = var.controls.deny_internet_facing_lb
  deny_lb_in_public_subnets     = var.controls.deny_lb_in_public_subnets
  deny_s3_public_access_changes = var.controls.deny_s3_public_access_changes

  public_subnet_ids = var.public_subnet_ids
  target_ids        = var.target_ids
}
```

## Exemplo 7: Multi-Ambiente com Locals

```hcl
locals {
  # Definir controles por ambiente
  environment_controls = {
    development = {
      deny_ec2_public_ip            = false
      deny_elastic_ip_operations    = false
      deny_public_security_groups   = true
      deny_internet_facing_lb       = false
      deny_lb_in_public_subnets     = false
      deny_s3_public_access_changes = true
    }
    staging = {
      deny_ec2_public_ip            = true
      deny_elastic_ip_operations    = false
      deny_public_security_groups   = true
      deny_internet_facing_lb       = true
      deny_lb_in_public_subnets     = false
      deny_s3_public_access_changes = true
    }
    production = {
      deny_ec2_public_ip            = true
      deny_elastic_ip_operations    = true
      deny_public_security_groups   = true
      deny_internet_facing_lb       = true
      deny_lb_in_public_subnets     = true
      deny_s3_public_access_changes = true
    }
  }

  current_controls = local.environment_controls[var.environment]
}

module "scp_environment_based" {
  source = "./scp-deny-public-access"

  policy_name = "DenyPublicAccess-${var.environment}"
  environment = var.environment

  deny_ec2_public_ip            = local.current_controls.deny_ec2_public_ip
  deny_elastic_ip_operations    = local.current_controls.deny_elastic_ip_operations
  deny_public_security_groups   = local.current_controls.deny_public_security_groups
  deny_internet_facing_lb       = local.current_controls.deny_internet_facing_lb
  deny_lb_in_public_subnets     = local.current_controls.deny_lb_in_public_subnets
  deny_s3_public_access_changes = local.current_controls.deny_s3_public_access_changes

  public_subnet_ids = var.public_subnet_ids
  target_ids        = var.target_ids
}
```

## Exemplo 8: Compliance-Based Controls

```hcl
variable "compliance_framework" {
  description = "Compliance framework to apply (cis, pci-dss, hipaa, custom)"
  type        = string
  default     = "custom"
}

locals {
  # Controles por framework de compliance
  compliance_controls = {
    cis = {
      deny_ec2_public_ip            = true
      deny_elastic_ip_operations    = true
      deny_public_security_groups   = true
      deny_internet_facing_lb       = true
      deny_lb_in_public_subnets     = true
      deny_s3_public_access_changes = true
    }
    pci-dss = {
      deny_ec2_public_ip            = true
      deny_elastic_ip_operations    = true
      deny_public_security_groups   = true
      deny_internet_facing_lb       = true
      deny_lb_in_public_subnets     = true
      deny_s3_public_access_changes = true
    }
    hipaa = {
      deny_ec2_public_ip            = true
      deny_elastic_ip_operations    = true
      deny_public_security_groups   = true
      deny_internet_facing_lb       = false  # Permitir ALB/NLB com TLS
      deny_lb_in_public_subnets     = false
      deny_s3_public_access_changes = true
    }
    custom = {
      deny_ec2_public_ip            = false
      deny_elastic_ip_operations    = false
      deny_public_security_groups   = true
      deny_internet_facing_lb       = false
      deny_lb_in_public_subnets     = false
      deny_s3_public_access_changes = true
    }
  }

  selected_controls = local.compliance_controls[var.compliance_framework]
}

module "scp_compliance" {
  source = "./scp-deny-public-access"

  policy_name        = "DenyPublicAccess-${upper(var.compliance_framework)}"
  policy_description = "SCP based on ${var.compliance_framework} compliance requirements"
  environment        = var.environment

  deny_ec2_public_ip            = local.selected_controls.deny_ec2_public_ip
  deny_elastic_ip_operations    = local.selected_controls.deny_elastic_ip_operations
  deny_public_security_groups   = local.selected_controls.deny_public_security_groups
  deny_internet_facing_lb       = local.selected_controls.deny_internet_facing_lb
  deny_lb_in_public_subnets     = local.selected_controls.deny_lb_in_public_subnets
  deny_s3_public_access_changes = local.selected_controls.deny_s3_public_access_changes

  public_subnet_ids = var.public_subnet_ids
  target_ids        = var.target_ids

  tags = {
    Compliance = upper(var.compliance_framework)
  }
}
```

## Verificar Controles Ativos

Após aplicar, use o output para verificar quais controles estão ativos:

```bash
terraform apply

# Ver controles habilitados
terraform output enabled_controls

# Exemplo de output:
# enabled_controls = {
#   "deny_ec2_public_ip" = true
#   "deny_elastic_ip_operations" = true
#   "deny_internet_facing_lb" = true
#   "deny_lb_in_public_subnets" = true
#   "deny_public_security_groups" = true
#   "deny_s3_public_access_changes" = true
#   "total_statements" = 7
# }
```

## Testar Controles Específicos

```bash
# Se deny_ec2_public_ip = true
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t3.micro \
  --associate-public-ip-address
# Esperado: AccessDenied

# Se deny_elastic_ip_operations = true
aws ec2 allocate-address
# Esperado: AccessDenied

# Se deny_public_security_groups = true
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
# Esperado: AccessDenied

# Se deny_internet_facing_lb = true
aws elbv2 create-load-balancer \
  --name test-alb \
  --subnets subnet-xxx subnet-yyy \
  --scheme internet-facing
# Esperado: AccessDenied
```

## Matriz de Controles Recomendados por Ambiente

| Controle | Sandbox | Dev | Staging | Prod |
|----------|---------|-----|---------|------|
| EC2 Public IP | ❌ | ❌ | ✅ | ✅ |
| Elastic IP Ops | ❌ | ❌ | ❌ | ✅ |
| Public SG | ❌ | ✅ | ✅ | ✅ |
| Internet-facing LB | ❌ | ❌ | ✅ | ✅ |
| LB in Public Subnets | ❌ | ❌ | ❌ | ✅ |
| S3 Public Access | ✅ | ✅ | ✅ | ✅ |

✅ = Habilitado (true)  
❌ = Desabilitado (false)
