resource "aws_organizations_policy" "deny_public_access" {
  name        = var.ai_copilot_policy_name
  description = var.ai_copilot_policy_description
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode(local.policy_document)

  tags = merge(
    var.ai_copilot_tags,
    {
      Name        = var.ai_copilot_policy_name
      ManagedBy   = "Terraform"
      PolicyType  = "SCP"
      Environment = var.ai_copilot_environment
    }
  )
}

resource "aws_organizations_policy_attachment" "attach_to_targets" {
  for_each = toset(var.ai_copilot_target_ids)

  policy_id = aws_organizations_policy.deny_public_access.id
  target_id = each.value
}