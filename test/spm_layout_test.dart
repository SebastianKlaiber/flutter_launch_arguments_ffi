import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Swift Package Manager layout', () {
    test('uses Flutter plugin package path and split Swift/Objective-C targets', () {
      final packageManifest = File(
        'ios/flutter_launch_arguments_ffi/Package.swift',
      );
      final deprecatedManifest = File('ios/Package.swift');
      final swiftPlugin = File(
        'ios/flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi/FlutterLaunchArgumentsFfiPlugin.swift',
      );
      final objectiveCImplementation = File(
        'ios/flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/ios_args.m',
      );
      final publicHeader = File(
        'ios/flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/include/launch_arguments.h',
      );

      expect(packageManifest.existsSync(), isTrue);
      expect(deprecatedManifest.existsSync(), isFalse);
      expect(swiftPlugin.existsSync(), isTrue);
      expect(objectiveCImplementation.existsSync(), isTrue);
      expect(publicHeader.existsSync(), isTrue);

      final manifest = packageManifest.readAsStringSync();
      expect(manifest, contains('name: "flutter_launch_arguments_ffi"'));
      expect(
        manifest,
        contains('.library(name: "flutter-launch-arguments-ffi"'),
      );
      expect(
        manifest,
        contains(
          '.package(name: "FlutterFramework", path: "../FlutterFramework")',
        ),
      );
      expect(manifest, contains('name: "flutter_launch_arguments_ffi_native"'));
      expect(manifest, isNot(contains('contains mixed language')));
    });

    test('keeps CocoaPods pointing at the shared SPM sources', () {
      final podspec = File(
        'ios/flutter_launch_arguments_ffi.podspec',
      ).readAsStringSync();

      expect(
        podspec,
        contains(
          "s.source_files = 'flutter_launch_arguments_ffi/Sources/**/*.{swift,m,h}'",
        ),
      );
      expect(
        podspec,
        contains(
          "s.public_header_files = 'flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/include/**/*.h'",
        ),
      );
      expect(podspec, isNot(contains("s.source_files     = 'Sources/")));
    });

    test(
      'declares Flutter version required by FlutterFramework dependency',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();

        expect(pubspec, contains("sdk: ^3.11.0"));
        expect(pubspec, contains("flutter: '>=3.41.0'"));
      },
    );

    test('points shared tooling at the nested public header', () {
      final headerPath =
          'ios/flutter_launch_arguments_ffi/Sources/flutter_launch_arguments_ffi_native/include/launch_arguments.h';
      final androidCmake = File('android/CMakeLists.txt').readAsStringSync();
      final ffigen = File('ffigen.yaml').readAsStringSync();

      expect(
        androidCmake,
        contains('../$headerPath'.replaceAll('/launch_arguments.h', '')),
      );
      expect(ffigen, contains(headerPath));
    });
  });
}
