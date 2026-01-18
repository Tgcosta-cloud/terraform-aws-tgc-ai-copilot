locals {
  # Control toggles
  deny_ec2_public_ip_statement             = var.ai_copilot_deny_ec2_public_ip ? [""] : []
  deny_elastic_ip_operations_statement     = var.ai_copilot_deny_elastic_ip_operations ? [""] : []
  deny_public_security_groups_statement    = var.ai_copilot_deny_public_security_groups ? [""] : []
  deny_internet_facing_lb_statement        = var.ai_copilot_deny_internet_facing_lb ? [""] : []
  deny_lb_in_public_subnets_statement      = var.ai_copilot_deny_lb_in_public_subnets ? [""] : []
  deny_s3_public_access_changes_statement  = var.ai_copilot_deny_s3_public_access_changes ? [""] : []

  # Determine if we should use role-based enforcement
  has_enforce_roles = length(var.ai_copilot_enforce_roles) > 0

  # Build role ARN patterns for enforcement
  roles_to_enforce = local.has_enforce_roles ? [
    for role in var.ai_copilot_enforce_roles : "arn:${data.aws_partition.current.partition}:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_${role}"
  ] : []
}
