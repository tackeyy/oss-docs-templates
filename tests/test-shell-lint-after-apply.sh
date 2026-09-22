#!/bin/bash
# --lang=shell で空ディレクトリに適用し、.shellcheckrc を読んだ shellcheck を実行する。
#
# 生成物には .sh が無い。ファイルを渡さない shellcheck は設定を読まずに終わるので、
# .shellcheckrc と同じディレクトリに一時的な .sh を置いて、設定が効くことを確かめる。
# - 波括弧付きの参照は通る（shell=bash が効き、rc が構文エラーなく読まれる）
# - 波括弧なしは SC2250 になる（enable=all が効いている）
# 生成物に .sh がある場合は、そのファイルも shellcheck が通ることを検査する。
#
# ツールが無いときは、検証を実行したことにしない。
# REQUIRE_TOOLS=1 のときは失敗する（CI はこれで、未導入を成功にしない）。
# 未設定のときは SKIP: を出して終了コード 0 で戻る。
# その場合、このファイルは「検証に成功した」とは書かない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-shell-lint.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$TEST_ROOT/project"
mkdir -p "$target"
bash "$APPLY" "$target" p owner repo --lang=shell --conduct-contact=conduct@example.org >/dev/null
[ -f "$target/.shellcheckrc" ] || fail "apply must install .shellcheckrc"

missing=()
command -v shellcheck >/dev/null 2>&1 || missing+=(shellcheck)
if [ "${#missing[@]}" -gt 0 ]; then
  if [ "${REQUIRE_TOOLS:-}" = "1" ]; then
    fail "REQUIRE_TOOLS=1 but missing: ${missing[*]}"
  fi
  echo "SKIP: ${missing[*]} is not installed; shellcheck was not run"
  exit 0
fi

sh_files=()
while IFS= read -r sh_file; do
  sh_files+=("$sh_file")
done < <(find "$target" -type f -name '*.sh' | sort)
if [ "${#sh_files[@]}" -gt 0 ]; then
  if ! sh_out="$(shellcheck "${sh_files[@]}" 2>&1)"; then
    printf '%s\n' "$sh_out" >&2
    fail "shellcheck must exit 0 on generated .sh files"
  fi
fi

# 一時ファイルは生成物ではない。rc を読ませるため、生成物のディレクトリに置く。
printf 'echo "%s{HOME}"\n' '$' >"$target/oss-docs-probe-clean.sh"
if ! clean_out="$(shellcheck "$target/oss-docs-probe-clean.sh" 2>&1)"; then
  printf '%s\n' "$clean_out" >&2
  fail ".shellcheckrc must parse, and shell=bash must apply to a script with no shebang (output: $clean_out)"
fi

printf 'echo "%sHOME"\n' '$' >"$target/oss-docs-probe-unbraced.sh"
if unbraced_out="$(shellcheck "$target/oss-docs-probe-unbraced.sh" 2>&1)"; then
  fail "enable=all must report SC2250 for an unbraced expansion (output: $unbraced_out)"
fi
printf '%s\n' "$unbraced_out" | grep -Fq "SC2250" \
  || fail "enable=all must report SC2250 (output: $unbraced_out)"

echo "All shell lint-after-apply tests passed."
