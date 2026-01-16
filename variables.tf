variable "ai_copilot_policy_name" {
  description = "Name of the SCP policy"
  type        = string
  default     = "DenyPublicAccessSCP"
}

variable "ai_copilot_policy_description" {
  description = "Description of the SCP policy"
  type        = string
  default     = "SCP to deny public access configurations including public IPs, Elastic IPs, open security groups, internet-facing load balancers, and S3 public access changes"
}

variable "ai_copilot_environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "ai_copilot_public_subnet_ids" {
  description = "List of public subnet IDs or ARNs to deny load balancer creation (required if deny_lb_in_public_subnets is true)"
  type        = list(string)
  default     = []
}

variable "ai_copilot_target_ids" {
  description = "List of AWS Organization target IDs (Account IDs or OU IDs) to attach the policy to"
  type        = list(string)
  default     = []
}

variable "ai_copilot_tags" {
  description = "Additional tags to apply to the SCP policy"
  type        = map(string)
  default     = {}
}

# ===================================
# Control Toggles
# ===================================

variable "ai_copilot_deny_ec2_public_ip" {
  description = "Enable control to deny EC2 instances launch with public IPv4 addresses"
  type        = bool
  default     = true
}

variable "ai_copilot_deny_elastic_ip_operations" {
  description = "Enable control to deny Elastic IP allocation, release, association and disassociation"
  type        = bool
  default     = true
}

variable "ai_copilot_deny_public_security_groups" {
  description = "Enable control to deny Security Group rules with public access (0.0.0.0/0 or ::/0)"
  type        = bool
  default     = true
}

variable "ai_copilot_deny_internet_facing_lb" {
  description = "Enable control to deny internet-facing Load Balancers"
  type        = bool
  default     = true
}

variable "ai_copilot_deny_lb_in_public_subnets" {
  description = "Enable control to deny Load Balancers in specified public subnets"
  type        = bool
  default     = true
}

variable "ai_copilot_deny_s3_public_access_changes" {
  description = "Enable control to deny changes to S3 account-level Block Public Access settings"
  type        = bool
  default     = true
}
