locals {
  # Determine if we should use role-based enforcement
  has_enforce_roles = length(var.ai_copilot_enforce_roles) > 0
  
  # Build condition for role enforcement
  # If enforce_roles is set, only those roles are blocked
  # If empty, all roles are blocked (default behavior)
  role_condition = local.has_enforce_roles ? {
    StringLike = {
      "aws:PrincipalArn" = [
        for role in var.ai_copilot_enforce_roles : "arn:aws:iam::*:role/${role}"
      ]
    }
  } : {}

  # Build statements list dynamically based on enabled controls
  policy_statements = concat(
    var.ai_copilot_deny_ec2_public_ip ? [
      {
        Sid      = "DenyEC2LaunchWithPublicIPv4"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "*"
        Condition = merge(
          {
            Bool = {
              "ec2:AssociatePublicIpAddress" = "true"
            }
          },
          local.role_condition
        )
      }
    ] : [],

    var.ai_copilot_deny_elastic_ip_operations ? [
      {
        Sid      = "DenyAssociateElasticIp"
        Effect   = "Deny"
        Action   = [
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress"
        ]
        Resource = "*"
        Condition = local.has_enforce_roles ? local.role_condition : null
      },
      {
        Sid      = "DenyAllocateAndReleaseElasticIp"
        Effect   = "Deny"
        Action   = [
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress"
        ]
        Resource = "*"
        Condition = local.has_enforce_roles ? local.role_condition : null
      }
    ] : [],

    var.ai_copilot_deny_public_security_groups ? [
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv4"
        Effect   = "Deny"
        Action   = "ec2:AuthorizeSecurityGroupIngress"
        Resource = "*"
        Condition = merge(
          {
            IpAddress = {
              "ec2:CidrIp" = "0.0.0.0/0"
            }
          },
          local.role_condition
        )
      },
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv6"
        Effect   = "Deny"
        Action   = "ec2:AuthorizeSecurityGroupIngress"
        Resource = "*"
        Condition = merge(
          {
            IpAddress = {
              "ec2:CidrIpv6" = "::/0"
            }
          },
          local.role_condition
        )
      }
    ] : [],

    var.ai_copilot_deny_internet_facing_lb ? [
      {
        Sid      = "DenyInternetFacingLoadBalancers"
        Effect   = "Deny"
        Action   = [
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = merge(
          {
            StringEquals = {
              "elasticloadbalancing:Scheme" = "internet-facing"
            }
          },
          local.role_condition
        )
      }
    ] : [],

    var.ai_copilot_deny_lb_in_public_subnets && length(var.ai_copilot_public_subnet_ids) > 0 ? [
      {
        Sid      = "DenyLoadBalancersInPublicSubnets"
        Effect   = "Deny"
        Action   = [
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = merge(
          {
            "ForAnyValue:StringEquals" = {
              "elasticloadbalancing:Subnet" = var.ai_copilot_public_subnet_ids
            }
          },
          local.role_condition
        )
      }
    ] : [],

    var.ai_copilot_deny_s3_public_access_changes ? [
      {
        Sid      = "DenyChangesToS3AccountLevelBlockPublicAccess"
        Effect   = "Deny"
        Action   = [
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
        Condition = local.has_enforce_roles ? local.role_condition : null
      }
    ] : []
  )

  # Remove null Conditions from statements
  policy_statements_cleaned = [
    for statement in local.policy_statements : 
    statement.Condition != null ? statement : merge(
      statement,
      { for k, v in statement : k => v if k != "Condition" }
    )
  ]

  # Build the final policy document
  policy_document = {
    Version   = "2012-10-17"
    Statement = local.policy_statements_cleaned
  }
}
