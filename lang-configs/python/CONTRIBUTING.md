# Contributing to {{PROJECT_NAME}}

Thank you for your interest in contributing to {{PROJECT_NAME}}! This document provides guidelines and
instructions for contributing to the project.

## 🙏 Welcome!

{{PROJECT_NAME}} is a Python application. We welcome contributions from everyone, whether you're
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

- Python 3.9 or higher
- pip or uv
- Git

### Getting Started

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/{{REPO_OWNER}}/{{REPO_NAME}}.git
   cd {{REPO_NAME}}
   ```

2. **Create virtual environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

4. **Run tests to verify setup**
   ```bash
   pytest
   ```

## 📝 Coding Standards

### Python Style

- Follow [PEP 8](https://pep8.org/) style guide
- Use type hints for function signatures
- Maximum line length: 100 characters
- Use `ruff` for linting and formatting
- Use `mypy` for type checking

### Code Formatting

```bash
# Format code with ruff
ruff format .

# Check linting
ruff check .

# Type checking
mypy .
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
feat: add user authentication endpoint

Implements JWT-based authentication for API.
Includes middleware for token validation.
```

## ✅ Testing Requirements

See [docs/TESTING.md](docs/TESTING.md) for detailed testing guidelines.

### Test Types

1. **Unit Tests**: For individual functions and methods
2. **Integration Tests**: For component interactions
3. **Functional Tests**: For end-to-end workflows

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov

# Run specific test file
pytest tests/test_user.py

# Run with verbose output
pytest -v

# Run specific test
pytest tests/test_user.py::test_create_user
```

### Test Coverage Expectations

- New features: 80%+ coverage required
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
   pytest
   ruff check .
   ruff format .
   mypy .
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
- ✅ Style: Does it follow PEP 8?

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
