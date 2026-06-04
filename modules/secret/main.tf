resource "aws_secretsmanager_secret" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  name = "${var.prefix}-${each.key}"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = var.secrets[each.key].value
}

# Updated: Create a more flexible policy that doesn't require direct ARN references during creation
resource "aws_secretsmanager_secret_policy" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

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
        }
        Resource = "*"
      }
    ]
  })
}