import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_launch_arguments_ffi/flutter_launch_arguments_ffi.dart';

void main() {
  test('FlutterLaunchArguments should not crash on unsupported platforms', () {
    // This test verifies that the package doesn't throw UnsupportedError
    // on platforms like macOS, Windows, Linux (used in tests)

    // These calls should return null on unsupported platforms instead of crashing
    expect(FlutterLaunchArguments.getString('test'), isNull);
    expect(FlutterLaunchArguments.getBool('enabled'), isNull);
    expect(FlutterLaunchArguments.getAll(), isEmpty);
  });

  test('getBool should handle various inputs gracefully', () {
    // Should not crash, just return null on unsupported platforms
    expect(FlutterLaunchArguments.getBool('flag1'), isNull);
    expect(FlutterLaunchArguments.getBool('flag2'), isNull);
    expect(FlutterLaunchArguments.getBool('nonexistent'), isNull);
  });

  test('getString should handle various inputs gracefully', () {
    // Should not crash, just return null on unsupported platforms
    expect(FlutterLaunchArguments.getString('key1'), isNull);
    expect(FlutterLaunchArguments.getString('key2'), isNull);
    expect(FlutterLaunchArguments.getString('nonexistent'), isNull);
  });
}
