#!/bin/bash
# --lang=node で空ディレクトリに適用した直後、その repo の lint が通ることを検査する。
#
# npm run lint は lint:md と lint:sh だけ（package.json の現状）。
# lint:yaml は含めない。ci.yml は yamllint を pip で入れてから別ステップで呼ぶ。
# yamllint は devDependency ではないので、lint に含めると yamllint の無い環境で
# 適用直後の npm run lint が失敗する。
#
# npm が無いときは npm ci / npm run lint / markdownlint を実行せず SKIP と出す。
# yamllint が無いときは YAML lint を実行せず SKIP と出す。
# どちらも、ツールが無いのに成功したことにはしない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-node-lint.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# GNU xargs は入力が空でもコマンドを起動する。-r が無いと shellcheck が引数なしで失敗する。
# BSD xargs（macOS）は空入力では起動しないが、-r は互換オプションとして受け付ける（何もしない）。
printf '' | xargs -0 -r true || fail "xargs -0 -r is not accepted on this system"

target="$TEST_ROOT/project"
mkdir -p "$target"
out="$(bash "$APPLY" "$target" p owner repo --lang=node --conduct-contact=conduct@example.org)"

# 適用直後に成功するコマンドだけを番号付きの手順にする。
echo "$out" | grep -Fq "npm ci" || fail "next steps must include npm ci"
echo "$out" | grep -Fq "Run lints: npm run lint" || fail "next steps must include npm run lint"
echo "$out" | grep -Fq "Before npm run typecheck, npm test, or npm run build:" \
  || fail "typecheck, test, and build must be listed with the prerequisite that those scripts are added first"
if echo "$out" | grep -Eq '^[0-9]+\..*npm run typecheck'; then
  fail "next steps must not list typecheck as a command to run immediately"
fi
if echo "$out" | grep -Eq '^[0-9]+\..*npm test'; then
  fail "next steps must not list npm test as a command to run immediately"
fi
if echo "$out" | grep -Eq '^[0-9]+\..*npm run build'; then
  fail "next steps must not list build as a command to run immediately"
fi

# macOS では -r が無くても npm run lint が成功する。GNU 向けの修正を戻すとここで落ちる。
grep -Fq 'xargs -0 -r shellcheck' "$target/package.json" \
  || fail "lint:sh must pass -r so GNU xargs does not run shellcheck when no .sh files exist"

lint_markdown() {
  local dir="$1" label="$2" lint_out md_n
  if ! lint_out="$(cd "$dir" && npm run lint 2>&1)"; then
    printf '%s\n' "$lint_out" >&2
    fail "$label: npm run lint must exit 0"
  fi
  md_n="$(find "$dir" -name '*.md' -not -path '*/node_modules/*' | wc -l | tr -d ' ')"
  echo "$lint_out" | grep -Fq "Linting: ${md_n} file(s)" \
    || fail "$label: markdownlint must lint all ${md_n} Markdown files (output: $lint_out)"
  echo "$lint_out" | grep -Fq "Summary: 0 error(s)" \
    || fail "$label: markdownlint must report 0 errors (output: $lint_out)"
}

if ! command -v npm >/dev/null 2>&1; then
  echo "SKIP: npm is not installed; npm ci, npm run lint, and markdownlint were not run"
else
  if ! ci_out="$(cd "$target" && npm ci 2>&1)"; then
    printf '%s\n' "$ci_out" >&2
    fail "npm ci must exit 0"
  fi
  lint_markdown "$target" "en"
fi

if ! command -v yamllint >/dev/null 2>&1; then
  echo "SKIP: yamllint is not installed; YAML lint was not run"
else
  if ! yaml_out="$(cd "$target" && yamllint . 2>&1)"; then
    printf '%s\n' "$yaml_out" >&2
    fail "yamllint must exit 0 on the generated tree"
  fi
fi

echo "All node lint-after-apply tests passed."
