locals {
  # Build statements list dynamically based on enabled controls
  policy_statements = concat(
    var.ai_copilot_deny_ec2_public_ip ? [
      {
        Sid    = "DenyEC2LaunchWithPublicIPv4"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "*"
        Condition = {
          Bool = {
            "ec2:AssociatePublicIpAddress" = "true"
          }
        }
      }
    ] : [],

    var.ai_copilot_deny_elastic_ip_operations ? [
      {
        Sid    = "DenyAssociateElasticIp"
        Effect = "Deny"
        Action = [
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAllocateAndReleaseElasticIp"
        Effect = "Deny"
        Action = [
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress"
        ]
        Resource = "*"
      }
    ] : [],

    var.ai_copilot_deny_public_security_groups ? [
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv4"
        Effect   = "Deny"
        Action   = "ec2:AuthorizeSecurityGroupIngress"
        Resource = "*"
        Condition = {
          IpAddress = {
            "ec2:CidrIp" = "0.0.0.0/0"
          }
        }
      },
      {
        Sid      = "DenyWorldOpenSecurityGroupIngressIPv6"
        Effect   = "Deny"
        Action   = "ec2:AuthorizeSecurityGroupIngress"
        Resource = "*"
        Condition = {
          IpAddress = {
            "ec2:CidrIpv6" = "::/0"
          }
        }
      }
    ] : [],

    var.ai_copilot_deny_internet_facing_lb ? [
      {
        Sid    = "DenyInternetFacingLoadBalancers"
        Effect = "Deny"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "elasticloadbalancing:Scheme" = "internet-facing"
          }
        }
      }
    ] : [],

    var.ai_copilot_deny_lb_in_public_subnets && length(var.ai_copilot_public_subnet_ids) > 0 ? [
      {
        Sid    = "DenyLoadBalancersInPublicSubnets"
        Effect = "Deny"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "elasticloadbalancing:Subnet" = var.ai_copilot_public_subnet_ids
          }
        }
      }
    ] : [],

    var.ai_copilot_deny_s3_public_access_changes ? [
      {
        Sid    = "DenyChangesToS3AccountLevelBlockPublicAccess"
        Effect = "Deny"
        Action = [
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
      }
    ] : []
  )

  # Build the final policy document
  policy_document = {
    Version   = "2012-10-17"
    Statement = local.policy_statements
  }
}
