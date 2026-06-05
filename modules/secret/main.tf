resource "aws_secretsmanager_secret" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  name                    = "${var.prefix}-${each.key}"
  description             = var.secrets[each.key].description
  recovery_window_in_days = var.recovery_window_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = nonsensitive(toset(keys(var.secrets)))

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = var.secrets[each.key].value
}
