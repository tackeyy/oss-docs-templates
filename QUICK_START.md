# クイックスタート

## 🚀 3ステップで始める

### ステップ1: プロジェクトに移動

```bash
cd ~/dev/your-project
```

### ステップ2: テンプレートを適用

`--lang` は付けていません。言語別の `CONTRIBUTING.md` と `docs/TESTING.md` はこのコマンドでは作られません。

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name \
  --conduct-contact=conduct@example.com
```

### ステップ3: カスタマイズ

ステップ2で作られるのはベーステンプレートです。編集するのはそのファイルです。

```bash
vim CODE_OF_CONDUCT.md
vim SECURITY.md
```

`CONTRIBUTING.md` と `docs/TESTING.md` を編集するのは、`--lang` を付けて適用したときだけです。

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
bash ~/templates/oss-docs/apply-templates.sh . awesome-cli tackeyy awesome-cli --conduct-contact=conduct@example.com
```

### 既存プロジェクト

```bash
cd ~/dev/existing-project
git checkout -b add-contributing-docs
bash ~/templates/oss-docs/apply-templates.sh . existing-project your-username existing-project --conduct-contact=conduct@example.com
git diff  # 変更内容を確認
```

### Python プロジェクト

```bash
bash ~/templates/oss-docs/apply-templates.sh . my-python-app tackeyy my-python-app --lang=python --conduct-contact=conduct@example.com
```

`--lang=node|go|swift|shell|python` を指定すると、言語別の `CONTRIBUTING.md`、`docs/TESTING.md`、lint 設定、GitHub Actions workflow が適用されます。

`--update-actions` が差し替え・退避するのは `--lang=node` のときだけです。既存の `ci.yml` は `ci.yml.pre-cost-optimization` に退避してからテンプレートで置き換え、既存の `lint.yml` と `release.yml` は `*.disabled` にリネームします。go / swift / shell / python の既存 workflow は `--update-actions` では置き換わらず、`--force` が無いと skip されます。

## ⚙️ カスタマイズ必須箇所

最低限、以下を確認・変更してください:

1. **CONTRIBUTING.md**（`--lang` を付けたときだけ作られる）
   - [ ] プロジェクト固有のセットアップ手順
   - [ ] 使用している技術スタック
   - [ ] テスト・ビルドコマンド

2. **docs/TESTING.md**（`--lang` を付けたときだけ作られる）
   - [ ] テストフレームワーク名
   - [ ] テストディレクトリ構造
   - [ ] テスト実行コマンド

3. **CODE_OF_CONDUCT.md**
   - [ ] 報告先（`--conduct-contact` で指定した値）

4. **SECURITY.md**
   - [ ] repo の Settings > Security で Private vulnerability reporting を有効にする

5. **.github のラベル**
   - [ ] Issue テンプレートが使うラベルは GitHub の既定（`bug` / `enhancement` / `question`）だけ。これ以外を書くときは、先にそのラベルを repo に作る

## 🆘 ヘルプ

問題が発生したら:
1. [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) のトラブルシューティングを確認
2. [README.md](README.md) の詳細な説明を参照
3. README.md と Usage 表示を確認
