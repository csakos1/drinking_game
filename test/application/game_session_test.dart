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

/// Beírja a [names] neveket, és opcionálisan sorsol; a notifiert visszaadja a
/// további műveletekhez. A setup-hívásokat itt zárjuk egybe, hogy a
/// teszt-törzsekben ne legyen egymást követő azonos-vevős hívás.
GameSessionNotifier _setUp(
  ProviderContainer c,
  List<String> names, {
  bool draw = true,
}) {
  final notifier = c.read(gameSessionProvider.notifier);
  names.forEach(notifier.addName);
  if (draw) {
    notifier.drawTeams();
  }
  return notifier;
}

void main() {
  group('setup', () {
    test('addName trimmel, és eldobja az ürest/duplikátumot', () {
      final container = _container();
      addTearDown(container.dispose);

      _setUp(container, ['  Anna  ', 'Anna', '   ', 'Béla'], draw: false);

      final session = container.read(gameSessionProvider);
      expect(session, isA<GameSetup>());
      expect((session as GameSetup).names, ['Anna', 'Béla']);
    });

    test('drawTeams két nevet 1-1 arányban oszt szét', () {
      final container = _container();
      addTearDown(container.dispose);

      _setUp(container, ['Anna', 'Béla']);

      final session = container.read(gameSessionProvider) as GameSetup;
      final roster = session.roster;
      expect(roster, isNotNull);
      if (roster == null) {
        return;
      }
      expect(roster.firstCount, 1);
      expect(roster.secondCount, 1);
      expect(session.canStart, isTrue);
    });

    test('név hozzáadása üríti a sorsolt keretet', () {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _setUp(container, ['Anna', 'Béla']);
      expect(
        (container.read(gameSessionProvider) as GameSetup).roster,
        isNotNull,
      );

      notifier.addName('Cili');

      expect(
        (container.read(gameSessionProvider) as GameSetup).roster,
        isNull,
      );
    });

    test('moveToOtherTeam átbillenti a játékos csapatát', () {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _setUp(container, ['Anna', 'Béla']);

      final before = container.read(gameSessionProvider) as GameSetup;
      final roster = before.roster;
      if (roster == null) {
        fail('A sorsolásnak keretet kell adnia.');
      }
      final player = roster.players.first;
      final originalTeam = player.team;

      notifier.moveToOtherTeam(player);

      final after = container.read(gameSessionProvider) as GameSetup;
      final movedRoster = after.roster;
      if (movedRoster == null) {
        fail('A korrekció után is kell keret.');
      }
      final moved = movedRoster.players.firstWhere(
        (p) => p.name == player.name,
      );
      expect(moved.team, originalTeam.opposite);
    });
  });

  group('játékmenet', () {
    test('start feloldott első kártyát ad, és GamePlaying-re vált', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _setUp(container, ['Anna', 'Béla']);
      await notifier.start();

      final session = container.read(gameSessionProvider);
      expect(session, isA<GamePlaying>());
      final card = (session as GamePlaying).card;
      expect(card.text, isNotEmpty);
      expect(card.text, isNot(contains('{')));
    });

    test('next új feloldott kártyát léptet', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _setUp(container, ['Anna', 'Béla']);
      await notifier.start();

      notifier.next();

      final session = container.read(gameSessionProvider);
      expect(session, isA<GamePlaying>());
      expect((session as GamePlaying).card.text, isNot(contains('{')));
    });

    test('quit a keret megőrzésével visszatér a setup-ba', () async {
      final container = _container();
      addTearDown(container.dispose);

      final notifier = _setUp(container, ['Anna', 'Béla']);
      await notifier.start();

      notifier.quit();

      final session = container.read(gameSessionProvider);
      expect(session, isA<GameSetup>());
      expect((session as GameSetup).roster, isNotNull);
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
