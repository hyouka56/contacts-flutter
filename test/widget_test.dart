import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contacts_flutter/main.dart';

void main() {
  testWidgets('Dialer shows keypad and minimal navigation', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    expect(find.text('Dialer'), findsOneWidget);
    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']) {
      expect(find.byKey(ValueKey('dialer-key-$digit')), findsOneWidget);
    }
  });

  testWidgets('Dialer accepts digits and deletes the last digit', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    await tester.tap(find.byKey(const ValueKey('dialer-key-1')));
    await tester.tap(find.byKey(const ValueKey('dialer-key-2')));
    await tester.pump();
    var field = tester.widget<TextField>(find.byKey(const ValueKey('dialer-number')));
    expect(field.controller!.text, '12');
    await tester.tap(find.byTooltip('Delete last digit'));
    await tester.pump();
    field = tester.widget<TextField>(find.byKey(const ValueKey('dialer-number')));
    expect(field.controller!.text, '1');
  });

  testWidgets('Add contact form validates name and phone number', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddContactPage()));
    expect(find.byKey(const ValueKey('contact-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-phone')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-contact')));
    await tester.pump();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a phone number'), findsOneWidget);
  });
}
