#!/bin/bash
# 生成される secret scan workflow を検査する。
# gitleaks の GitHub Action は organization の repo ではライセンスキーが必要で、
# 無いと失敗する。CLI を版とチェックサムで固定して直接実行する方式であることを確かめる。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-security.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$TEST_ROOT/project"
mkdir -p "$target"
bash "$SCRIPT_DIR/apply-templates.sh" "$target" p owner repo --conduct-contact=conduct@example.org >/dev/null
wf="$target/.github/workflows/security.yml"
[ -f "$wf" ] || fail "security.yml must be generated"

! grep -Fq "gitleaks/gitleaks-action" "$wf" || fail "must not use gitleaks-action (requires a license key for organization repos)"
! grep -Fq "GITLEAKS_LICENSE" "$wf" || fail "must not require GITLEAKS_LICENSE"
grep -Eq 'GITLEAKS_VERSION: "?[0-9]+\.[0-9]+\.[0-9]+"?' "$wf" || fail "gitleaks version must be pinned"
grep -Eq 'GITLEAKS_SHA256: "?[0-9a-f]{64}"?' "$wf" || fail "gitleaks archive checksum must be pinned"
grep -Fq "sha256sum -c" "$wf" || fail "downloaded archive must be verified with sha256sum -c"
grep -Eq 'gitleaks"? git .*--redact' "$wf" || fail "must scan git history with redacted output"
grep -Fq "fetch-depth: 0" "$wf" || fail "history scan needs a full clone"

# 固定したチェックサムが、固定した版の公式 linux_x64 アーカイブのものか（ネットワークがある場合のみ）
version="$(sed -nE 's/.*GITLEAKS_VERSION: "?([0-9.]+)"?.*/\1/p' "$wf" | head -1)"
sum="$(sed -nE 's/.*GITLEAKS_SHA256: "?([0-9a-f]{64})"?.*/\1/p' "$wf" | head -1)"
if official="$(curl -fsSL --max-time 20 "https://github.com/gitleaks/gitleaks/releases/download/v${version}/gitleaks_${version}_checksums.txt" 2>/dev/null)"; then
  echo "$official" | grep -Fq "$sum  gitleaks_${version}_linux_x64.tar.gz" \
    || fail "pinned checksum does not match the official checksums for v${version}"
else
  echo "SKIP: official checksum lookup (offline)"
fi

# 生成されるすべての workflow と dependabot.yml が YAML として読める（GitHub が読み込めない workflow は動かない）
parse_yaml() {
  if python3 -c 'import yaml' 2>/dev/null; then
    python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$1"
  elif command -v ruby >/dev/null 2>&1; then
    ruby -ryaml -e 'YAML.safe_load(File.read(ARGV[0]), aliases: true)' "$1"
  else
    fail "no YAML parser (python3 yaml or ruby) is available"
  fi
}
for lang in "" node go python swift shell; do
  dir="$TEST_ROOT/yaml-${lang:-none}"
  mkdir -p "$dir"
  bash "$SCRIPT_DIR/apply-templates.sh" "$dir" p owner repo --conduct-contact=conduct@example.org ${lang:+--lang=$lang} >/dev/null
  while IFS= read -r f; do
    parse_yaml "$f" >/dev/null 2>&1 || fail "${lang:-none}: ${f#"$dir"/} is not valid YAML"
  done < <(find "$dir/.github" -type f \( -name '*.yml' -o -name '*.yaml' \))
done

echo "All security workflow tests passed."
