# Análisis de Diseño: Testing Infrastructure

---

## Testing Utilities

```swift
// Mock Factory
enum MockFactory {
    static func makeUser() -> User
    static func makeToken() -> TokenInfo
}

// Custom Assertions
func XCTAssertSuccess<T>(_ result: Result<T, Error>)
func XCTAssertFailure<T>(_ result: Result<T, Error>)
```

---

## CI/CD Pipeline

```yaml
name: Tests
on: [pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.0.app
      - name: Run tests
        run: xcodebuild test -scheme apple-app -destination 'platform=iOS Simulator,name=iPhone 15'
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```
