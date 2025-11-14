/// Abstract interface for platform-specific implementations of launch arguments.
abstract class FlutterLaunchArgumentsInterface {
  /// Get a string value for the given key from launch arguments.
  /// Returns null if the key doesn't exist.
  String? getString(String key);

  /// Get a boolean value for the given flag from launch arguments.
  /// Returns null if the flag doesn't exist.
  /// Returns true for values: 'true', '1'
  /// Returns false for other values
  bool? getBool(String flag);

  /// Get all launch arguments as an unmodifiable list.
  List<String> getAll();

  /// Clear the cached arguments and force re-initialization.
  void clearCache();
}

/// Exception thrown when there's an error accessing launch arguments.
class FlutterLaunchArgumentsException implements Exception {
  final String message;
  FlutterLaunchArgumentsException(this.message);

  @override
  String toString() => 'FlutterLaunchArgumentsException: $message';
}
