locals {
  # Determine if we should use role-based enforcement
  has_enforce_roles = length(var.ai_copilot_enforce_roles) > 0
  
  # Build condition for role enforcement
  role_condition = local.has_enforce_roles ? {
    ArnLike = {
      "aws:PrincipalArn" = [
        for role in var.ai_copilot_enforce_roles : "arn:${data.aws_partition.current.partition}:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_${role}"
      ]
    }
  } : {}

  # Build statements list dynamically based on enabled controls
  policy_statements_raw = concat(
    var.ai_copilot_deny_ec2_public_ip ? [
      {
        Sid      = "DenyEC2LaunchWithPublicIPv4"
        Effect   = "Deny"
        Action   = ["ec2:RunInstances"]
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
        Resource   = "*"
        Condition  = local.role_condition
      },
      {
        Sid      = "DenyAllocateAndReleaseElasticIp"
        Effect   = "Deny"
        Action   = [
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress"
        ]
        Resource   = "*"
        Condition  = local.role_condition
      }
    ] : [],

    var.ai_copilot_deny_public_security_groups ? [
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv4"
        Effect   = "Deny"
        Action   = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:ModifySecurityGroupRules"
        ]
        Resource = "*"
        Condition = merge(
          {
            "ForAnyValue:StringEquals" = {
              "ec2:Ipv4Ranges" = ["0.0.0.0/0"]
            }
          },
          local.role_condition
        )
      },
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv6"
        Effect   = "Deny"
        Action   = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:ModifySecurityGroupRules"
        ]
        Resource = "*"
        Condition = merge(
          {
            "ForAnyValue:StringEquals" = {
              "ec2:Ipv6Ranges" = ["::/0"]
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
        Resource   = "*"
        Condition  = local.role_condition
      }
    ] : []
  )

  # First pass: create statements WITH Condition (only if Condition is not empty)
  policy_statements_with_condition = [
    for stmt in local.policy_statements_raw :
    {
      Sid       = stmt.Sid
      Effect    = stmt.Effect
      Action    = stmt.Action
      Resource  = stmt.Resource
      Condition = stmt.Condition
    }
    if length(keys(stmt.Condition)) > 0
  ]

  # Second pass: create statements WITHOUT Condition (only if Condition is empty)
  policy_statements_without_condition = [
    for stmt in local.policy_statements_raw :
    {
      Sid      = stmt.Sid
      Effect   = stmt.Effect
      Action   = stmt.Action
      Resource = stmt.Resource
    }
    if length(keys(stmt.Condition)) == 0
  ]

  # Combine both lists
  policy_statements = concat(
    local.policy_statements_with_condition,
    local.policy_statements_without_condition
  )

  # Build the final policy document
  policy_document = {
    Version   = "2012-10-17"
    Statement = local.policy_statements
  }
}