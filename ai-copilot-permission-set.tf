# AI Copilot Developer Permission Set for AWS IAM Identity Center
# This creates a Permission Set with all necessary policies for developer access

# Get the SSO Instance
data "aws_ssoadmin_instances" "this" {
  count = var.ai_copilot_create_permission_set ? 1 : 0
}

# Create the Permission Set
resource "aws_ssoadmin_permission_set" "ai_copilot_developer" {
  count = var.ai_copilot_create_permission_set ? 1 : 0

  name             = var.ai_copilot_permission_set_name
  description      = var.ai_copilot_permission_set_description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  session_duration = var.ai_copilot_session_duration

}

# Attach the Developer Application Policy (Identity Policy)
resource "aws_ssoadmin_customer_managed_policy_attachment" "developer_application_policy" {
  count = var.ai_copilot_create_permission_set && var.ai_copilot_attach_developer_application_policy ? 1 : 0

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn
  customer_managed_policy_reference {
    name = var.ai_copilot_developer_application_policy_name
    path = "/"
  }
}

# Attach the Developer IAM Permissions Guardrail Policy
resource "aws_ssoadmin_customer_managed_policy_attachment" "developer_iam_guardrail" {
  count = var.ai_copilot_create_permission_set && var.ai_copilot_attach_developer_iam_guardrail ? 1 : 0

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn
  customer_managed_policy_reference {
    name = var.ai_copilot_developer_policy_name_guardrail
    path = "/"
  }

}
