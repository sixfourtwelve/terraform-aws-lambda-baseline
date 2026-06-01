resource "aws_secretsmanager_secret" "this" {
  name = "${var.prefix}-secret"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = var.secrets
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.value
}

resource "aws_secretsmanager_secret_policy" "this" {
  for_each   = var.secrets
  secret_arn = aws_secretsmanager_secret.this[each.key].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.iam_role_arn
        }
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}
