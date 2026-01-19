# Application Permissions Boundary
# This is a PERMISSIONS BOUNDARY (not an Identity Policy)
# Defines the maximum permissions that developer roles and application roles can have
# Prevents privilege escalation even if broader permissions were mistakenly attached later

data "aws_iam_policy_document" "application_permissions_boundary" {
  count = var.ai_copilot_create_application_permissions_boundary ? 1 : 0

  # Allow Approved Developer Service Families
  statement {
    sid    = "AllowApprovedDevServiceFamilies"
    effect = "Allow"
    actions = [
      "lambda:*",
      "ecs:*",
      "ecr:*",
      "s3:*",
      "dynamodb:*",
      "sqs:*",
      "sns:*",
      "logs:*",
      "cloudwatch:*",
      "events:*",
      "xray:*",
      "apigateway:*",
      "cloudformation:*",
      "ec2:Describe*",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "elasticloadbalancing:*",
      "ssm:*",
      "secretsmanager:*",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "rds:*",
      "docdb:*",
      "elasticache:*",
      "autoscaling:*",
      "application-autoscaling:*"
    ]
    resources = ["*"]
  }

  # Hard Deny IAM and Account Control Planes
  statement {
    sid    = "HardDenyIAMAndAccountControlPlanes"
    effect = "Deny"
    actions = [
      "iam:*",
      "organizations:*",
      "account:*",
      "billing:*",
      "aws-portal:*",
      "budgets:*",
      "cur:*",
      "ce:*",
      "support:*"
    ]
    resources = ["*"]
  }

  # Deny Subnet Group Management for DB and Cache Services
  statement {
    sid    = "DenySubnetGroupManagementForDBAndCacheServices"
    effect = "Deny"
    actions = [
      "rds:CreateDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",
      "rds:DeleteDBSubnetGroup",
      "docdb:CreateDBSubnetGroup",
      "docdb:ModifyDBSubnetGroup",
      "docdb:DeleteDBSubnetGroup",
      "elasticache:CreateCacheSubnetGroup",
      "elasticache:ModifyCacheSubnetGroup",
      "elasticache:DeleteCacheSubnetGroup"
    ]
    resources = ["*"]
  }
}

# Create the Application Permissions Boundary Policy
resource "aws_iam_policy" "application_permissions_boundary" {
  count = var.ai_copilot_create_application_permissions_boundary ? 1 : 0

  name        = var.ai_copilot_application_permissions_boundary_name
  description = "Permissions boundary defining maximum permissions for developer roles and application roles. Prevents privilege escalation even if broader permissions are mistakenly attached later."
  path        = "/"

  policy = data.aws_iam_policy_document.application_permissions_boundary[0].json
}
