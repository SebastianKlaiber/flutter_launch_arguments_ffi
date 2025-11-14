# Maestro Tests for Launch Arguments FFI

## Prerequisites

Install Maestro:
```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

## Build the app

```bash
cd example
flutter build ios --simulator
```

## Run the test

```bash
maestro test .maestro/launch_arguments_test.yaml
```

## What the test does

1. Launches the app with arguments: `--foo=hello --enabled --test=123`
2. Verifies the app title is visible
3. Checks that the argument count is displayed
4. Verifies the parsed `foo` value is "hello"
5. Verifies the `enabled` flag is parsed as "true"
6. Scrolls to see all raw arguments
7. Confirms all three arguments are visible in the list

## Expected Results

The test should pass, showing that:
- Launch arguments are successfully passed via `xcrun simctl launch`
- The native iOS code correctly retrieves them via NSProcessInfo
- The Dart FFI layer properly parses and displays them
