import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_launch_arguments_ffi_example/main.dart';

void main() {
  testWidgets('Launch arguments UI renders fallback values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.text('Launch Arguments FFI'), findsOneWidget);
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('foo'), findsOneWidget);
    expect(find.text('enabled'), findsOneWidget);
    expect(find.text('null'), findsNWidgets(2));
  });
}
