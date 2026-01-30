# Reference the existing SAML provider
data "aws_iam_saml_provider" "ai_copilot_saml" {
  count = local.create_saml_role ? 1 : 0
  arn   = var.ai_copilot_saml_provider_arn
}

# Create the SAML Role with trust policy
resource "aws_iam_role" "ai_copilot_saml_developer" {
  count = local.create_saml_role ? 1 : 0
  name  = var.ai_copilot_saml_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_saml_provider.ai_copilot_saml[0].arn
        }
        Action = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })

  # Ensure policies are created before the role
  depends_on = [
    aws_iam_policy.developer_application_policy,
    aws_iam_policy.ai_copilot_developer_iam_permissions_guardrail
  ]

  tags = {
    Name        = var.ai_copilot_saml_role_name
    Purpose     = "SAML federated role for AI Copilot developers"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Attach Developer Application Policy (from ai-copilot-dev-policy.tf)
resource "aws_iam_role_policy_attachment" "developer_application_policy_attach" {
  count = local.create_saml_role && var.ai_copilot_create_developer_application_policy ? 1 : 0

  role       = aws_iam_role.ai_copilot_saml_developer[0].name
  policy_arn = aws_iam_policy.developer_application_policy[0].arn

  depends_on = [
    aws_iam_role.ai_copilot_saml_developer,
    aws_iam_policy.developer_application_policy
  ]
}

# Attach Developer IAM Guardrail Policy (from ai-copilot-policy-guardrail.tf)
resource "aws_iam_role_policy_attachment" "developer_iam_guardrail_attach" {
  count = local.create_saml_role && var.ai_copilot_create_developer_iam_policy_guardrail ? 1 : 0

  role       = aws_iam_role.ai_copilot_saml_developer[0].name
  policy_arn = aws_iam_policy.ai_copilot_developer_iam_permissions_guardrail[0].arn

  depends_on = [
    aws_iam_role.ai_copilot_saml_developer,
    aws_iam_policy.ai_copilot_developer_iam_permissions_guardrail
  ]
}
