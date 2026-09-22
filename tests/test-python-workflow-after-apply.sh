#!/bin/bash
# --lang=python で空ディレクトリに適用した直後、生成される lint workflow の
# ruff check / ruff format --check / mypy / pytest が終了コード 0 になることを検査する。
#
# mypy は pyproject.toml の python_version を実際に読み、
# 「is not supported」を出さないことも検査する。python_version を 3.9 に戻すと、
# mypy 2.x はその警告を出してこのテストは失敗する。
# mypy の「.py が無い」ガード、または pytest の exit 5 ガードを外すと、
# 生成された run を実行した時点で非 0 になり、このテストは失敗する。
# 緩和は対象ファイルが 1 件も無いときだけにする。テストがあるのに全件 deselect
# された exit 5 や、.py があるのに exclude で隠した mypy の exit 2 を成功にすると、
# このテストは失敗する。
#
# ruff、mypy、pytest、または pytest-cov が無いときは、workflow の手順を実行したことにしない。
# REQUIRE_TOOLS=1 のときは失敗する（CI はこれで、未導入を成功にしない）。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-python-workflow.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

read_step_run() {
  local file="$1"
  local step_name="$2"
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    python3 - "$file" "$step_name" <<'PY'
import sys
import yaml

path, name = sys.argv[1], sys.argv[2]
data = yaml.safe_load(open(path))
steps = data["jobs"]["quality"]["steps"]
for step in steps:
    if step.get("name") == name:
        run = step.get("run")
        if not isinstance(run, str) or not run.strip():
            sys.exit(f"step {name} has no run script")
        sys.stdout.write(run)
        if not run.endswith("\n"):
            sys.stdout.write("\n")
        raise SystemExit(0)
sys.exit(f"missing step: {name}")
PY
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml - "$file" "$step_name" <<'RUBY'
path, name = ARGV
data = YAML.safe_load(File.read(path), aliases: true)
steps = data.fetch("jobs").fetch("quality").fetch("steps")
steps.each do |step|
  next unless step["name"] == name
  run = step["run"]
  abort("step #{name} has no run script") unless run.is_a?(String) && !run.strip.empty?
  print run
  print "\n" unless run.end_with?("\n")
  exit 0
end
abort("missing step: #{name}")
RUBY
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}

run_workflow_step_capture() {
  local name="$1"
  local script step_status
  # exit inside $(...) はサブシェルで終わり、親の set -e が失敗を取りこぼすことがある。
  # 成否はファイルに残し、出力もファイルに残す。
  script="$(read_step_run "$workflow" "$name")" || fail "could not read workflow step: $name"
  printf '%s' "$script" >"$TEST_ROOT/step.sh"
  set +e
  (cd "$target" && bash "$TEST_ROOT/step.sh") >"$TEST_ROOT/step.out" 2>&1
  step_status=$?
  set -e
  printf '%s\n' "$step_status" >"$TEST_ROOT/step.status"
  cat "$TEST_ROOT/step.out"
}

run_workflow_step() {
  local name="$1"
  local step_status
  run_workflow_step_capture "$name"
  step_status="$(cat "$TEST_ROOT/step.status")"
  if [ "$step_status" -ne 0 ]; then
    fail "workflow step '$name' must exit 0 (exit $step_status; output: $(cat "$TEST_ROOT/step.out"))"
  fi
}

# 緩和を外すと成功してしまう穴。非 0 で終わり、空ツリー用の成功メッセージを出さないこと。
assert_step_rejects_hidden_targets() {
  local name="$1"
  local must_have="$2"
  local must_not="$3"
  local step_status
  run_workflow_step_capture "$name" >/dev/null
  step_status="$(cat "$TEST_ROOT/step.status")"
  if [ "$step_status" -eq 0 ]; then
    fail "workflow step '$name' must fail (output: $(cat "$TEST_ROOT/step.out"))"
  fi
  grep -Fq "$must_have" "$TEST_ROOT/step.out" \
    || fail "workflow step '$name' must show '$must_have' (output: $(cat "$TEST_ROOT/step.out"))"
  if grep -Fq "$must_not" "$TEST_ROOT/step.out"; then
    fail "workflow step '$name' must not waive this run (output: $(cat "$TEST_ROOT/step.out"))"
  fi
}

target="$TEST_ROOT/project"
mkdir -p "$target"
bash "$APPLY" "$target" sample-pkg owner sample-pkg --lang=python --conduct-contact=conduct@example.org >/dev/null
workflow="$target/.github/workflows/lint.yml"
[ -f "$workflow" ] || fail "apply must install .github/workflows/lint.yml"

missing=()
command -v ruff >/dev/null 2>&1 || missing+=(ruff)
command -v mypy >/dev/null 2>&1 || missing+=(mypy)
command -v pytest >/dev/null 2>&1 || missing+=(pytest)
if command -v pytest >/dev/null 2>&1; then
  help_out="$(cd "$TEST_ROOT" && pytest -p no:cacheprovider --help 2>&1)" || help_out=""
  if ! printf '%s\n' "$help_out" | grep -q -- '--cov'; then
    missing+=(pytest-cov)
  fi
fi
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; ruff check, ruff format, mypy, and pytest were not run"
  exit 0
fi

# キャッシュは適用先（一時ディレクトリ）の外、このテストの一時領域に置く。
export NO_COLOR=1
export PY_COLORS=0
export MYPY_CACHE_DIR="$TEST_ROOT/mypy-cache"
export RUFF_CACHE_DIR="$TEST_ROOT/ruff-cache"
export PYTEST_ADDOPTS="-p no:cacheprovider"

run_workflow_step "Run ruff check" >/dev/null
run_workflow_step "Run ruff format check" >/dev/null

run_workflow_step "Run mypy" >"$TEST_ROOT/mypy.out"
if grep -Fq "is not supported" "$TEST_ROOT/mypy.out"; then
  fail "mypy must accept python_version without an unsupported-version warning (output: $(cat "$TEST_ROOT/mypy.out"))"
fi
grep -Fq "There are no .py[i] files in directory '.'" "$TEST_ROOT/mypy.out" \
  || fail "mypy must run against the applied tree (output: $(cat "$TEST_ROOT/mypy.out"))"

run_workflow_step "Run tests" >"$TEST_ROOT/pytest.out"
grep -Fq "collected 0 items" "$TEST_ROOT/pytest.out" \
  || fail "pytest must run and collect zero tests on a fresh apply (output: $(cat "$TEST_ROOT/pytest.out"))"
grep -Fq "treating pytest exit code 5 as success" "$TEST_ROOT/pytest.out" \
  || fail "pytest exit code 5 must be treated as success (output: $(cat "$TEST_ROOT/pytest.out"))"

# テストファイルがあるのに addopts の -m slow で全件 deselect されると、
# pytest は exit 5 になる。ファイルが残っているので成功にしない。
mkdir -p "$target/tests"
cat >"$target/tests/test_sample.py" <<'PY'
def test_sample() -> None:
    assert True
PY
awk '
  /^addopts = \[/ && !inserted {
    print
    print "    \"-m\","
    print "    \"slow\","
    inserted = 1
    next
  }
  { print }
' "$target/pyproject.toml" >"$TEST_ROOT/pyproject.deselect.toml"
mv "$TEST_ROOT/pyproject.deselect.toml" "$target/pyproject.toml"
grep -Fq '"-m",' "$target/pyproject.toml" \
  || fail "failed to set pytest addopts -m slow"
assert_step_rejects_hidden_targets \
  "Run tests" \
  "deselected" \
  "treating pytest exit code 5 as success"

# テンプレートの python_files は test_*.py だけなので *_test.py は収集されない。
# pytest の既定名に含まれるので、ファイルがあるときの exit 5 は成功にしない。
underscore="$TEST_ROOT/underscore"
mkdir -p "$underscore"
bash "$APPLY" "$underscore" sample-pkg owner sample-pkg --lang=python --conduct-contact=conduct@example.org >/dev/null
target="$underscore"
workflow="$underscore/.github/workflows/lint.yml"
cat >"$target/widget_test.py" <<'PY'
def test_widget() -> None:
    assert True
PY
assert_step_rejects_hidden_targets \
  "Run tests" \
  "collected 0 items" \
  "treating pytest exit code 5 as success"

# .py に型エラーがあっても exclude = ["."] だと mypy は空ツリーと同じ
# exit 2 とメッセージを出す。ファイルが残っているので成功にしない。
target="$TEST_ROOT/exclude"
mkdir -p "$target"
bash "$APPLY" "$target" sample-pkg owner sample-pkg --lang=python --conduct-contact=conduct@example.org >/dev/null
workflow="$target/.github/workflows/lint.yml"
cat >"$target/bad_types.py" <<'PY'
def broken(x: int) -> str:
    return x
PY
awk '
  /^\[tool\.mypy\]/ && !inserted {
    print
    print "exclude = [\".\"]"
    inserted = 1
    next
  }
  { print }
' "$target/pyproject.toml" >"$TEST_ROOT/pyproject.exclude.toml"
mv "$TEST_ROOT/pyproject.exclude.toml" "$target/pyproject.toml"
grep -Fq 'exclude = ["."]' "$target/pyproject.toml" \
  || fail "failed to set mypy exclude"
assert_step_rejects_hidden_targets \
  "Run mypy" \
  "There are no .py[i] files in directory '.'" \
  "No Python files found; skipping mypy"

echo "All python workflow-after-apply tests passed."
