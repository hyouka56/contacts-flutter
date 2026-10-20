import 'package:flutter_test/flutter_test.dart';
import 'package:contacts_flutter/main.dart';

void main() {
  testWidgets('Contacts app renders its title', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    expect(find.text('Contacts'), findsOneWidget);
  });
}
