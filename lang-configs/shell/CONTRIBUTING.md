# Contributing to {{PROJECT_NAME}}

Thank you for your interest in contributing to {{PROJECT_NAME}}! This document provides guidelines and
instructions for contributing to the project.

## 🙏 Welcome!

{{PROJECT_NAME}} is a shell script project. We welcome contributions from everyone, whether you're
fixing a bug, adding a feature, or improving documentation.

## 📖 Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Submitting Changes](#submitting-changes)
- [Code Review Process](#code-review-process)
- [Community Guidelines](#community-guidelines)
- [Getting Help](#getting-help)

## 🎯 Ways to Contribute

- **Bug Reports**: Found a bug? Open an issue with reproduction steps
- **Feature Requests**: Have an idea? Share it in a feature request issue
- **Code Contributions**: Submit pull requests for bug fixes or features
- **Documentation**: Improve README, add examples, or fix typos
- **Testing**: Add test cases or improve test coverage
- **Code Review**: Review open pull requests

## 🛠️ Development Setup

### Prerequisites

- Bash 4.0+ or compatible shell (zsh, dash)
- Git
- ShellCheck (for linting)

### Getting Started

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/{{REPO_OWNER}}/{{REPO_NAME}}.git
   cd {{REPO_NAME}}
   ```

2. **Install ShellCheck**
   ```bash
   # macOS
   brew install shellcheck

   # Ubuntu/Debian
   apt-get install shellcheck

   # Other platforms: https://github.com/koalaman/shellcheck#installing
   ```

3. **Make scripts executable**
   ```bash
   chmod +x *.sh
   ```

## 📝 Coding Standards

### Shell Script Style

- Use `#!/bin/bash` shebang (or appropriate shell)
- Use `set -euo pipefail` for error handling
- Quote variables: `"$var"` not `$var`
- Use `shellcheck` for static analysis
- Use descriptive function and variable names
- Add comments for complex logic

### Best Practices

```bash
#!/bin/bash
set -euo pipefail

# Good: Quoted variable
echo "Hello, $USER"

# Bad: Unquoted variable
# echo Hello, $USER

# Good: Check if file exists
if [[ -f "$file" ]]; then
    echo "File exists"
fi

# Good: Use functions
function process_file() {
    local file="$1"
    # Processing logic
}
```

### Code Formatting

```bash
# Run shellcheck
shellcheck *.sh

# Run shfmt (if installed)
shfmt -w -i 2 *.sh
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Adding or updating tests
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

Example:
```
feat: add support for multiple input files

Allows processing multiple files in a single run.
Includes parallel processing option with -p flag.
```

## ✅ Testing Requirements

See [docs/TESTING.md](docs/TESTING.md) for detailed testing guidelines.

### Test Types

1. **Unit Tests**: For individual functions (using bats)
2. **Integration Tests**: For full script execution
3. **Edge Case Tests**: For error handling and boundary conditions

### Running Tests

```bash
# Run tests with bats
bats tests/

# Run specific test file
bats tests/test_main.bats

# Run shellcheck
shellcheck *.sh
```

### Test Coverage Expectations

- New features: Add tests for main functionality
- Bug fixes: Add test that reproduces the bug
- All tests must pass before merging

## 📤 Submitting Changes

### Before Submitting

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes**
   - Write clean, readable code
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests and linters**
   ```bash
   shellcheck *.sh
   bats tests/
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push to your fork**
   ```bash
   git push origin feat/your-feature-name
   ```

6. **Open a Pull Request**
   - Use the PR template
   - Link related issues
   - Describe your changes clearly

## 🔍 Code Review Process

### For Contributors

- Be responsive to feedback
- Keep discussions constructive
- Update your PR based on review comments
- Be patient - reviews may take a few days

### Review Criteria

- ✅ Functionality: Does it work as intended?
- ✅ Tests: Are there adequate tests?
- ✅ Code Quality: Is it readable and maintainable?
- ✅ Documentation: Are changes documented?
- ✅ ShellCheck: Does it pass ShellCheck?

## 🤝 Community Guidelines

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

### Recognition

Contributors are recognized in:
- GitHub Contributors page
- Release notes for significant contributions

## 💬 Getting Help

- **Questions**: Open a [Question issue](.github/ISSUE_TEMPLATE/question.yml)
- **Discussion**: Use GitHub Discussions (if enabled)
- **Bugs**: Open a [Bug Report](.github/ISSUE_TEMPLATE/bug_report.yml)

---

Thank you for contributing to {{PROJECT_NAME}}! 🎉
