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
  String? _foo;
  bool _enabled = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    try {
      _args = FlutterLaunchArguments.getAll();
      _foo = FlutterLaunchArguments.getString('foo');
      _enabled = FlutterLaunchArguments.getBool('enabled');
    } catch (e) {
      _error = e.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Launch Arguments FFI')),
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
            Card(child: ListTile(title: Text('Count: ${_args.length}'))),
            Card(child: ListTile(title: const Text('foo'), subtitle: Text(_foo ?? 'null'))),
            Card(child: ListTile(title: const Text('enabled'), subtitle: Text('$_enabled'))),
            const Divider(),
            ..._args.map((arg) => Card(child: ListTile(title: Text(arg)))),
          ],
        ),
      ),
    );
  }
}
