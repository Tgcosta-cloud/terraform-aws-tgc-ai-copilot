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

# ========================================
# Account Assignment Variables
# ========================================

variable "ai_copilot_target_account_ids" {
  description = <<-EOT
    List of AWS Account IDs where the Permission Set will be assigned.
    Users/groups will be able to access these accounts using this Permission Set.
    Example: ["123456789012", "234567890123"]
  EOT
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for account in var.ai_copilot_target_account_ids :
      can(regex("^[0-9]{12}$", account))
    ])
    error_message = "Account IDs must be 12-digit numbers."
  }
}

variable "ai_copilot_user_names" {
  description = <<-EOT
    List of Identity Center user names (email addresses or usernames) to assign the Permission Set.
    These must match EXACTLY the UserName in IAM Identity Center (case-sensitive).
    Example: ["thiago@company.com", "developer1@company.com"]
    Note: Using groups is recommended over individual users for easier management.
  EOT
  type        = list(string)
  default     = []
}

variable "ai_copilot_group_names" {
  description = <<-EOT
    List of Identity Center group display names to assign the Permission Set.
    These must match EXACTLY the DisplayName in IAM Identity Center (case-sensitive).
    Example: ["Developers", "AI-Engineers", "DevOps-Team"]
    Recommended: Use groups instead of individual users for easier management.
  EOT
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.ai_copilot_user_names) > 0 || length(var.ai_copilot_group_names) > 0 || !var.ai_copilot_create_permission_set
    error_message = "At least one user or group must be specified when creating a Permission Set, or set ai_copilot_create_permission_set to false."
  }
}

# ========================================
# Advanced Account Assignment (Optional)
# ========================================

variable "ai_copilot_account_assignments" {
  description = <<-EOT
    Advanced: Granular control over account assignments.
    Allows different users/groups per account.
    If specified, this takes precedence over ai_copilot_user_names and ai_copilot_group_names.
    
    Example:
    {
      dev = {
        account_id = "123456789012"
        users      = ["dev1@company.com"]
        groups     = ["Developers", "Junior-Devs"]
      }
      prod = {
        account_id = "345678901234"
        users      = []
        groups     = ["Senior-Developers"]
      }
    }
  EOT
  type = map(object({
    account_id = string
    users      = list(string)
    groups     = list(string)
  }))
  default = {}
}

# ========================================
# Validation and Helper Variables
# ========================================

variable "ai_copilot_enable_assignment_validation" {
  description = "Enable validation checks for account assignments (checks if users/groups exist before creating assignments)"
  type        = bool
  default     = true
}

variable "ai_copilot_assignment_wait_time" {
  description = "Time to wait for assignments to propagate (in seconds). Useful for automation."
  type        = number
  default     = 60
  
  validation {
    condition     = var.ai_copilot_assignment_wait_time >= 0 && var.ai_copilot_assignment_wait_time <= 300
    error_message = "Wait time must be between 0 and 300 seconds."
  }
}
