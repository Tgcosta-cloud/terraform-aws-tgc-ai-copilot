# account-assignment.tf
# Add this file to your ai-copilot module to enable account assignments

# ========================================
# Data Sources for Identity Center
# ========================================

# Get Identity Center users by username
data "aws_identitystore_user" "ai_copilot_users" {
  for_each = var.ai_copilot_create_permission_set ? toset(var.ai_copilot_user_names) : []

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.value
    }
  }
}

# Get Identity Center groups by display name
data "aws_identitystore_group" "ai_copilot_groups" {
  for_each = var.ai_copilot_create_permission_set ? toset(var.ai_copilot_group_names) : []

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}

# ========================================
# Account Assignments for Users
# ========================================

resource "aws_ssoadmin_account_assignment" "ai_copilot_user_assignments" {
  for_each = var.ai_copilot_create_permission_set ? {
    for assignment in local.ai_copilot_user_account_assignments : 
    "${assignment.user}-${assignment.account}" => assignment
  } : {}

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn

  principal_id   = data.aws_identitystore_user.ai_copilot_users[each.value.user].user_id
  principal_type = "USER"

  target_id   = each.value.account
  target_type = "AWS_ACCOUNT"
}

# ========================================
# Account Assignments for Groups
# ========================================

resource "aws_ssoadmin_account_assignment" "ai_copilot_group_assignments" {
  for_each = var.ai_copilot_create_permission_set ? {
    for assignment in local.ai_copilot_group_account_assignments : 
    "${assignment.group}-${assignment.account}" => assignment
  } : {}

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn

  principal_id   = data.aws_identitystore_group.ai_copilot_groups[each.value.group].group_id
  principal_type = "GROUP"

  target_id   = each.value.account
  target_type = "AWS_ACCOUNT"
}

# ========================================
# Locals for Cartesian Products
# ========================================

locals {
  # Create all combinations of users × accounts
  ai_copilot_user_account_assignments = flatten([
    for user in var.ai_copilot_user_names : [
      for account in var.ai_copilot_target_account_ids : {
        user    = user
        account = account
      }
    ]
  ])

  # Create all combinations of groups × accounts
  ai_copilot_group_account_assignments = flatten([
    for group in var.ai_copilot_group_names : [
      for account in var.ai_copilot_target_account_ids : {
        group   = group
        account = account
      }
    ]
  ])
}

# ========================================
# Outputs
# ========================================

output "ai_copilot_permission_set_arn" {
  description = "ARN of the AI Copilot Permission Set"
  value       = var.ai_copilot_create_permission_set ? aws_ssoadmin_permission_set.ai_copilot_developer[0].arn : null
}

output "ai_copilot_user_assignments" {
  description = "Map of user account assignments created"
  value = var.ai_copilot_create_permission_set ? {
    for k, v in aws_ssoadmin_account_assignment.ai_copilot_user_assignments :
    k => {
      user       = v.principal_id
      account    = v.target_id
      created_at = v.id
    }
  } : {}
}

output "ai_copilot_group_assignments" {
  description = "Map of group account assignments created"
  value = var.ai_copilot_create_permission_set ? {
    for k, v in aws_ssoadmin_account_assignment.ai_copilot_group_assignments :
    k => {
      group      = v.principal_id
      account    = v.target_id
      created_at = v.id
    }
  } : {}
}

output "ai_copilot_assignment_summary" {
  description = "Summary of all assignments"
  value = var.ai_copilot_create_permission_set ? {
    permission_set_name = aws_ssoadmin_permission_set.ai_copilot_developer[0].name
    total_user_assignments = length(aws_ssoadmin_account_assignment.ai_copilot_user_assignments)
    total_group_assignments = length(aws_ssoadmin_account_assignment.ai_copilot_group_assignments)
    target_accounts = var.ai_copilot_target_account_ids
    users_assigned = var.ai_copilot_user_names
    groups_assigned = var.ai_copilot_group_names
  } : null
}
