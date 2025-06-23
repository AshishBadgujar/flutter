import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notes/main.dart';

void main() {
  testWidgets('Notes app launches and shows default UI', (WidgetTester tester) async {
    // Build the app and wait for it to settle
    await tester.pumpWidget(MyApp(isDarkMode: false));
    await tester.pumpAndSettle();

    // Verify that a default folder (e.g., 'Default') is visible
    expect(find.text('Default'), findsWidgets);

    // Verify presence of the 'Folders' label in the sidebar
    expect(find.text('Folders'), findsOneWidget);

    // Look for the '+' or folder creation icon (optional)
    expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
  });
}
