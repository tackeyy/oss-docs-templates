# OSS Documentation Templates

Reusable OSS documentation templates with one-command setup. Based on industry best practices (GitHub CLI, AWS CLI, Contributor Covenant).

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/tackeyy/oss-docs-templates.git ~/templates/oss-docs

# Apply to your project
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name
```

See [QUICK_START.md](QUICK_START.md) for detailed instructions.

## 📦 What's Included

| File | Purpose | Customization |
|------|---------|---------------|
| **CONTRIBUTING.md** | Contribution guidelines | ⭐⭐⭐ High |
| **CODE_OF_CONDUCT.md** | Community standards (Contributor Covenant v2.1) | ⭐ Low |
| **docs/TESTING.md** | Testing strategy and guide | ⭐⭐⭐ High |
| **.github/ISSUE_TEMPLATE/** | Bug report, feature request, question templates | ⭐⭐ Medium |
| **.github/PULL_REQUEST_TEMPLATE.md** | PR checklist and guidelines | ⭐⭐ Medium |

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in 3 steps
- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** - Project-specific examples and troubleshooting
- **[CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md)** - Research-based best practices reference

## ✨ Features

- **One-command setup** - Apply all templates with a single script
- **Automatic customization** - Project name and repository auto-replacement
- **Industry standards** - Based on GitHub CLI, AWS CLI, Contributor Covenant
- **Multi-language support** - Default for Node.js/TypeScript, easy to adapt for Python, Go, Rust
- **Privacy-conscious** - Contact via X (Twitter) [@3chhe](https://x.com/3chhe) instead of email

## 🎯 Use Cases

### New CLI Tool Project

```bash
mkdir ~/dev/awesome-cli && cd ~/dev/awesome-cli
npm init -y

bash ~/templates/oss-docs/apply-templates.sh \
  . awesome-cli your-username awesome-cli

# Almost ready to use for Node.js/TypeScript projects
git add . && git commit -m "docs: add OSS contribution guidelines"
```

### Existing Python Project

```bash
cd ~/dev/python-project

bash ~/templates/oss-docs/apply-templates.sh \
  . python-project your-username python-project

# Customize for Python
sed -i '' 's/npm install/pip install -r requirements.txt/g' CONTRIBUTING.md
sed -i '' 's/npm test/pytest/g' CONTRIBUTING.md
sed -i '' 's/Vitest/pytest/g' docs/TESTING.md

git add . && git commit -m "docs: add OSS contribution guidelines"
```

See [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) for more examples.

## 🛠️ How It Works

The `apply-templates.sh` script:

1. Copies template files to your project
2. Automatically replaces `zoomy` with your project name
3. Replaces `tackeyy/zoomy` with your repository path
4. Customizes GitHub issue/PR templates
5. Provides next steps for further customization

## 📋 Customization Checklist

After applying templates, review and customize:

- [ ] **CONTRIBUTING.md**
  - [ ] Development setup instructions
  - [ ] Technology stack (Node.js → Python/Go/etc.)
  - [ ] Test and build commands
- [ ] **docs/TESTING.md**
  - [ ] Test framework (Vitest → pytest/Go test/etc.)
  - [ ] Test directory structure
  - [ ] Test execution commands
- [ ] **CODE_OF_CONDUCT.md**
  - [ ] Contact information (currently: X [@3chhe](https://x.com/3chhe))
- [ ] **.github templates**
  - [ ] Issue labels
  - [ ] Version check commands

## 🌍 Multi-Language Support

### Node.js/TypeScript (Default)
- ✅ Ready to use as-is
- Test framework: Vitest/Jest
- Package manager: npm/yarn

### Python
Replace after applying:
- `npm install` → `pip install -r requirements.txt`
- `npm test` → `pytest`
- `Vitest` → `pytest`

### Go
Replace after applying:
- `npm install` → `go mod download`
- `npm test` → `go test ./...`
- `Vitest` → `Go testing package`

### Rust
Replace after applying:
- `npm install` → `cargo build`
- `npm test` → `cargo test`
- `Vitest` → `Rust built-in test framework`

See [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) for detailed customization commands.

## 📖 Best Practices Reference

This template is based on extensive research of OSS best practices:

- [GitHub CLI Contributing Guide](https://github.com/cli/cli/blob/trunk/.github/CONTRIBUTING.md)
- [AWS CLI Contributing](https://github.com/aws/aws-cli/blob/develop/CONTRIBUTING.md)
- [Contributor Covenant v2.1](https://www.contributor-covenant.org/)
- [How to Build a CONTRIBUTING.md](https://contributing.md/)
- [GitHub PR Template Best Practices](https://graphite.com/guides/comprehensive-checklist-github-pr-template)

See [CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md) for comprehensive research and recommendations.

## 🤝 Contributing

Improvements and suggestions are welcome! Feel free to:

- Open an issue for bugs or feature requests
- Submit a pull request with improvements
- Share your experience using these templates

## 📄 License

These templates are provided as-is for public use. Derived from the [zoomy](https://github.com/tackeyy/zoomy) project.

## 🔗 Links

- **Repository**: https://github.com/tackeyy/oss-docs-templates
- **Source Project**: [zoomy](https://github.com/tackeyy/zoomy) - Zoom CLI tool
- **Contact**: X (Twitter) [@3chhe](https://x.com/3chhe)

---

**Made with ❤️ for the open source community**
