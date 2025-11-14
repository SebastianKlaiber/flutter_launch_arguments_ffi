# flutter_launch_arguments_ffi

A Flutter FFI plugin that provides access to command-line launch arguments on iOS and Android. This package allows you to pass arguments when launching your Flutter app and access them from Dart code, making it perfect for automated testing, debugging, and feature flagging.

## Features

- 🚀 Access command-line launch arguments in Flutter apps
- 📱 Cross-platform support (iOS and Android)
- ⚡ Built with FFI for high performance
- 🎯 Simple API with `getString()`, `getBool()`, and `getAll()` methods
- 🧪 Perfect for Maestro UI testing and automation
- 📦 Swift Package Manager (SPM) support for iOS
- 🔧 No method channels required

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| Web      | ❌        |
| macOS    | ❌        |
| Windows  | ❌        |
| Linux    | ❌        |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_launch_arguments_ffi: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:flutter_launch_arguments_ffi/flutter_launch_arguments_ffi.dart';

void main() {
  // Get a specific string argument
  final apiUrl = FlutterLaunchArguments.getString('apiUrl');
  print('API URL: $apiUrl'); // null if not provided

  // Get a boolean flag
  final debugMode = FlutterLaunchArguments.getBool('debug');
  print('Debug mode: $debugMode'); // null if not provided

  // Get all arguments as a list
  final allArgs = FlutterLaunchArguments.getAll();
  print('All arguments: $allArgs');

  runApp(MyApp());
}
```

### Using with Nullable Booleans

The `getBool()` method returns `bool?` to distinguish between three states:
- `null` - argument wasn't provided
- `true` - argument was provided and set to "true" or "1"
- `false` - argument was provided but set to another value

```dart
final debugMode = FlutterLaunchArguments.getBool('debug');
if (debugMode == null) {
  // Use default behavior - argument not provided
  print('Debug mode not specified');
} else if (debugMode) {
  // Explicitly enabled
  print('Debug mode enabled');
} else {
  // Explicitly disabled
  print('Debug mode disabled');
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_launch_arguments_ffi/flutter_launch_arguments_ffi.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> _args = [];
  String? _environment;
  bool? _debugMode;
  String _error = '';

  @override
  void initState() {
    super.initState();
    try {
      _args = FlutterLaunchArguments.getAll();
      _environment = FlutterLaunchArguments.getString('env');
      _debugMode = FlutterLaunchArguments.getBool('debug');
    } catch (e) {
      _error = e.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Launch Arguments')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error.isNotEmpty)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error),
                ),
              ),
            Card(
              child: ListTile(
                title: const Text('Environment'),
                subtitle: Text(_environment ?? 'Not specified'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Debug Mode'),
                subtitle: Text(_debugMode?.toString() ?? 'Not specified'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Total Arguments: ${_args.length}'),
              ),
            ),
            const Divider(),
            ..._args.map((arg) => Card(child: ListTile(title: Text(arg)))),
          ],
        ),
      ),
    );
  }
}
```

## Launching Your App with Arguments

### iOS (Simulator)

Using `xcrun simctl`:

```bash
xcrun simctl launch booted com.example.myapp --env production --debug true
```

Using Maestro:

```yaml
appId: com.example.myapp
---
- launchApp:
    arguments:
      env: "production"
      debug: "true"
      apiUrl: "https://api.example.com"
```

### Android (Device/Emulator)

Using `adb`:

```bash
adb shell am start -n com.example.myapp/.MainActivity \
  --es env production \
  --ez debug true \
  --es apiUrl "https://api.example.com"
```

Using Maestro:

```yaml
appId: com.example.myapp
---
- launchApp:
    arguments:
      env: "production"
      debug: "true"
      apiUrl: "https://api.example.com"
```

## Argument Format

The package supports multiple argument formats:

- `--key=value` - Key-value pair with equals sign
- `--key value` - Key-value pair with space
- `--flag` - Boolean flag (defaults to "true")
- `-key value` - Short format (commonly used by Maestro)
- `-flag` - Short boolean flag

## How It Works

This package uses Dart FFI (Foreign Function Interface) to call native C/C++ code that retrieves the command-line arguments:

1. **Android**: Accesses `ProcessInfo.getCmdline()` via JNI to retrieve arguments
2. **iOS**: Uses `NSProcessInfo.processInfo.arguments` to get arguments
3. **FFI Bridge**: Native code is exposed to Dart through FFI bindings
4. **Parsing**: Arguments are parsed to extract key-value pairs and flags

## iOS Setup (Swift Package Manager)

This package uses Swift Package Manager for iOS. For detailed setup instructions, see [SPM Guide](doc/flutter_launch_arguments_ffi_spm_guide.md).

## Testing

The package includes Maestro UI test scripts in the `example/.maestro` directory:

```bash
# Install Maestro
curl -Ls "https://get.maestro.mobile.dev" | bash

# Run tests
cd example
maestro test .maestro/launch_arguments_test.yaml
```

## Clearing Cache

If you need to reset the singleton instance (useful for testing):

```dart
FlutterLaunchArguments.clearCache();
```

## Error Handling

The package throws `FlutterLaunchArgumentsException` if there are errors accessing native arguments:

```dart
try {
  final args = FlutterLaunchArguments.getAll();
} on FlutterLaunchArgumentsException catch (e) {
  print('Error getting arguments: $e');
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Sebastian Klaiber

## Issues

Please file any issues, bugs, or feature requests in our [issue tracker](https://github.com/SebastianKlaiber/flutter_launch_arguments_ffi/issues).
