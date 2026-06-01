# terraform-aws-lambda-baseline

A Terraform module that provisions a baseline AWS Lambda setup, including an IAM execution role, a Secrets Manager secret, and a CloudWatch log group — all wired together with least-privilege IAM policies.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Lambda Function                    │
│  runtime: var.lambda_runtime  handler: index.handler│
│  env: SECRET_ARN=<secret_arn>                       │
└────────────┬───────────────────────┬────────────────┘
             │ assumes               │ writes logs
             ▼                       ▼
     ┌───────────────┐     ┌──────────────────────┐
     │   IAM Role    │     │  CloudWatch Log Group │
     │ + CW policy   │     └──────────────────────┘
     │ + SM policy   │
     │ + extra ARNs  │
     └───────┬───────┘
             │ GetSecretValue
             ▼
     ┌───────────────┐
     │    Secrets    │
     │    Manager    │
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
  secret_value    = var.payments_api_key

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
| `secret_value` | `string` | — | yes | Secret payload to store in Secrets Manager (sensitive) |
| `lambda_runtime` | `string` | `"python3.12"` | no | Lambda runtime identifier |
| `lambda_memory_mb` | `number` | `512` | no | Amount of memory (MB) allocated to the Lambda function |
| `lambda_timeout_seconds` | `number` | `30` | no | Maximum execution time (seconds) for the Lambda function |
| `log_retention_days` | `number` | `30` | no | Number of days to retain CloudWatch logs |
| `extra_iam_policy_arns` | `list(string)` | `[]` | no | Additional AWS managed policy ARNs to attach to the execution role |
| `tags` | `map(string)` | `{}` | no | Tags applied to every resource |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_arn` | ARN of the Lambda function |
| `lambda_name` | Name of the Lambda function |
| `secret_arn` | ARN of the Secrets Manager secret |
| `log_group_name` | Name of the CloudWatch log group |
| `iam_role_arn` | ARN of the Lambda IAM execution role |

## Notes

- The Lambda handler is hardcoded to `index.handler`. Ensure your deployment package exposes this entrypoint.
- The `SECRET_ARN` environment variable is automatically injected into the Lambda function at deploy time.
- The execution role is granted least-privilege access: CloudWatch Logs write access to the provisioned log group and `secretsmanager:GetSecretValue` on the provisioned secret only.
- `secret_value` is marked sensitive and will not appear in Terraform plan output.

