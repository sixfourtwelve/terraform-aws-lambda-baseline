# terraform-aws-lambda-baseline
[![Terraform Checks](https://github.com/sixfourtwelve/terraform-aws-lambda-baseline/actions/workflows/terraform-checks.yml/badge.svg)](https://github.com/sixfourtwelve/terraform-aws-lambda-baseline/actions/workflows/terraform-checks.yml)

A Terraform module that provisions a baseline AWS Lambda setup, including:
- A CloudWatch log group (with configurable retention)
- Zero or more Secrets Manager secrets
- A least-privilege IAM execution role scoped to both
- The Lambda function itself, wired to all of the above

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Lambda Function                           │
│  runtime: var.lambda_runtime    handler: index.handler           │
│  env: <KEY>_SECRET_ARN=<arn>, ...                                │
└──────────────────┬────────────────────────────┬──────────────────┘
                   │ assumes                     │ writes logs (JSON)
                   ▼                             ▼
           ┌───────────────┐       ┌─────────────────────────────┐
           │   IAM Role    │       │     CloudWatch Log Group     │
           │ + CW policy   │       │  /aws/lambda/<prefix>-lambda │
           │ + SM policy   │       └─────────────────────────────┘
           │ + extra ARNs  │
           └───────┬───────┘
                   │ GetSecretValue (scoped to each provisioned secret ARN)
                   ▼
           ┌───────────────┐
           │    Secrets    │
           │    Manager    │
           │   (0 .. n)    │
           └───────────────┘
```

All resources are named using the prefix `{environment}-{name}`.

## Usage

```hcl
module "my_lambda" {
  source = "github.com/your-org/terraform-aws-lambda-baseline"

  name        = "payments-processor"
  environment = "prod"

  lambda_zip_path = "${path.module}/dist/function.zip"

  secrets = {
    api_key = {
      value       = var.payments_api_key
      description = "Payments API key"
    }
    db_password = {
      value       = var.db_password
      description = "Database password"
    }
  }

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  lambda_runtime         = "python3.12"
  lambda_memory_mb       = 512
  lambda_timeout_seconds = 30
  log_retention_days     = 30

  extra_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess",
  ]

  tags = {
    Team    = "platform"
    Service = "payments"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 6.0 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `name` | `string` | — | yes | Base name for all resources, e.g. `payments-processor` |
| `environment` | `string` | — | yes | Deployment environment: `dev`, `staging`, or `prod` |
| `lambda_zip_path` | `string` | — | yes | Local path to the zipped Lambda deployment package |
| `secrets` | `map(object({value=string, description=string}))` | `{}` | no | Secrets to create in Secrets Manager; key becomes part of the secret name |
| `environment_variables` | `map(string)` | `{}` | no | Plain-text env vars passed to the Lambda |
| `lambda_runtime` | `string` | `"python3.12"` | no | Lambda runtime identifier |
| `lambda_memory_mb` | `number` | `512` | no | Memory (MB) allocated to the Lambda |
| `lambda_timeout_seconds` | `number` | `30` | no | Maximum execution time in seconds |
| `lambda_tracing_mode` | `string` | `"PassThrough"` | no | X-Ray tracing mode: `PassThrough` or `Active` |
| `lambda_reserved_concurrency` | `number` | `-1` | no | Reserved concurrency; `-1` = unreserved, `0` = disabled |
| `log_retention_days` | `number` | `30` | no | Days to retain CloudWatch logs |
| `secret_recovery_window_days` | `number` | `30` | no | Days before a deleted secret is permanently removed; `0` disables recovery |
| `extra_iam_policy_arns` | `list(string)` | `[]` | no | Additional managed policy ARNs to attach to the execution role |
| `tags` | `map(string)` | `{}` | no | Tags applied to every resource |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_arn` | ARN of the Lambda function |
| `lambda_name` | Name of the Lambda function |
| `secret_arns` | Map of `secret_key → ARN` for all provisioned secrets |
| `log_group_name` | Name of the CloudWatch log group |
| `iam_role_arn` | ARN of the Lambda IAM execution role |

## Local integration testing

The repo ships a full integration test suite that runs Terraform against
[MiniStack](https://ministack.org/) — a free, MIT-licensed AWS emulator
(drop-in LocalStack alternative) that supports Lambda, IAM, Secrets Manager,
and CloudWatch Logs out of the box.

**Prerequisites:** Docker (Colima, Docker Desktop, etc.), `docker-compose`,
`terraform`, `aws` CLI, `python3`, `zip`.

```bash
./scripts/test-ministack.sh
```

The script will:
1. Build a minimal Lambda zip from `tests/ministack/fixture/`
2. Start MiniStack on port 4566 (stopped automatically on exit)
3. Run `terraform apply` against it
4. Assert every resource — Lambda config, IAM trust policy, CloudWatch
   retention, Secrets Manager values, secret ARN env vars, and a live Lambda
   invocation
5. `terraform destroy` and stop MiniStack

To reuse an already-running MiniStack container:

```bash
MINISTACK_RUNNING=1 ./scripts/test-ministack.sh
```

To run against a remote MiniStack (e.g. in CI with the container on a
different host):

```bash
MINISTACK_ENDPOINT=http://ministack:4566 MINISTACK_RUNNING=1 ./scripts/test-ministack.sh
```

## Notes

- **Handler:** hardcoded to `index.handler`. Ensure your deployment package exposes this entrypoint.
- **Secret injection:** each secret's ARN is injected as `<KEY>_SECRET_ARN` (key uppercased). For the example above: `API_KEY_SECRET_ARN` and `DB_PASSWORD_SECRET_ARN`. Read these at runtime to fetch values from Secrets Manager.
- **Least-privilege IAM:** the execution role is granted CloudWatch Logs write access scoped to the provisioned log group, and `secretsmanager:GetSecretValue` scoped to the specific secret ARNs provisioned by this module — no wildcards.
- **Log format:** logs are written in JSON format to `/aws/lambda/{environment}-{name}-lambda` with the configured retention policy applied.
- **Sensitive values:** `secrets` is marked sensitive and will not appear in Terraform plan output.
- **Dev/test tip:** set `secret_recovery_window_days = 0` to allow immediate recreation of secrets with the same name after a `terraform destroy`.
