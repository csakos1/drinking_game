import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/application/content_providers.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/team.dart';
import 'package:igyal2/src/presentation/app.dart';

/// Két 1v1-ben játszható sablon (egy névre feloldó és egy token nélküli), hogy a
/// KEZDÉS bármely nem üres kerettel el tudjon indulni.
const _validJson =
    '{"version":1,"templates":[{"id":"a1","type":"jatek","constraint":"anyone","playerCount":1,"text":"{p1} iszik"},{"id":"ev","type":"virus","constraint":"everyone","playerCount":0,"text":"Mindenki iszik"}]}';

/// Seedelt RNG-vel és fake tartalomforrásokkal felszerelt container: a
/// `taskContentProvider` a valódi validátoron át áll elő a fake bundledből.
ProviderContainer _container({int seed = 1}) {
  return ProviderContainer(
    overrides: [
      randomProvider.overrideWith((ref) => Random(seed)),
      bundledTaskTemplateSourceProvider.overrideWith(
        (ref) => const _FakeSource(Success(_validJson)),
      ),
      taskTemplateCacheProvider.overrideWith(
        (ref) => _FakeCache(loadResult: const Failure(TaskSourceNotFound('x'))),
      ),
    ],
  );
}

/// Bevitel + IGYUNK: a containert GameTeams állapotba hozza.
void _toTeams(
  ProviderContainer c, {
  List<String> first = const [],
  List<String> second = const [],
}) {
  final notifier = c.read(gameSessionProvider.notifier);
  for (final name in first) {
    notifier.add(name, Team.first);
  }
  for (final name in second) {
    notifier.add(name, Team.second);
  }
  notifier.proceed();
}

Widget _app(ProviderContainer c) {
  return UncontrolledProviderScope(container: c, child: const IgyalApp());
}

void main() {
  testWidgets('kézi keretnél nincs ÚJRASORSOLÁS, a KEZDÉS látszik', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    _toTeams(container, first: ['Anna', 'Béla'], second: ['Cili']);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Cili'), findsOneWidget);
    expect(find.text('Kezdés'), findsOneWidget);
    expect(find.text('Újrasorsolás'), findsNothing);
  });

  testWidgets('auto-split keretnél megjelenik az ÚJRASORSOLÁS', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    _toTeams(container, first: ['a', 'b', 'c', 'd']);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Újrasorsolás'), findsOneWidget);
  });

  testWidgets('VISSZA a névbeviteli setupra tér vissza', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    _toTeams(container, first: ['Anna', 'Béla'], second: ['Cili']);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Vissza'));
    await tester.pumpAndSettle();

    // A setupra jellemző IGYUNK gomb; a KEZDÉS eltűnik.
    expect(find.text('Igyunk'), findsOneWidget);
    expect(find.text('Kezdés'), findsNothing);
  });

  testWidgets('KEZDÉS elindítja a játékot (a kártyára vált)', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    _toTeams(container, first: ['Anna', 'Béla'], second: ['Cili']);

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Kezdés'));
    await tester.pumpAndSettle();

    // A kártya-képernyőre váltunk: a teljes képernyős koppintási terület jelen,
    // a KEZDÉS gomb eltűnt.
    expect(find.byKey(const Key('card_tap_area')), findsOneWidget);
    expect(find.text('Kezdés'), findsNothing);
  });
}

class _FakeSource implements TaskTemplateSource {
  const _FakeSource(this._result);

  final Result<String, TaskSourceError> _result;

  @override
  Future<Result<String, TaskSourceError>> load() async => _result;
}

class _FakeCache implements TaskTemplateCache {
  _FakeCache({required Result<String, TaskSourceError> loadResult}) : _loadResult = loadResult;

  final Result<String, TaskSourceError> _loadResult;

  @override
  Future<Result<String, TaskSourceError>> load() async => _loadResult;

  @override
  Future<Result<void, TaskSourceError>> save(String rawJson) async =>
      const Success<void, TaskSourceError>(null);

  @override
  Future<Result<void, TaskSourceError>> clear() async => const Success<void, TaskSourceError>(null);
}
