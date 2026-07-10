import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/presentation/app.dart';

/// Seedelt RNG-vel felszerelt app: a proceed auto-split ága determinisztikus.
Widget _app() {
  return ProviderScope(
    overrides: [randomProvider.overrideWith((ref) => Random(1))],
    child: const IgyalApp(),
  );
}

/// Nevet ír a [key] mezőbe, és a „kész" akcióval felveszi.
Future<void> _add(WidgetTester tester, Key key, String name) async {
  await tester.enterText(find.byKey(key), name);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

/// Az IGYUNK gomb, amelynek `onPressed`-je a `canProceed`-et tükrözi.
FilledButton _cheersButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Igyunk'),
  );
}

void main() {
  const firstKey = Key('first_team_input');
  const secondKey = Key('second_team_input');

  testWidgets('kezdetben az IGYUNK gomb letiltva', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(_cheersButton(tester).onPressed, isNull);
  });

  testWidgets('két név az első csapatba aktiválja az IGYUNK gombot', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await _add(tester, firstKey, 'Anna');
    await _add(tester, firstKey, 'Béla');

    expect(_cheersButton(tester).onPressed, isNotNull);
  });

  testWidgets('egyetlen név az első csapatban még nem elég', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await _add(tester, firstKey, 'Anna');

    expect(_cheersButton(tester).onPressed, isNull);
  });

  testWidgets('a felvett név megjelenik, az ismétlés nem duplikál', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await _add(tester, firstKey, 'Anna');
    await _add(tester, firstKey, 'Anna');

    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('egy-egy név után az IGYUNK a csapat-áttekintőre vált', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await _add(tester, firstKey, 'Anna');
    await _add(tester, secondKey, 'Béla');

    await tester.tap(find.widgetWithText(FilledButton, 'Igyunk'));
    await tester.pumpAndSettle();

    // A proceed a csapat-áttekintőre vált: megjelenik a KEZDÉS, eltűnik az
    // IGYUNK.
    expect(find.text('Kezdés'), findsOneWidget);
    expect(find.text('Igyunk'), findsNothing);
  });
}
