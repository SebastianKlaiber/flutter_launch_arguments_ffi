import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'src/flutter_launch_arguments_bindings_generated.dart';

const String _libName = 'flutter_launch_arguments_ffi';

final DynamicLibrary _dylib = () {
  if (Platform.isIOS) {
    return DynamicLibrary.process();  // SPM bundles as framework
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
}();

final FlutterLaunchArgumentsBindings _bindings =
    FlutterLaunchArgumentsBindings(_dylib);

class FlutterLaunchArguments {
  static FlutterLaunchArguments? _instance;

  final Map<String, String> _keyValueArgs = {};
  final List<String> _allArguments = [];
  bool _initialized = false;

  FlutterLaunchArguments._internal() {
    _initialize();
  }

  static FlutterLaunchArguments get instance {
    _instance ??= FlutterLaunchArguments._internal();
    return _instance!;
  }

  void _initialize() {
    if (_initialized) return;

    final Pointer<CommandLineArguments> resultPtr =
        _bindings.get_command_line_arguments();

    if (resultPtr == nullptr) {
      throw FlutterLaunchArgumentsException('Native returned null');
    }

    try {
      final result = resultPtr.ref;

      if (result.error_code != 0) {
        final error = result.error_message != nullptr
            ? result.error_message.cast<Utf8>().toDartString()
            : 'Error code: ${result.error_code}';
        throw FlutterLaunchArgumentsException(error);
      }

      if (result.count > 0 && result.arguments != nullptr) {
        final argsArray = result.arguments.cast<Pointer<Utf8>>();

        for (int i = 0; i < result.count; i++) {
          final argPtr = argsArray[i];
          if (argPtr == nullptr) continue;

          final arg = argPtr.toDartString();
          _allArguments.add(arg);
        }

        // Parse arguments with lookahead for -key value pairs
        for (int i = 0; i < _allArguments.length; i++) {
          final arg = _allArguments[i];

          // Check if next argument exists and doesn't start with - (potential value)
          final nextArg = (i + 1 < _allArguments.length) ? _allArguments[i + 1] : null;
          final hasNextValue = nextArg != null && !nextArg.startsWith('-');

          if (_parseArgumentWithLookahead(arg, nextArg, hasNextValue)) {
            i++; // Skip next argument as it was consumed as a value
          }
        }
      }

      _initialized = true;
    } finally {
      _bindings.free_command_line_arguments(resultPtr);
    }
  }

  /// Returns true if the next argument was consumed as a value
  bool _parseArgumentWithLookahead(String arg, String? nextArg, bool hasNextValue) {
    // Handle --key=value format
    if (arg.startsWith('--') && arg.contains('=')) {
      final stripped = arg.substring(2);
      final idx = stripped.indexOf('=');
      _keyValueArgs[stripped.substring(0, idx)] = stripped.substring(idx + 1);
      return false;
    }

    // Handle --key or --key value format
    if (arg.startsWith('--')) {
      final key = arg.substring(2);
      if (hasNextValue) {
        _keyValueArgs[key] = nextArg!;
        return true; // Consumed next argument
      } else {
        _keyValueArgs[key] = 'true';
        return false;
      }
    }

    // Handle -key or -key value format (Maestro uses this)
    if (arg.startsWith('-') && !arg.startsWith('--')) {
      final key = arg.substring(1);
      if (hasNextValue) {
        _keyValueArgs[key] = nextArg!;
        return true; // Consumed next argument
      } else {
        _keyValueArgs[key] = 'true';
        return false;
      }
    }

    return false;
  }

  static String? getString(String key) => instance._keyValueArgs[key];

  static bool? getBool(String flag) {
    final value = instance._keyValueArgs[flag];
    if (value == null) return null;
    return value.toLowerCase() == 'true' || value == '1';
  }

  static List<String> getAll() => List.unmodifiable(instance._allArguments);

  static void clearCache() {
    _instance?._keyValueArgs.clear();
    _instance?._allArguments.clear();
    _instance?._initialized = false;
    _instance = null;
  }
}

class FlutterLaunchArgumentsException implements Exception {
  final String message;
  FlutterLaunchArgumentsException(this.message);

  @override
  String toString() => 'FlutterLaunchArgumentsException: $message';
}
