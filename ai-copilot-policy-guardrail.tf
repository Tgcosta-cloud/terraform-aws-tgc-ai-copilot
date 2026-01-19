# IAM Policy Document for Developers
data "aws_iam_policy_document" "ai_copilot_developer_iam_permissions_guardrail" {
  count = var.ai_copilot_create_developer_iam_policy_guardrail ? 1 : 0

  # Allow Read-Only IAM Visibility
  statement {
    sid    = "AllowReadOnlyIAMVisibility"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "access-analyzer:List*",
      "access-analyzer:Get*"
    ]
    resources = ["*"]
  }

  # Allow Create Dev App Roles Only With Required Boundary
  statement {
    sid    = "AllowCreateDevAppRolesOnlyWithRequiredBoundary"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.ai_copilot_developer_role_prefix}*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.ai_copilot_developer_permissions_boundary_name}"
      ]
    }
  }

  # Allow Manage Inline Policies On Dev App Roles
  statement {
    sid    = "AllowManageInlinePoliciesOnDevAppRoles"
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.ai_copilot_developer_role_prefix}*"
    ]
  }

  # Allow Attach/Detach Only AWS Managed Policies To Dev App Roles
  statement {
    sid    = "AllowAttachDetachOnlyAwsManagedPoliciesToDevAppRolesOptional"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.ai_copilot_developer_role_prefix}*"
    ]

    condition {
      test     = "ArnLike"
      variable = "iam:PolicyARN"
      values   = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/*"]
    }
  }

  # Allow Pass Dev App Roles To Approved Services Only
  statement {
    sid       = "AllowPassDevAppRolesToApprovedServicesOnly"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.ai_copilot_developer_role_prefix}*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = var.ai_copilot_developer_allowed_passrole_services
    }
  }

  # Deny Managed Policy Lifecycle
  statement {
    sid    = "DenyManagedPolicyLifecycle"
    effect = "Deny"
    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = ["*"]
  }

  # Deny Creating Roles Outside Dev App Prefix
  statement {
    sid           = "DenyCreatingRolesOutsideDevAppPrefix"
    effect        = "Deny"
    actions       = ["iam:CreateRole"]
    not_resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.ai_copilot_developer_role_prefix}*"
    ]
  }
}

# Create the IAM Policy
resource "aws_iam_policy" "ai_copilot_developer_iam_permissions_guardrail" {
  count = var.ai_copilot_create_developer_iam_policy_guardrail ? 1 : 0

  name        = var.ai_copilot_developer_policy_name_guardrail
  description = "Allows developers to manage application roles with enforced permissions boundary (${var.ai_copilot_developer_permissions_boundary_name})"
  path        = "/"

  policy = data.aws_iam_policy_document.ai_copilot_developer_iam_permissions_guardrail[0].json
}
