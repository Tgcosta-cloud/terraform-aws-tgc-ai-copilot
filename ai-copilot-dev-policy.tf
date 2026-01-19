# Developer Application Identity Policy
# This is an Identity Policy (not a Permissions Boundary)
# It grants day-to-day permissions developers need to build and deploy applications

data "aws_iam_policy_document" "developer_application_policy" {
  count = var.ai_copilot_create_developer_application_policy ? 1 : 0

  # Developer Core Services
  statement {
    sid    = "DeveloperCoreServices"
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
      "ssm:*",
      "secretsmanager:*",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  # CloudFormation for Console and CDK
  statement {
    sid    = "CloudFormationForConsoleAndCDK"
    effect = "Allow"
    actions = [
      "cloudformation:CreateStack",
      "cloudformation:UpdateStack",
      "cloudformation:DeleteStack",
      "cloudformation:Describe*",
      "cloudformation:Get*",
      "cloudformation:List*",
      "cloudformation:ValidateTemplate",
      "cloudformation:CreateChangeSet",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:DeleteChangeSet"
    ]
    resources = ["*"]
  }

  # EC2, ELB and Security Groups
  statement {
    sid    = "EC2ELBAndSecurityGroups"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags",
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
      "elasticloadbalancing:*"
    ]
    resources = ["*"]
  }

  # Allow RDS Create/Manage But Force Existing Subnet Groups
  statement {
    sid    = "AllowRDSCreateManageButForceExistingSubnetGroups"
    effect = "Allow"
    actions = [
      "rds:CreateDBInstance",
      "rds:ModifyDBInstance",
      "rds:DeleteDBInstance",
      "rds:RebootDBInstance",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:Describe*",
      "rds:List*",
      "rds:AddTagsToResource",
      "rds:RemoveTagsFromResource"
    ]
    resources = ["*"]
  }

  # Deny RDS Subnet Group Management
  statement {
    sid    = "DenyRDSSubnetGroupManagement"
    effect = "Deny"
    actions = [
      "rds:CreateDBSubnetGroup",
      "rds:ModifyDBSubnetGroup",
      "rds:DeleteDBSubnetGroup"
    ]
    resources = ["*"]
  }

  # Allow DocumentDB Create/Manage But Force Existing Subnet Groups
  statement {
    sid    = "AllowDocDBCreateManageButForceExistingSubnetGroups"
    effect = "Allow"
    actions = [
      "docdb:CreateDBCluster",
      "docdb:DeleteDBCluster",
      "docdb:ModifyDBCluster",
      "docdb:CreateDBInstance",
      "docdb:DeleteDBInstance",
      "docdb:ModifyDBInstance",
      "docdb:Describe*",
      "docdb:List*",
      "docdb:AddTagsToResource",
      "docdb:RemoveTagsFromResource"
    ]
    resources = ["*"]
  }

  # Deny DocumentDB Subnet Group Management
  statement {
    sid    = "DenyDocDBSubnetGroupManagement"
    effect = "Deny"
    actions = [
      "docdb:CreateDBSubnetGroup",
      "docdb:ModifyDBSubnetGroup",
      "docdb:DeleteDBSubnetGroup"
    ]
    resources = ["*"]
  }

  # Allow ElastiCache Create/Manage But Force Existing Subnet Groups
  statement {
    sid    = "AllowElastiCacheCreateManageButForceExistingSubnetGroups"
    effect = "Allow"
    actions = [
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticache:CreateCacheCluster",
      "elasticache:ModifyCacheCluster",
      "elasticache:DeleteCacheCluster",
      "elasticache:CreateReplicationGroup",
      "elasticache:ModifyReplicationGroup",
      "elasticache:DeleteReplicationGroup",
      "elasticache:AddTagsToResource",
      "elasticache:RemoveTagsFromResource"
    ]
    resources = ["*"]
  }

  # Deny ElastiCache Subnet Group Management
  statement {
    sid    = "DenyElastiCacheSubnetGroupManagement"
    effect = "Deny"
    actions = [
      "elasticache:CreateCacheSubnetGroup",
      "elasticache:ModifyCacheSubnetGroup",
      "elasticache:DeleteCacheSubnetGroup"
    ]
    resources = ["*"]
  }

  # Allow Auto Scaling Management
  statement {
    sid    = "AllowAutoScalingManage"
    effect = "Allow"
    actions = [
      "autoscaling:*",
      "application-autoscaling:*"
    ]
    resources = ["*"]
  }
}

# Create the Developer Application Identity Policy
resource "aws_iam_policy" "developer_application_policy" {
  count = var.ai_copilot_create_developer_application_policy ? 1 : 0

  name        = var.ai_copilot_developer_application_policy_name
  description = "Identity policy granting day-to-day permissions for developers to build and deploy applications in dev environment. Limits RDS/DocDB/ElastiCache to pre-created subnet groups maintained in shared IaC."
  path        = "/"

  policy = data.aws_iam_policy_document.developer_application_policy[0].json
}
