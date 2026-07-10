import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/application/content_providers.dart';
import 'package:igyal2/src/application/game_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/team.dart';

/// Két 1v1-ben játszható sablon: egy névre feloldódó (`anyone`) és egy token
/// nélküli (`everyone`), hogy a `StartGame` biztosan találjon játszhatót.
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
        (ref) => _FakeCache(
          loadResult: const Failure(TaskSourceNotFound('nincs')),
        ),
      ),
    ],
  );
}

/// Felveszi a neveket a két csapatba, és visszaadja a notifiert (GameSetup).
GameSessionNotifier _entered(
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
  return notifier;
}

/// Bevitel + IGYUNK: a notifiert GameTeams állapotban adja vissza.
GameSessionNotifier _teams(
  ProviderContainer c, {
  List<String> first = const [],
  List<String> second = const [],
}) {
  return _entered(c, first: first, second: second)..proceed();
}

/// Bevitel + IGYUNK + KEZDÉS: a notifiert GamePlaying állapotban adja vissza.
Future<GameSessionNotifier> _playing(
  ProviderContainer c, {
  List<String> first = const [],
  List<String> second = const [],
}) async {
  final notifier = _teams(c, first: first, second: second);
  await notifier.start();
  return notifier;
}

void main() {
  group('setup', () {
    test('add trimmel és a két csapaton keresztül deduplikál', () {
      final container = _container();
      addTearDown(container.dispose);

      _entered(
        container,
        first: ['  Anna  ', 'Anna', 'Béla'],
        second: ['Anna'],
      );

      final session = container.read(gameSessionProvider) as GameSetup;
      expect(session.firstNames, ['Anna', 'Béla']);
      expect(session.secondNames, isEmpty);
    });

    test('canProceed: egy név az elsőben kevés, egy-egy mindkettőben elég', () {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _entered(container, first: ['a']);
      expect(
        (container.read(gameSessionProvider) as GameSetup).canProceed,
        isFalse,
      );

      notifier.add('b', Team.second);

      expect(
        (container.read(gameSessionProvider) as GameSetup).canProceed,
        isTrue,
      );
    });
  });

  group('csapatalkotás', () {
    test('proceed csak első csapattal auto-splitel (egyenlő)', () {
      final container = _container();
      addTearDown(container.dispose);

      _teams(container, first: ['a', 'b', 'c', 'd']);

      final session = container.read(gameSessionProvider) as GameTeams;
      expect(session.wasAutoSplit, isTrue);
      expect(session.roster.firstCount, 2);
      expect(session.roster.secondCount, 2);
      expect(session.roster.isStartable, isTrue);
    });

    test('proceed mindkét csapattal a kézi felosztást tartja', () {
      final container = _container();
      addTearDown(container.dispose);

      _teams(container, first: ['a', 'b'], second: ['c']);

      final session = container.read(gameSessionProvider) as GameTeams;
      expect(session.wasAutoSplit, isFalse);
      expect(session.roster.first.map((p) => p.name), ['a', 'b']);
      expect(session.roster.second.map((p) => p.name), ['c']);
    });

    test('redraw auto-split után is egyenlő és auto-split marad', () {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _teams(container, first: ['a', 'b', 'c', 'd']);
      expect(
        (container.read(gameSessionProvider) as GameTeams).wasAutoSplit,
        isTrue,
      );

      notifier.redraw();

      final session = container.read(gameSessionProvider) as GameTeams;
      expect(session.wasAutoSplit, isTrue);
      expect(session.roster.firstCount, 2);
      expect(session.roster.secondCount, 2);
    });

    test('backToSetup a keretből visszaállítja a két listát', () {
      final container = _container();
      addTearDown(container.dispose);

      _teams(container, first: ['a', 'b'], second: ['c']).backToSetup();

      final session = container.read(gameSessionProvider) as GameSetup;
      expect(session.firstNames, ['a', 'b']);
      expect(session.secondNames, ['c']);
    });
  });

  group('játékmenet', () {
    test('start feloldott első kártyát ad, és GamePlaying-re vált', () async {
      final container = _container();
      addTearDown(container.dispose);

      await _playing(container, first: ['Anna', 'Béla']);

      final session = container.read(gameSessionProvider);
      expect(session, isA<GamePlaying>());
      final card = (session as GamePlaying).card;
      expect(card.text, isNotEmpty);
      expect(card.text, isNot(contains('{')));
    });

    test('next új feloldott kártyát léptet', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = await _playing(container, first: ['Anna', 'Béla']);
      expect(container.read(gameSessionProvider), isA<GamePlaying>());

      notifier.next();

      final session = container.read(gameSessionProvider);
      expect(session, isA<GamePlaying>());
      expect((session as GamePlaying).card.text, isNot(contains('{')));
    });

    test('quit a keret megőrzésével az áttekintőbe tér vissza', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = await _playing(container, first: ['Anna', 'Béla']);
      expect(container.read(gameSessionProvider), isA<GamePlaying>());

      notifier.quit();

      final session = container.read(gameSessionProvider);
      expect(session, isA<GameTeams>());
      expect((session as GameTeams).roster.isStartable, isTrue);
    });
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
