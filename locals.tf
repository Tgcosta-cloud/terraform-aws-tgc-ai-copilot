locals {
  # Control toggles
  deny_ec2_public_ip_statement            = var.ai_copilot_deny_ec2_public_ip ? [""] : []
  deny_elastic_ip_operations_statement    = var.ai_copilot_deny_elastic_ip_operations ? [""] : []
  deny_internet_facing_lb_statement       = var.ai_copilot_deny_internet_facing_lb ? [""] : []
  deny_lb_in_public_subnets_statement     = var.ai_copilot_deny_lb_in_public_subnets ? [""] : []
  deny_s3_public_access_changes_statement = var.ai_copilot_deny_s3_public_access_changes ? [""] : []

  # Determine if we should use role-based enforcement
  has_enforce_roles = length(var.ai_copilot_enforce_roles) > 0

  # Build role ARN patterns for enforcement
  roles_to_enforce = local.has_enforce_roles ? [
    for role in var.ai_copilot_enforce_roles : "arn:${data.aws_partition.current.partition}:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_${role}"
  ] : []

  ai_copilot_has_default_principal = var.ai_copilot_default_group_name != "" || var.ai_copilot_default_user_name != ""

  ai_copilot_validate_principal = (
    !var.ai_copilot_create_permission_set ||
    length(var.ai_copilot_target_ids) == 0 ||
    local.ai_copilot_has_default_principal
  ) ? true : tobool("ERROR: When ai_copilot_create_permission_set=true and ai_copilot_target_ids is not empty, you must specify either ai_copilot_default_group_name or ai_copilot_default_user_name")

}
