import 'package:flutter_test/flutter_test.dart';
import 'package:notime_app/app/notime_app.dart';

void main() {
  testWidgets('NotiMe app launches starter flow', (tester) async {
    await tester.pumpWidget(const NotiMeApp());
    await tester.pumpAndSettle();

    expect(find.text('Receive Notifications From Your Favorite Apps'), findsOneWidget);
    expect(find.text('Simulate valid Scratchify login'), findsOneWidget);
  });
}
