import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liblibeapp/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    // Mock returns placeholder options (apiKey "123"); use default init so it matches.
    await Firebase.initializeApp();
  });

  testWidgets('LiblibeApp builds without throwing and renders a MaterialApp', (
    WidgetTester tester,
  ) async {
    // Phone-like height so layout has room.
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LiblibeApp());
    // A single pump (not pumpAndSettle) because the app has continuous
    // background animations that would never settle.
    await tester.pump();

    // The root MaterialApp is present, proving the app booted and applied
    // its theme without throwing during build.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
