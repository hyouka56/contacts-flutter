import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contacts_flutter/main.dart';

void main() {
  testWidgets('App opens directly to contacts only', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    await tester.pump();
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Dialer'), findsNothing);
    expect(find.text('Recents'), findsNothing);
    expect(find.byKey(const ValueKey('dialer-number')), findsNothing);
  });

  testWidgets('Add contact form validates name and phone number', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddContactPage()));
    expect(find.byKey(const ValueKey('contact-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('contact-phone')), findsOneWidget);
    final nameInput = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('contact-name')),
        matching: find.byType(TextField),
      ),
    );
    final phoneInput = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('contact-phone')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameInput.decoration?.labelText, 'Name');
    expect(phoneInput.decoration?.labelText, 'Phone number');
    await tester.tap(find.byKey(const ValueKey('save-contact')));
    await tester.pump();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a phone number'), findsOneWidget);
  });
}
