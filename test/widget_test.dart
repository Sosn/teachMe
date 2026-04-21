import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teach_me/app/app.dart';

void main() {
  testWidgets('Root screen is subject picker with orthography card',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeachMeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Czego chcesz się dziś uczyć?'), findsOneWidget);
    expect(find.text('Ortografia'), findsOneWidget);
    expect(find.text('Części mowy'), findsOneWidget);
    expect(find.text('Matematyka'), findsOneWidget);
    expect(find.text('Czytanie'), findsOneWidget);
  });
}
