#!/bin/bash
# README・QUICK_START・USAGE_EXAMPLES の記述が実装と食い違っていないかを検査する。
# 文書だけを読んだ利用者が、存在しない機能を前提にしたり、使えるオプションを知らないままになったりしないようにする。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-docs.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
DOCS=("$SCRIPT_DIR/README.md" "$SCRIPT_DIR/QUICK_START.md" "$SCRIPT_DIR/USAGE_EXAMPLES.md")

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# 1) 使い方表示にあるオプションは、すべて README に載っている
usage="$(bash "$SCRIPT_DIR/apply-templates.sh" 2>&1 || true)"
while IFS= read -r opt; do
  # オプション表（| `--opt...` | 説明 |）の行に載っていること
  grep -Eq -- "^\| \`${opt}[=\`]" "$SCRIPT_DIR/README.md" || grep -Eq -- "^\| \`[^|]*\` / \`${opt}[=\`]" "$SCRIPT_DIR/README.md" \
    || fail "README.md options table does not document $opt"
done < <(echo "$usage" | grep -oE -- '--[a-z][a-z-]+' | sort -u)

# 2) 実装に無い対応範囲や、廃止した仕組みを案内していない
for pattern in 'yarn' 'pnpm' 'eslint' 'Jest' 'NPM_TOKEN' 'gitleaks-action' 'instead of email' 'Security contact handle and email' '連絡先（現在: X'; do
  for doc in "${DOCS[@]}"; do
    ! grep -Fq -- "$pattern" "$doc" || fail "$(basename "$doc") mentions '$pattern', which the templates no longer provide"
  done
done

# 3) 文書に載っている実行例は、そのまま実行して成功する（~/... のパスはテスト用ディレクトリに置き換える）
n=0
while IFS= read -r cmd; do
  n=$((n + 1))
  target="$TEST_ROOT/example-$n"
  mkdir -p "$target"
  args="$(echo "$cmd" | sed -E 's#^bash [^ ]*apply-templates\.sh ##')"
  # 先頭の位置引数（対象ディレクトリ）をテスト用ディレクトリに置き換える
  args="$(echo "$args" | sed -E "s#^[^ ]+#$target#")"
  # shellcheck disable=SC2086
  eval "bash \"$SCRIPT_DIR/apply-templates.sh\" $args" >/dev/null 2>&1 || fail "documented example fails: $cmd"
done < <(python3 - "${DOCS[@]}" <<'PY'
import re,sys
for path in sys.argv[1:]:
    lines=open(path).read().split("\n"); i=0
    while i<len(lines):
        l=lines[i].strip()
        if re.match(r'^bash \S*apply-templates\.sh', l) and "..." not in l and '"$' not in l:
            parts=[l.rstrip("\\").strip()]
            while lines[i].rstrip().endswith("\\"):
                i+=1; parts.append(lines[i].strip().rstrip("\\").strip())
            cmd=" ".join(p for p in parts if p)
            if len(cmd.split())>=5: print(cmd)
        i+=1
PY
)
[ "$n" -gt 0 ] || fail "no documented example was found"

echo "All documentation consistency tests passed ($n examples)."
