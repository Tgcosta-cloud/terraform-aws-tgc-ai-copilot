variable "ai_copilot_create_developer_scp" {
  description = "Enable creation of developer SCP policy"
  type        = bool
  default     = false
}
variable "ai_copilot_policy_name" {
  description = "Name of the SCP policy"
  type        = string
}

variable "ai_copilot_target_ids" {
  description = "List of AWS Organization target IDs (Account IDs or OU IDs) to attach the policy to"
  type        = list(string)
  default     = []
}

# SCP rule toggles
variable "ai_copilot_deny_ec2_public_ip" {
  description = "Enable control to deny EC2 instances launch with public IPv4 addresses"
  type        = bool
  default     = false
}

variable "ai_copilot_deny_elastic_ip_operations" {
  description = "Enable control to deny Elastic IP allocation, release, association and disassociation"
  type        = bool
  default     = false
}

variable "ai_copilot_deny_internet_facing_lb" {
  description = "Enable control to deny internet-facing Load Balancers"
  type        = bool
  default     = false
}

variable "ai_copilot_deny_lb_in_public_subnets" {
  description = "Enable control to deny Load Balancers in specified public subnets"
  type        = bool
  default     = false
}

variable "ai_copilot_deny_s3_public_access_changes" {
  description = "Enable control to deny changes to S3 account-level Block Public Access settings"
  type        = bool
  default     = false
}

variable "ai_copilot_public_subnet_ids" {
  description = "List of public subnet IDs or ARNs to deny load balancer creation (required if deny_lb_in_public_subnets is true)"
  type        = list(string)
  default     = []
}

variable "ai_copilot_enforce_roles" {
  description = "List of IAM role names that should be enforced by this SCP. If empty, applies to all roles. Example: ['Dev-Role-Builder-Enforcement', 'AWSReservedSSO_DevRole_*']"
  type        = list(string)
  default     = []
}

# Developer IAM Policy Variables Guardrail
variable "ai_copilot_create_developer_iam_policy_guardrail" {
  description = "Enable creation of developer IAM policy with permissions boundary enforcement"
  type        = bool
  default     = false
}

variable "ai_copilot_developer_policy_name_guardrail" {
  description = "Name of the IAM policy for developers"
  type        = string
  default     = "cognitus-developer-iam-permissions"
}

variable "ai_copilot_developer_permissions_boundary_name" {
  description = "Name of the required permissions boundary policy"
  type        = string
  default     = "cognitus-dev-application-permissions-boundary"
}

variable "ai_copilot_developer_role_prefix" {
  description = "Prefix that developers can use when creating roles"
  type        = string
  default     = "dev-app-"
}

variable "ai_copilot_developer_allowed_passrole_services" {
  description = "List of AWS services that developers can pass roles to"
  type        = list(string)
  default = [
    "lambda.amazonaws.com",
    "ecs-tasks.amazonaws.com"
  ]
}

# Developer Application Policy Variables
variable "ai_copilot_create_developer_application_policy" {
  description = "Enable creation of developer application policy - grants day-to-day permissions for building and deploying applications"
  type        = bool
  default     = false
}

variable "ai_copilot_developer_application_policy_name" {
  description = "Name of the developer application policy"
  type        = string
  default     = "cognitus-dev-ai-developer"
}