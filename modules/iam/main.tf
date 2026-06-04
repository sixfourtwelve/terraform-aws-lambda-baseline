resource "aws_iam_role" "this" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this" {
  name = "${var.prefix}-cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.cloudwatch_log_group}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each = toset(var.extra_iam_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Create a generic secret access policy that can be attached later if needed
resource "aws_iam_policy" "secrets_generic" {
  count = var.secret_arns != null && length(var.secret_arns) > 0 ? 1 : 0

  name = "${var.prefix}-secrets-generic"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"  # Generic access pattern
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_generic" {
  count = var.secret_arns != null && length(var.secret_arns) > 0 ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.secrets_generic[0].arn
}