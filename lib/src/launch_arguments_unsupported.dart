import 'launch_arguments_interface.dart';

// Top-level getter for conditional imports
FlutterLaunchArgumentsInterface get platformInstance =>
    FlutterLaunchArgumentsUnsupported.instance;

/// Unsupported platform implementation of FlutterLaunchArguments.
///
/// This implementation is used for platforms that are not yet supported.
/// All methods throw UnsupportedError to indicate the platform is not supported.
class FlutterLaunchArgumentsUnsupported
    implements FlutterLaunchArgumentsInterface {
  static FlutterLaunchArgumentsUnsupported? _instance;

  FlutterLaunchArgumentsUnsupported._internal();

  static FlutterLaunchArgumentsUnsupported get instance {
    _instance ??= FlutterLaunchArgumentsUnsupported._internal();
    return _instance!;
  }

  @override
  String? getString(String key) {
    throw UnsupportedError(
      'FlutterLaunchArguments is not supported on this platform. '
      'Supported platforms: iOS, Android, Web',
    );
  }

  @override
  bool? getBool(String flag) {
    throw UnsupportedError(
      'FlutterLaunchArguments is not supported on this platform. '
      'Supported platforms: iOS, Android, Web',
    );
  }

  @override
  List<String> getAll() {
    throw UnsupportedError(
      'FlutterLaunchArguments is not supported on this platform. '
      'Supported platforms: iOS, Android, Web',
    );
  }

  @override
  void clearCache() {
    _instance = null;
  }
}
