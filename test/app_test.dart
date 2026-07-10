import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/presentation/app.dart';

void main() {
  testWidgets('indításkor a setup-képernyő jelenik meg', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IgyalApp()));
    await tester.pump();

    expect(find.text('Első csapat'), findsOneWidget);
    expect(find.text('Második csapat'), findsOneWidget);
  });
}
