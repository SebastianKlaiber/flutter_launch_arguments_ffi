// Export the public interface and exception
export 'src/launch_arguments_interface.dart';

// Import the interface for type annotations
import 'src/launch_arguments_interface.dart';

// Conditional imports based on platform
// This will import the appropriate implementation based on the platform:
// - On native platforms (iOS, Android, etc.): uses launch_arguments_native.dart
// - On web: uses launch_arguments_web.dart
// - On unsupported platforms: uses launch_arguments_unsupported.dart
import 'src/launch_arguments_unsupported.dart'
    if (dart.library.io) 'src/launch_arguments_native.dart'
    if (dart.library.html) 'src/launch_arguments_web.dart';

/// Access command-line arguments passed when launching your Flutter app.
///
/// This package provides access to launch arguments on iOS and Android platforms.
/// On web, all methods return null or empty values (graceful degradation).
/// On other platforms, methods throw UnsupportedError.
///
/// ## Platform Support
///
/// | Platform | Supported |
/// |----------|-----------|
/// | iOS      | ✅        |
/// | Android  | ✅        |
/// | Web      | ⚠️ (returns empty/null) |
/// | macOS    | ❌        |
/// | Windows  | ❌        |
/// | Linux    | ❌        |
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_launch_arguments_ffi/flutter_launch_arguments_ffi.dart';
///
/// // Get a string argument
/// final apiUrl = FlutterLaunchArguments.getString('api-url');
///
/// // Get a boolean flag
/// final enableDebug = FlutterLaunchArguments.getBool('debug');
///
/// // Get all arguments
/// final allArgs = FlutterLaunchArguments.getAll();
/// ```
class FlutterLaunchArguments {
  // Prevent instantiation
  FlutterLaunchArguments._();

  /// Get a string value for the given key from launch arguments.
  ///
  /// Returns null if the key doesn't exist.
  ///
  /// Supports multiple argument formats:
  /// - `--key=value`
  /// - `--key value`
  /// - `-key value` (Maestro format)
  ///
  /// Example:
  /// ```dart
  /// final apiUrl = FlutterLaunchArguments.getString('api-url');
  /// ```
  static String? getString(String key) {
    return _instance.getString(key);
  }

  /// Get a boolean value for the given flag from launch arguments.
  ///
  /// Returns null if the flag doesn't exist.
  /// Returns true for values: 'true', '1'
  /// Returns false for other values.
  ///
  /// Example:
  /// ```dart
  /// final isDebug = FlutterLaunchArguments.getBool('debug');
  /// if (isDebug == true) {
  ///   print('Debug mode enabled');
  /// }
  /// ```
  static bool? getBool(String flag) {
    return _instance.getBool(flag);
  }

  /// Get all launch arguments as an unmodifiable list.
  ///
  /// Returns an empty list on web or if no arguments were provided.
  ///
  /// Example:
  /// ```dart
  /// final allArgs = FlutterLaunchArguments.getAll();
  /// print('Launch arguments: $allArgs');
  /// ```
  static List<String> getAll() {
    return _instance.getAll();
  }

  /// Clear the cached arguments and force re-initialization.
  ///
  /// Useful for testing or when you need to refresh the arguments.
  ///
  /// Example:
  /// ```dart
  /// FlutterLaunchArguments.clearCache();
  /// ```
  static void clearCache() {
    _instance.clearCache();
  }

  // Private getter that returns the platform-specific instance
  // This is resolved at compile time based on the conditional imports above:
  // - On iOS/Android: returns FlutterLaunchArgumentsNative.instance
  // - On Web: returns FlutterLaunchArgumentsWeb.instance
  // - On other platforms: returns FlutterLaunchArgumentsUnsupported.instance
  static FlutterLaunchArgumentsInterface get _instance => platformInstance;
}
