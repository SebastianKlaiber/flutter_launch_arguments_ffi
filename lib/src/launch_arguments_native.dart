import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'flutter_launch_arguments_bindings_generated.dart';
import 'launch_arguments_interface.dart';

// Top-level getter for conditional imports
FlutterLaunchArgumentsInterface get platformInstance =>
    FlutterLaunchArgumentsNative.instance;

const String _libName = 'flutter_launch_arguments_ffi';

// Lazy initialization of FFI library - only on supported platforms
DynamicLibrary? _dylib;
FlutterLaunchArgumentsBindings? _bindings;

bool _isPlatformSupported() => Platform.isIOS || Platform.isAndroid;

DynamicLibrary? _getDylib() {
  if (_dylib != null) return _dylib;

  if (!_isPlatformSupported()) {
    return null; // Gracefully return null on unsupported platforms
  }

  if (Platform.isIOS) {
    _dylib = DynamicLibrary.process();  // SPM bundles as framework
  } else if (Platform.isAndroid) {
    _dylib = DynamicLibrary.open('lib$_libName.so');
  }

  if (_dylib != null) {
    _bindings = FlutterLaunchArgumentsBindings(_dylib!);
  }

  return _dylib;
}

class FlutterLaunchArgumentsNative implements FlutterLaunchArgumentsInterface {
  static FlutterLaunchArgumentsNative? _instance;

  final Map<String, String> _keyValueArgs = {};
  final List<String> _allArguments = [];
  bool _initialized = false;

  FlutterLaunchArgumentsNative._internal() {
    _initialize();
  }

  static FlutterLaunchArgumentsNative get instance {
    _instance ??= FlutterLaunchArgumentsNative._internal();
    return _instance!;
  }

  void _initialize() {
    if (_initialized) return;

    // Initialize FFI bindings (returns null on unsupported platforms)
    _getDylib();

    // Return early if platform is not supported
    if (_bindings == null) {
      _initialized = true;
      return;
    }

    final Pointer<CommandLineArguments> resultPtr =
        _bindings!.get_command_line_arguments();

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
      _bindings!.free_command_line_arguments(resultPtr);
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

  @override
  String? getString(String key) => _keyValueArgs[key];

  @override
  bool? getBool(String flag) {
    final value = _keyValueArgs[flag];
    if (value == null) return null;
    return value.toLowerCase() == 'true' || value == '1';
  }

  @override
  List<String> getAll() => List.unmodifiable(_allArguments);

  @override
  void clearCache() {
    _keyValueArgs.clear();
    _allArguments.clear();
    _initialized = false;
    _instance = null;
  }
}
