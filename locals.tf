locals {
  # Determine if we should use role-based enforcement
  ai_copilot_has_enforce_roles = length(var.ai_copilot_enforce_roles) > 0
  
  # Build condition for role enforcement
  # If enforce_roles is set, only those roles are blocked
  # If empty, all roles are blocked (default behavior)
  role_condition = local.ai_copilot_has_enforce_roles ? {
    StringLike = {
      "aws:PrincipalArn" = [
        for role in var.ai_copilot_enforce_roles : "arn:aws:iam::*:role/${role}"
      ]
    }
  } : {}

  # Build statements list dynamically based on enabled controls
  policy_statements = concat(
    var.ai_copilot_deny_ec2_public_ip ? [
      merge(
        {
          Sid      = "DenyEC2LaunchWithPublicIPv4"
          Effect   = "Deny"
          Action   = "ec2:RunInstances"
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = merge(
            {
              Bool = {
                "ec2:AssociatePublicIpAddress" = "true"
              }
            },
            local.role_condition
          )
        } : {
          Condition = {
            Bool = {
              "ec2:AssociatePublicIpAddress" = "true"
            }
          }
        }
      )
    ] : [],

    var.ai_copilot_deny_elastic_ip_operations ? [
      merge(
        {
          Sid    = "DenyAssociateElasticIp"
          Effect = "Deny"
          Action = [
            "ec2:AssociateAddress",
            "ec2:DisassociateAddress"
          ]
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = local.role_condition
        } : {}
      ),
      merge(
        {
          Sid    = "DenyAllocateAndReleaseElasticIp"
          Effect = "Deny"
          Action = [
            "ec2:AllocateAddress",
            "ec2:ReleaseAddress"
          ]
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = local.role_condition
        } : {}
      )
    ] : [],

    var.ai_copilot_deny_public_security_groups ? [
      merge(
        {
          Sid      = "DenyWorldOpenSecurityGroupIngressIPv4"
          Effect   = "Deny"
          Action   = "ec2:AuthorizeSecurityGroupIngress"
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = merge(
            {
              IpAddress = {
                "ec2:CidrIp" = "0.0.0.0/0"
              }
            },
            local.role_condition
          )
        } : {
          Condition = {
            IpAddress = {
              "ec2:CidrIp" = "0.0.0.0/0"
            }
          }
        }
      ),
      merge(
        {
          Sid      = "DenyWorldOpenSecurityGroupIngressIPv6"
          Effect   = "Deny"
          Action   = "ec2:AuthorizeSecurityGroupIngress"
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = merge(
            {
              IpAddress = {
                "ec2:CidrIpv6" = "::/0"
              }
            },
            local.role_condition
          )
        } : {
          Condition = {
            IpAddress = {
              "ec2:CidrIpv6" = "::/0"
            }
          }
        }
      )
    ] : [],

    var.ai_copilot_deny_internet_facing_lb ? [
      merge(
        {
          Sid    = "DenyInternetFacingLoadBalancers"
          Effect = "Deny"
          Action = [
            "elasticloadbalancing:CreateLoadBalancer"
          ]
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = merge(
            {
              StringEquals = {
                "elasticloadbalancing:Scheme" = "internet-facing"
              }
            },
            local.role_condition
          )
        } : {
          Condition = {
            StringEquals = {
              "elasticloadbalancing:Scheme" = "internet-facing"
            }
          }
        }
      )
    ] : [],

    var.ai_copilot_deny_lb_in_public_subnets && length(var.ai_copilot_public_subnet_ids) > 0 ? [
      merge(
        {
          Sid    = "DenyLoadBalancersInPublicSubnets"
          Effect = "Deny"
          Action = [
            "elasticloadbalancing:CreateLoadBalancer"
          ]
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = merge(
            {
              "ForAnyValue:StringEquals" = {
                "elasticloadbalancing:Subnet" = var.ai_copilot_public_subnet_ids
              }
            },
            local.role_condition
          )
        } : {
          Condition = {
            "ForAnyValue:StringEquals" = {
              "elasticloadbalancing:Subnet" = var.ai_copilot_public_subnet_ids
            }
          }
        }
      )
    ] : [],

    var.ai_copilot_deny_s3_public_access_changes ? [
      merge(
        {
          Sid    = "DenyChangesToS3AccountLevelBlockPublicAccess"
          Effect = "Deny"
          Action = [
            "s3:PutAccountPublicAccessBlock"
          ]
          Resource = "*"
        },
        length(keys(local.role_condition)) > 0 ? {
          Condition = local.role_condition
        } : {}
      )
    ] : []
  )

  # Build the final policy document
  policy_document = {
    Version   = "2012-10-17"
    Statement = local.policy_statements
  }
}
