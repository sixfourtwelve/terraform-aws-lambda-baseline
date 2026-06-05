# Issues — terraform-aws-lambda-baseline

This document lists known defects and improvements in this Terraform module, written
for an AI agent to act on. Each issue includes the affected file(s), the problem, the
impact, and a concrete fix. Severities: 🔴 Critical (broken/incorrect behavior),
🟠 Security, 🟡 Hygiene/best-practice.

Validation baseline at time of writing:
- `terraform validate` → passes (syntax is valid)
- `terraform fmt -check -recursive` → **fails** on `modules/iam/main.tf`

---

## 🔴 Critical functional bugs

### 1. CloudWatch logging IAM policy is never attached to the Lambda role
- **File:** `modules/iam/main.tf`
- **Problem:** `aws_iam_policy.this` (`${prefix}-cloudwatch`) is created, but there is no
  `aws_iam_role_policy_attachment` that references it. Only the `extra` and `secrets_generic`
  attachments exist.
- **Impact:** The Lambda execution role has **no permission to create log streams or put log
  events**. Logging silently fails. Contradicts the README claim of least-privilege CloudWatch
  write access.
- **Fix:** Add an attachment:
  ```hcl
  resource "aws_iam_role_policy_attachment" "cloudwatch" {
    role       = aws_iam_role.this.name
    policy_arn = aws_iam_policy.this.arn
  }
  ```

### 2. Provisioned CloudWatch log group is orphaned — the Lambda never uses it
- **Files:** `modules/cloudwatch/main.tf`, `modules/lambda/main.tf`, `modules/lambda/variables.tf`, `main.tf`
- **Problem:** AWS auto-creates a log group named `/aws/lambda/<function_name>` (here
  `/aws/lambda/${prefix}-lambda`). This module instead creates `${prefix}-log-group`, which does
  not match, and the Lambda has no `logging_config` pointing to it. `var.log_group_name` is passed
  into the lambda module but **never referenced** in `modules/lambda/main.tf` (dead wiring).
- **Impact:** The custom log group stays empty; the Lambda logs to a different, unmanaged group
  (with no retention setting). Retention config is effectively not applied to real logs.
- **Fix (choose one):**
  - **A (recommended):** Name the log group `/aws/lambda/${prefix}-lambda` in
    `modules/cloudwatch/main.tf`, and add a `logging_config` block (or `depends_on`) in the Lambda
    so it uses the managed group. Reference `var.log_group_name` in the lambda resource.
  - **B:** Remove the unused `log_group_name` variable and the cross-module wiring if a separate
    log group is not intended.

### 3. IAM module's secret-access policy is dead code
- **Files:** `modules/iam/main.tf`, `main.tf`
- **Problem:** `main.tf` never passes `secret_arns` into the `iam` module (it only passes them to
  the `lambda` module on line ~54). So `var.secret_arns` defaults to `[]`, the `count` guard is 0,
  and the `secrets_generic` policy + attachment are **never created**. Secret access relies solely
  on the resource-based `aws_secretsmanager_secret_policy` in `modules/secret/main.tf`.
- **Impact:** The identity-based secret permission advertised in the README does not exist. The
  effective access model is implicit and inconsistent.
- **Fix:** Decide on a single model. Preferred: pass scoped secret ARNs into the IAM module and
  attach an identity policy limited to those ARNs; remove the resource policy (or vice versa).
  Remove whichever path is unused.

---

## 🟠 Security issues

### 4. Over-broad `Resource = "*"` on the secrets identity policy
- **File:** `modules/iam/main.tf` (`aws_iam_policy.secrets_generic`)
- **Problem:** Grants `secretsmanager:GetSecretValue` on **all secrets in the account**. Currently
  dead code (see #3), but a latent footgun if it is ever wired up.
- **Impact:** Violates least privilege; potential cross-secret access.
- **Fix:** Scope `Resource` to the specific secret ARNs (e.g. the values from
  `module.secret.secret_arns`).

### 5. Inconsistent / ambiguous secret-access model
- **Files:** `modules/iam/main.tf`, `modules/secret/main.tf`
- **Problem:** The module mixes a resource-based secret policy with a (broken) identity-based
  policy, making the true effective permissions hard to reason about.
- **Fix:** Standardize on one approach (identity policy scoped to specific secret ARNs is the
  common choice for Lambda execution roles).

---

## 🟡 Hygiene & best-practice issues

### 6. Stray `.new` scratch files committed to the repo
- **Files:** `main.tf.new`, `modules/secret/main.tf.new`
- **Problem:** `main.tf.new` is identical to `main.tf`. `modules/secret/main.tf.new` is
  **malformed** (has a `}` where a `]` should be). These look like leftover editor scratch files.
- **Fix:** Delete both files.

### 7. `terraform fmt -check` fails (CI will fail)
- **File:** `modules/iam/main.tf` (trailing whitespace around the `secrets_generic` block)
- **Problem:** The CI workflow runs `terraform fmt -check -recursive`, which currently fails.
- **Fix:** Run `terraform fmt -recursive` and commit the result.

### 8. Duplicate `required_version` block
- **Files:** `main.tf`, `versions.tf`
- **Problem:** `terraform { required_version = ">= 1.6.0" }` is declared in both files.
- **Fix:** Keep it only in `versions.tf`; remove the duplicate `terraform` block from `main.tf`
  (keep the `locals`).

### 9. Misleading ordering comments
- **File:** `main.tf`
- **Problem:** Comments like "Create X first/after/last" imply declaration order controls
  sequencing. Terraform orders by reference dependencies, not comment order.
- **Fix:** Remove or reword the comments to avoid confusion.

### 10. Unused `description` field on secrets
- **Files:** `variables.tf`, `modules/secret/variables.tf`, `modules/secret/main.tf`
- **Problem:** The `secrets` object type defines a `description` attribute that is never applied to
  `aws_secretsmanager_secret`.
- **Fix:** Set `description = each.value.description` on the secret resource, or remove the field.

### 11. README is significantly out of date (docs drift)
- **File:** `README.md`
- **Problems:**
  - Usage shows `secret_value = var.payments_api_key`; the real variable is `secrets`
    (`map(object({ value, description }))`).
  - Inputs table documents a non-existent `secret_value`; real vars `secrets` and
    `environment_variables` are undocumented.
  - Outputs table lists `secret_arn`; the actual output is `secret_arns` (a map).
  - Claims env var `SECRET_ARN=<secret_arn>`; the lambda actually injects per-secret
    `<KEY>_SECRET_ARN`.
  - Notes claim a least-privilege identity policy for secrets that is not actually attached (see #3).
- **Fix:** Rewrite Usage, Inputs, Outputs, and Notes to match the actual variables, outputs, and
  injected env var naming.

### 12. Minor robustness/hardening gaps
- **Files:** `modules/secret/main.tf`, `modules/lambda/main.tf`
- **Problems / suggestions:**
  - Secrets have no `recovery_window_in_days`; the default 30-day recovery window blocks recreating
    a same-named secret in dev. Consider `recovery_window_in_days = 0` for non-prod.
  - For a "baseline" module, consider exposing optional hardening: X-Ray tracing
    (`tracing_config`), `reserved_concurrent_executions`, and `kms_key_arn` for env var encryption.
- **Fix:** Add optional variables with safe defaults; document them.

---

## Suggested fix order
1. #1 — attach the CloudWatch policy (unblocks logging permissions).
2. #2 — fix or remove the log-group wiring (so retention applies to real logs).
3. #3 / #4 / #5 — settle on one scoped secret-access model; remove dead code.
4. #6 / #7 — delete `.new` files and run `terraform fmt` (unblocks CI).
5. #8 / #9 / #10 — config cleanup.
6. #11 — update README to match reality.
7. #12 — optional hardening.

## Verification after fixes
- `terraform fmt -check -recursive` → should pass
- `terraform validate` → should pass
- Confirm the Lambda role has both CloudWatch logging and scoped secret access attached.
- Confirm the Lambda writes to the managed log group with the configured retention.
