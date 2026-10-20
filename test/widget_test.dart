import 'package:flutter_test/flutter_test.dart';
import 'package:contacts_flutter/main.dart';

void main() {
  testWidgets('Contacts shows add button and no top refresh button', (tester) async {
    await tester.pumpWidget(const ContactsApp());
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.byTooltip('Add contact'), findsOneWidget);
    expect(find.byTooltip('Refresh contacts'), findsNothing);
  });
}
