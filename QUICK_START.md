# クイックスタート

## 🚀 3ステップで始める

### ステップ1: プロジェクトに移動

```bash
cd ~/dev/your-project
```

### ステップ2: テンプレートを適用

```bash
bash ~/dev/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name
```

### ステップ3: カスタマイズ

```bash
# 必要に応じて編集
vim CONTRIBUTING.md
vim docs/TESTING.md
```

## 📚 詳細ドキュメント

| ファイル | 内容 |
|---------|------|
| [README.md](README.md) | テンプレートの全体像と使い方 |
| [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) | 具体的な使用例とトラブルシューティング |
| [CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md) | ベストプラクティスのリファレンス |

## 💡 よくある使い方

### 新規プロジェクト

```bash
mkdir ~/dev/awesome-cli && cd ~/dev/awesome-cli
npm init -y
bash ~/dev/templates/oss-docs/apply-templates.sh . awesome-cli tackeyy awesome-cli
```

### 既存プロジェクト

```bash
cd ~/dev/existing-project
git checkout -b add-contributing-docs
bash ~/dev/templates/oss-docs/apply-templates.sh . existing-project your-username existing-project
git diff  # 変更内容を確認
```

### Python プロジェクト

```bash
bash ~/dev/templates/oss-docs/apply-templates.sh . my-python-app tackeyy my-python-app --lang=python
```

`--lang=node|go|swift|shell|python` を指定すると、言語別の `CONTRIBUTING.md`、`docs/TESTING.md`、lint 設定、GitHub Actions workflow が適用されます。

## ⚙️ カスタマイズ必須箇所

最低限、以下を確認・変更してください:

1. **CONTRIBUTING.md**
   - [ ] プロジェクト固有のセットアップ手順
   - [ ] 使用している技術スタック
   - [ ] テスト・ビルドコマンド

2. **docs/TESTING.md**
   - [ ] テストフレームワーク名
   - [ ] テストディレクトリ構造
   - [ ] テスト実行コマンド

3. **CODE_OF_CONDUCT.md**
   - [ ] 連絡先（現在: X [@3chhe](https://x.com/3chhe)）

## 🆘 ヘルプ

問題が発生したら:
1. [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) のトラブルシューティングを確認
2. [README.md](README.md) の詳細な説明を参照
3. README.md と Usage 表示を確認
