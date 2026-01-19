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

# Application Permissions Boundary Variables
variable "ai_copilot_create_application_permissions_boundary" {
  description = "Enable creation of application permissions boundary - defines maximum permissions that developer roles and application roles can have"
  type        = bool
  default     = false
}

variable "ai_copilot_application_permissions_boundary_name" {
  description = "Name of the application permissions boundary policy"
  type        = string
  default     = "cognitus-dev-application-permissions-boundary"
}


# Permission Set Variables
variable "ai_copilot_create_permission_set" {
  description = "Enable creation of AWS IAM Identity Center Permission Set"
  type        = bool
  default     = false
}

variable "ai_copilot_permission_set_name" {
  description = "Name of the Permission Set in AWS IAM Identity Center"
  type        = string
  default     = "AI-Copilot-Developer"
}

variable "ai_copilot_permission_set_description" {
  description = "Description of the Permission Set"
  type        = string
  default     = "Permission Set for AI Copilot developers with application development and limited IAM permissions including enforced permissions boundary"
}

variable "ai_copilot_session_duration" {
  description = "Session duration for the Permission Set (in ISO-8601 format, e.g., PT8H for 8 hours)"
  type        = string
  default     = "PT8H"
}

# Policy Attachment Toggles
variable "ai_copilot_attach_developer_application_policy" {
  description = "Attach the Developer Application Policy to the Permission Set"
  type        = bool
  default     = true
}

variable "ai_copilot_attach_developer_iam_guardrail" {
  description = "Attach the Developer IAM Guardrail Policy to the Permission Set"
  type        = bool
  default     = true
}

variable "ai_copilot_attach_permissions_boundary" {
  description = "Attach the Application Permissions Boundary to the Permission Set"
  type        = bool
  default     = true
}

