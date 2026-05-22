## 0.2.0

* **Breaking Change**: Add Flutter Swift Package Manager support for iOS
  * Move the iOS Swift package to Flutter's expected `ios/flutter_launch_arguments_ffi/Package.swift` location
  * Split Swift plugin registration and Objective-C FFI code into separate SwiftPM targets
  * Update CocoaPods fallback paths to use the same shared SwiftPM sources
  * Update Android CMake and ffigen to use the moved public header
  * Raise minimum Flutter SDK to `>=3.41.0` for `FlutterFramework` SwiftPM dependency support

## 0.1.2

* **Improvement**: Fix pub.dev scoring issues
  * Shorten package description to meet 180 character limit
  * Format Dart files to pass static analysis checks
  * Increase pub.dev score from 140/160 to 150/160

## 0.1.1

* **Bug Fix**: Add graceful handling for desktop platforms and tests
  * Fix `UnsupportedError` crash when used on macOS, Windows, or Linux
  * Fix widget tests that use components calling FlutterLaunchArguments methods
  * Convert FFI library initialization from eager to lazy loading
  * Add platform guards to return `null` on unsupported platforms
  * Add comprehensive platform guard tests

## 0.1.0

* **Initial Release**: FFI-based Flutter plugin to access command-line launch arguments
  * Support for iOS and Android via FFI (Foreign Function Interface)
  * Web platform support with graceful degradation
  * Parse multiple argument formats: `--key=value`, `--key value`, `-key value`
  * Boolean flag support with `getBool()` method
  * String value retrieval with `getString()` method
  * Get all arguments with `getAll()` method
  * Perfect for automated testing with Maestro
  * Comprehensive documentation and SPM integration guide
  * MIT License

## 0.0.1

* Initial development release
