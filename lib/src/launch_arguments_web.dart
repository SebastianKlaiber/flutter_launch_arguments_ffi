import 'launch_arguments_interface.dart';

// Top-level getter for conditional imports
FlutterLaunchArgumentsInterface get platformInstance =>
    FlutterLaunchArgumentsWeb.instance;

/// Web implementation of FlutterLaunchArguments.
///
/// Launch arguments are not supported on web platforms.
/// All methods return null or empty values to allow graceful degradation.
class FlutterLaunchArgumentsWeb implements FlutterLaunchArgumentsInterface {
  static FlutterLaunchArgumentsWeb? _instance;

  FlutterLaunchArgumentsWeb._internal();

  static FlutterLaunchArgumentsWeb get instance {
    _instance ??= FlutterLaunchArgumentsWeb._internal();
    return _instance!;
  }

  @override
  String? getString(String key) => null;

  @override
  bool? getBool(String flag) => null;

  @override
  List<String> getAll() => const [];

  @override
  void clearCache() {
    _instance = null;
  }
}
