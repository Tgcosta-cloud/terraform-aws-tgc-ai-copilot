# Uses ai_copilot_target_ids for account assignment
# Supports optional default principal (group or user) for initial assignment

# ========================================
# APPROACH 1: Assign to a Default Group (RECOMMENDED)
# ========================================
# Best for: Initial setup with a default "Admins" or "Developers" group
# 
# This approach assigns the Permission Set to your target accounts
# using a default group that you specify (e.g., "Administrators")
# 
# Users in that group will automatically get access.
# You can add more groups/users later via console or by expanding the Terraform code.

# Get the default group if specified
data "aws_identitystore_group" "ai_copilot_default_group" {
  count = var.ai_copilot_create_permission_set && var.ai_copilot_default_group_name != "" ? 1 : 0

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = var.ai_copilot_default_group_name
    }
  }
}

# Get the default user if specified (alternative to group)
data "aws_identitystore_user" "ai_copilot_default_user" {
  count = var.ai_copilot_create_permission_set && var.ai_copilot_default_user_name != "" ? 1 : 0

  identity_store_id = tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.ai_copilot_default_user_name
    }
  }
}

# Assign Permission Set to all target accounts using default GROUP
resource "aws_ssoadmin_account_assignment" "default_group_assignments" {
  for_each = var.ai_copilot_create_permission_set && var.ai_copilot_default_group_name != "" ? toset(var.ai_copilot_target_ids) : []

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn

  principal_id   = data.aws_identitystore_group.ai_copilot_default_group[0].group_id
  principal_type = "GROUP"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}

# Assign Permission Set to all target accounts using default USER (if no group specified)
resource "aws_ssoadmin_account_assignment" "default_user_assignments" {
  for_each = var.ai_copilot_create_permission_set && var.ai_copilot_default_group_name == "" && var.ai_copilot_default_user_name != "" ? toset(var.ai_copilot_target_ids) : []

  instance_arn       = tolist(data.aws_ssoadmin_instances.this[0].arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.ai_copilot_developer[0].arn

  principal_id   = data.aws_identitystore_user.ai_copilot_default_user[0].user_id
  principal_type = "USER"

  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}