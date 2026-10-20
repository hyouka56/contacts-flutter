import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contacts_flutter/main.dart';

void main() {
  testWidgets('Contacts shows add button and no top refresh button', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.byTooltip('Add contact'), findsOneWidget);
    expect(find.byTooltip('Refresh contacts'), findsNothing);
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
