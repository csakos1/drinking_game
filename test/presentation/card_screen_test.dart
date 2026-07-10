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

/// Egy vírus-sablon: determinisztikus típuscím (Vírus) és szöveg.
const _oneVirus =
    '{"version":1,"templates":[{"id":"v","type":"virus","constraint":"everyone","playerCount":0,"text":"Virus kartya"}]}';

/// Két különböző típusú sablon: a no-repeat léptetés a másik típusra vált.
const _twoTypes =
    '{"version":1,"templates":[{"id":"v","type":"virus","constraint":"everyone","playerCount":0,"text":"Virus kartya"},{"id":"j","type":"jatek","constraint":"everyone","playerCount":0,"text":"Jatek kartya"}]}';

const _cardTap = Key('card_tap_area');

ProviderContainer _container(String json, {int seed = 1}) {
  return ProviderContainer(
    overrides: [
      randomProvider.overrideWith((ref) => Random(seed)),
      bundledTaskTemplateSourceProvider.overrideWith(
        (ref) => _FakeSource(Success(json)),
      ),
      taskTemplateCacheProvider.overrideWith(
        (ref) => _FakeCache(loadResult: const Failure(TaskSourceNotFound('x'))),
      ),
    ],
  );
}

Widget _app(ProviderContainer c) {
  return UncontrolledProviderScope(container: c, child: const IgyalApp());
}

/// Végigviszi a folyamot a kártyáig: bevitel + IGYUNK + KEZDÉS (a start()-ot a
/// KEZDÉS gomb triggeli, hogy a fake tartalombetöltés a pump során oldódjon fel).
Future<void> _toCard(
  WidgetTester tester,
  ProviderContainer c, {
  required List<String> first,
  required List<String> second,
}) async {
  final notifier = c.read(gameSessionProvider.notifier);
  for (final name in first) {
    notifier.add(name, Team.first);
  }
  for (final name in second) {
    notifier.add(name, Team.second);
  }
  notifier.proceed();

  await tester.pumpWidget(_app(c));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Kezdés'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a kártya a típuscímet és a szöveget mutatja', (tester) async {
    final container = _container(_oneVirus);
    addTearDown(container.dispose);

    await _toCard(tester, container, first: ['Anna', 'Béla'], second: ['Cili']);

    expect(find.text('Vírus'), findsOneWidget);
    expect(find.text('Virus kartya'), findsOneWidget);
  });

  testWidgets('koppintás a következő kártyára léptet (más típus)', (
    tester,
  ) async {
    final container = _container(_twoTypes);
    addTearDown(container.dispose);

    await _toCard(tester, container, first: ['Anna', 'Béla'], second: ['Cili']);

    final virusBefore = find.text('Vírus').evaluate().isNotEmpty;
    await tester.tap(find.byKey(_cardTap));
    await tester.pump();
    final virusAfter = find.text('Vírus').evaluate().isNotEmpty;

    expect(virusAfter, isNot(virusBefore));
  });

  testWidgets('OS-vissza + Kilépés az áttekintőbe tér vissza', (tester) async {
    final container = _container(_oneVirus);
    addTearDown(container.dispose);

    await _toCard(tester, container, first: ['Anna', 'Béla'], second: ['Cili']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Kilépsz a játékból?'), findsOneWidget);

    await tester.tap(find.text('Kilépés'));
    await tester.pumpAndSettle();

    expect(find.text('Kezdés'), findsOneWidget);
    expect(find.text('Virus kartya'), findsNothing);
  });

  testWidgets('OS-vissza + Mégse a kártyán marad', (tester) async {
    final container = _container(_oneVirus);
    addTearDown(container.dispose);

    await _toCard(tester, container, first: ['Anna', 'Béla'], second: ['Cili']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();

    expect(find.text('Virus kartya'), findsOneWidget);
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
