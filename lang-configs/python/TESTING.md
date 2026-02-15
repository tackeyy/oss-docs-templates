# Testing Guide for {{PROJECT_NAME}}

This document describes the testing strategy, guidelines, and best practices for {{PROJECT_NAME}}.

## 🎯 Testing Philosophy

- **Test behavior, not implementation**
- **Write tests first** when fixing bugs
- **Keep tests simple and readable**
- **Use fixtures** for test data
- **Mock external dependencies**

## 📚 Testing Framework

{{PROJECT_NAME}} uses pytest along with:
- `pytest` - Testing framework
- `pytest-cov` - Coverage reporting
- `pytest-mock` - Mocking utilities
- `pytest-asyncio` - Async test support (if needed)

## 🏗️ Test Structure

### Directory Layout

```
{{REPO_NAME}}/
├── src/
│   └── {{REPO_NAME}}/
│       ├── __init__.py
│       ├── user.py
│       └── handler.py
└── tests/
    ├── __init__.py
    ├── conftest.py
    ├── test_user.py
    └── test_handler.py
```

### Naming Convention

- Test files: `test_*.py`
- Test functions: `def test_function_name():`
- Test classes: `class TestClassName:`

## ✍️ Writing Tests

### Basic Test Example

```python
def test_user_creation():
    # Arrange
    name = "John Doe"
    email = "john@example.com"

    # Act
    user = User(name=name, email=email)

    # Assert
    assert user.name == name
    assert user.email == email
```

### Parametrized Test Example

```python
import pytest

@pytest.mark.parametrize("email,expected", [
    ("user@example.com", True),
    ("invalid-email", False),
    ("", False),
    ("user@", False),
])
def test_email_validation(email, expected):
    result = validate_email(email)
    assert result == expected
```

### Fixture Example

```python
import pytest

@pytest.fixture
def sample_user():
    return User(name="Test User", email="test@example.com")

def test_user_display_name(sample_user):
    assert sample_user.display_name == "Test User"
```

### Class-based Tests

```python
class TestUserAPI:
    @pytest.fixture(autouse=True)
    def setup(self):
        self.client = TestClient()
        yield
        self.client.close()

    def test_get_user(self):
        response = self.client.get("/users/1")
        assert response.status_code == 200

    def test_create_user(self):
        data = {"name": "New User", "email": "new@example.com"}
        response = self.client.post("/users", json=data)
        assert response.status_code == 201
```

## 🎭 Mocking

### Using pytest-mock

```python
def test_fetch_user_data(mocker):
    # Mock external API call
    mock_response = mocker.Mock()
    mock_response.json.return_value = {"id": 1, "name": "Test"}
    mocker.patch("requests.get", return_value=mock_response)

    result = fetch_user_data(user_id=1)
    assert result["name"] == "Test"
```

### Mocking with unittest.mock

```python
from unittest.mock import Mock, patch

def test_send_email():
    with patch("smtplib.SMTP") as mock_smtp:
        send_email("test@example.com", "Hello")
        mock_smtp.assert_called_once()
```

## 🏃 Running Tests

### Basic Commands

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_user.py

# Run specific test
pytest tests/test_user.py::test_user_creation

# Run tests matching pattern
pytest -k "test_user"

# Run with coverage
pytest --cov=src

# Generate HTML coverage report
pytest --cov=src --cov-report=html

# Run in parallel (with pytest-xdist)
pytest -n auto
```

### Watch Mode

```bash
# Install pytest-watch
pip install pytest-watch

# Run tests on file change
ptw
```

## 📊 Test Coverage

### Coverage Requirements

- **Overall**: 70%+ coverage required
- **New features**: 80%+ coverage required
- **Critical paths**: 90%+ coverage required
- **Bug fixes**: Must include regression test

### Check Coverage

```bash
# Generate coverage report
pytest --cov=src --cov-report=term-missing

# View HTML report
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

### Coverage Configuration

Create `.coveragerc`:
```ini
[run]
source = src
omit =
    */tests/*
    */test_*.py
    */__pycache__/*

[report]
precision = 2
show_missing = True
skip_covered = False
```

## ✅ Test Checklist

Before submitting a PR, ensure:

- [ ] All tests pass: `pytest`
- [ ] Coverage is adequate: `pytest --cov`
- [ ] Linting passes: `ruff check .`
- [ ] Type checking passes: `mypy .`
- [ ] Code is formatted: `ruff format .`
- [ ] Tests use fixtures where appropriate
- [ ] External dependencies are mocked
- [ ] Edge cases are tested
- [ ] Error cases are tested

## 🎯 Best Practices

1. **Use descriptive test names** - test names should explain what's being tested
2. **One assertion per test** (when reasonable)
3. **Use fixtures** for shared test data
4. **Test error handling** - don't just test happy paths
5. **Avoid test interdependencies** - tests should run independently
6. **Keep tests fast** - mock slow operations
7. **Use parametrize** for similar test cases
8. **Write docstrings** for complex tests

## 🔧 Integration Tests

### Marking Integration Tests

```python
import pytest

@pytest.mark.integration
def test_database_integration():
    # Integration test code
    pass
```

### Running Integration Tests

```bash
# Run only integration tests
pytest -m integration

# Skip integration tests
pytest -m "not integration"
```

## 🚀 Advanced Testing

### Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_function():
    result = await async_operation()
    assert result is not None
```

### Property-based Testing (with Hypothesis)

```python
from hypothesis import given
import hypothesis.strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    assert a + b == b + a
```

## 📚 Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest Best Practices](https://docs.pytest.org/en/stable/goodpractices.html)
- [Python Testing Style Guide](https://docs.python-guide.org/writing/tests/)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)

---

**Questions?** Open an issue or refer to [CONTRIBUTING.md](../CONTRIBUTING.md)
