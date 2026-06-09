#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Integration test: terraform-aws-lambda-baseline × MiniStack
#
# Usage:
#   ./scripts/test-ministack.sh            # start/stop MiniStack automatically
#   MINISTACK_RUNNING=1 ./scripts/test-ministack.sh  # reuse an already-running MiniStack
#
# Requirements: docker, docker compose, terraform, aws cli, python3, zip
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="$REPO_ROOT/tests/ministack/fixture"
TF_DIR="$REPO_ROOT/tests/ministack"
ZIP_PATH="$REPO_ROOT/tests/ministack/fixture.zip"
ENDPOINT="${MINISTACK_ENDPOINT:-http://localhost:4566}"
AWS_ARGS=(--endpoint-url "$ENDPOINT" --region us-east-1)
AWS_ENV=(
  AWS_ACCESS_KEY_ID=test
  AWS_SECRET_ACCESS_KEY=test
  AWS_DEFAULT_REGION=us-east-1
)

PASS=0
FAIL=0
ERRORS=()

# ── helpers ────────────────────────────────────────────────────────────────

log()  { echo "  $*"; }
ok()   { echo "  ✅  $*"; ((PASS++)) || true; }
fail() { echo "  ❌  $*"; ((FAIL++)) || true; ERRORS+=("$*"); }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$label"
  else
    fail "$label (expected '$expected', got '$actual')"
  fi
}

assert_nonempty() {
  local label="$1" value="$2"
  if [[ -n "$value" && "$value" != "null" ]]; then
    ok "$label"
  else
    fail "$label (empty or null)"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -q "$needle"; then
    ok "$label"
  else
    fail "$label (expected to contain '$needle')"
  fi
}

aws_cmd() { env "${AWS_ENV[@]}" aws "${AWS_ARGS[@]}" "$@"; }

# ── 1. Build fixture zip ────────────────────────────────────────────────────

echo ""
echo "━━━ 1. Build Lambda fixture zip ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
(cd "$FIXTURE_DIR" && zip -q -j "$ZIP_PATH" index.py)
log "zip: $ZIP_PATH ($(wc -c < "$ZIP_PATH") bytes)"

# ── 2. Start MiniStack ──────────────────────────────────────────────────────

echo ""
echo "━━━ 2. MiniStack ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect docker compose command (plugin vs standalone)
DOCKER_COMPOSE=""
if docker compose version &>/dev/null 2>&1; then
  DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  DOCKER_COMPOSE="docker-compose"
else
  echo "ERROR: neither 'docker compose' nor 'docker-compose' found." >&2
  echo "Install with: brew install docker-compose" >&2
  exit 1
fi

MINISTACK_MANAGED=0
if [[ "${MINISTACK_RUNNING:-0}" != "1" ]]; then
  log "Starting MiniStack via $DOCKER_COMPOSE..."
  $DOCKER_COMPOSE -f "$REPO_ROOT/docker-compose.yml" up -d --pull=missing
  MINISTACK_MANAGED=1
fi

log "Waiting for MiniStack to be healthy..."
for i in $(seq 1 30); do
  if curl -sf "$ENDPOINT/_ministack/health" > /dev/null 2>&1; then
    ok "MiniStack is up"
    break
  fi
  sleep 1
  if [[ $i -eq 30 ]]; then
    fail "MiniStack did not become healthy in 30s"
    exit 1
  fi
done

cleanup() {
  echo ""
  echo "━━━ 5. Cleanup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Running terraform destroy..."
  terraform -chdir="$TF_DIR" destroy -auto-approve \
    -var="lambda_zip_path=$ZIP_PATH" \
    -var="ministack_endpoint=$ENDPOINT" 2>&1 | tail -5 || true

  if [[ $MINISTACK_MANAGED -eq 1 ]]; then
    log "Stopping MiniStack..."
    $DOCKER_COMPOSE -f "$REPO_ROOT/docker-compose.yml" down -v --remove-orphans
  fi
}
trap cleanup EXIT

# ── 3. Terraform apply ──────────────────────────────────────────────────────

echo ""
echo "━━━ 3. Terraform apply ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "terraform init..."
terraform -chdir="$TF_DIR" init -upgrade -reconfigure 2>&1 | tail -3

log "terraform apply..."
terraform -chdir="$TF_DIR" apply -auto-approve \
  -var="lambda_zip_path=$ZIP_PATH" \
  -var="ministack_endpoint=$ENDPOINT" 2>&1 | tail -10

# Capture outputs
TF_OUT=$(terraform -chdir="$TF_DIR" output -json \
  -var="lambda_zip_path=$ZIP_PATH" \
  -var="ministack_endpoint=$ENDPOINT" 2>/dev/null || \
  terraform -chdir="$TF_DIR" output -json)

LAMBDA_ARN=$(echo "$TF_OUT"    | python3 -c "import sys,json; print(json.load(sys.stdin)['lambda_arn']['value'])")
LAMBDA_NAME=$(echo "$TF_OUT"   | python3 -c "import sys,json; print(json.load(sys.stdin)['lambda_name']['value'])")
IAM_ROLE_ARN=$(echo "$TF_OUT"  | python3 -c "import sys,json; print(json.load(sys.stdin)['iam_role_arn']['value'])")
LOG_GROUP=$(echo "$TF_OUT"     | python3 -c "import sys,json; print(json.load(sys.stdin)['log_group_name']['value'])")
SECRET_ARNS=$(echo "$TF_OUT"   | python3 -c "import sys,json; d=json.load(sys.stdin)['secret_arns']['value']; print(json.dumps(d))")

log "lambda_arn:     $LAMBDA_ARN"
log "lambda_name:    $LAMBDA_NAME"
log "iam_role_arn:   $IAM_ROLE_ARN"
log "log_group_name: $LOG_GROUP"
log "secret_arns:    $SECRET_ARNS"

ok "terraform apply completed"

# ── 4. Assertions ───────────────────────────────────────────────────────────

echo ""
echo "━━━ 4. Assertions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 4a. Lambda function exists and has the right name/role/runtime
echo ""
log "── Lambda function ──"
LAMBDA_CFG=$(aws_cmd lambda get-function --function-name "$LAMBDA_NAME" 2>&1)
assert_nonempty "lambda get-function succeeds" "$LAMBDA_CFG"

ACTUAL_RUNTIME=$(echo "$LAMBDA_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['Configuration']['Runtime'])")
assert_eq "runtime is python3.12" "python3.12" "$ACTUAL_RUNTIME"

ACTUAL_ROLE=$(echo "$LAMBDA_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['Configuration']['Role'])")
assert_eq "lambda uses the provisioned IAM role" "$IAM_ROLE_ARN" "$ACTUAL_ROLE"

ACTUAL_HANDLER=$(echo "$LAMBDA_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['Configuration']['Handler'])")
assert_eq "handler is index.handler" "index.handler" "$ACTUAL_HANDLER"

ACTUAL_MEM=$(echo "$LAMBDA_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['Configuration']['MemorySize'])")
assert_eq "memory is 128 MB" "128" "$ACTUAL_MEM"

# 4b. Secret ARN env vars are injected
echo ""
log "── Secret ARN env vars injected ──"
ACTUAL_ENV=$(echo "$LAMBDA_CFG" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['Configuration']['Environment']['Variables']))")
assert_contains "API_KEY_SECRET_ARN env var present"    "API_KEY_SECRET_ARN"    "$ACTUAL_ENV"
assert_contains "DB_PASSWORD_SECRET_ARN env var present" "DB_PASSWORD_SECRET_ARN" "$ACTUAL_ENV"
assert_contains "LOG_LEVEL env var present"              "LOG_LEVEL"              "$ACTUAL_ENV"

# 4c. IAM role exists
echo ""
log "── IAM role ──"
ROLE_NAME=$(basename "$IAM_ROLE_ARN")
ROLE_CFG=$(aws_cmd iam get-role --role-name "$ROLE_NAME" 2>&1)
assert_nonempty "iam get-role succeeds" "$ROLE_CFG"

TRUST=$(echo "$ROLE_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['Role']['AssumeRolePolicyDocument']['Statement'][0]['Principal']['Service'])")
assert_eq "role trusts lambda.amazonaws.com" "lambda.amazonaws.com" "$TRUST"

# 4d. CloudWatch log group exists with correct name + retention
echo ""
log "── CloudWatch log group ──"
CW_CFG=$(aws_cmd logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" 2>&1)
ACTUAL_LG=$(echo "$CW_CFG" | python3 -c "import sys,json; gs=json.load(sys.stdin)['logGroups']; print(gs[0]['logGroupName'] if gs else '')")
assert_eq "log group name matches" "$LOG_GROUP" "$ACTUAL_LG"

ACTUAL_RETENTION=$(echo "$CW_CFG" | python3 -c "import sys,json; gs=json.load(sys.stdin)['logGroups']; print(gs[0].get('retentionInDays','')) if gs else print('')")
assert_eq "log retention is 7 days" "7" "$ACTUAL_RETENTION"

# 4e. Secrets Manager secrets exist with correct values
echo ""
log "── Secrets Manager ──"
for KEY in api_key db_password; do
  SECRET_NAME="ministack-test-${KEY}"
  SM_CFG=$(aws_cmd secretsmanager describe-secret --secret-id "$SECRET_NAME" 2>&1)
  assert_nonempty "secret '$SECRET_NAME' exists" "$SM_CFG"

  SM_VAL=$(aws_cmd secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['SecretString'])")
  assert_nonempty "secret '$SECRET_NAME' has a value" "$SM_VAL"

  # Confirm the ARN in the output map matches what SecretsManager reports
  SM_ARN=$(echo "$SM_CFG" | python3 -c "import sys,json; print(json.load(sys.stdin)['ARN'])")
  TF_ARN=$(echo "$SECRET_ARNS" | python3 -c "import sys,json; print(json.load(sys.stdin)['${KEY}'])")
  assert_eq "secret ARN matches terraform output for '$KEY'" "$SM_ARN" "$TF_ARN"
done

# 4f. Invoke the Lambda and check the response
echo ""
log "── Lambda invocation ──"
INVOKE_RESP=$(aws_cmd lambda invoke \
  --function-name "$LAMBDA_NAME" \
  --payload '{}' \
  /dev/stdout 2>/dev/null || true)

assert_contains "invocation returns secret ARN env vars" "SECRET_ARN" "$INVOKE_RESP"
assert_contains "invocation statusCode 200" "200" "$INVOKE_RESP"

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "━━━ Results ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "  Failures:"
  for e in "${ERRORS[@]}"; do
    echo "    • $e"
  done
  echo ""
  exit 1
else
  echo ""
  echo "  All assertions passed 🎉"
  echo ""
fi
