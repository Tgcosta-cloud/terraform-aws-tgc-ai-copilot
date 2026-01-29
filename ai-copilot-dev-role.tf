data "aws_iam_openid_connect_provider" "example" {
count = var.ai_copilot_create_developer_application_policy ? 1 : 0
  arn = "arn:aws:iam::274016496335:saml-provider/ContaAzureteste"
}
# 2️⃣ Criar a Role com trust policy para SAML
resource "aws_iam_role" "saml_role" {
count = var.ai_copilot_create_developer_application_policy ? 1 : 0
  name = "SAML-ReadOnly-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.example[0].arn
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
}

# 3️⃣ Anexar uma política de exemplo (ReadOnly)
resource "aws_iam_role_policy_attachment" "readonly_attach" {
count = var.ai_copilot_create_developer_application_policy ? 1 : 0
  role       = aws_iam_role.saml_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# 4️⃣ (Opcional) Política inline customizada
resource "aws_iam_role_policy" "custom_policy" {
count = var.ai_copilot_create_developer_application_policy ? 1 : 0
  name = "CustomSAMLPolicy"
  role = aws_iam_role.saml_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "*"
      }
    ]
  })
}
