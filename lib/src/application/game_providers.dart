import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/content_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/domain/draw_next.dart';
import 'package:igyal2/src/domain/draw_teams.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/start_game.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/team.dart';

/// A domain use case-ek véletlenforrása.
///
/// Élesben seedeletlen [Random]; tesztben `Random(seed)`-re felülírható, így a
/// sorsolás, a pakli-keverés és a fair választás determinisztikus. Ugyanaz a
/// példány szolgálja ki az összes húzást, így állapota végigível a session-ön.
final randomProvider = Provider<Random>((ref) => Random());

/// A csapatsorsolás use case (tiszta, állapotmentes).
final drawTeamsProvider = Provider<DrawTeams>((ref) => const DrawTeams());

/// A játékindítás (pakli-felépítés) use case.
final startGameProvider = Provider<StartGame>((ref) => const StartGame());

/// A következő kártya húzása + feloldása use case.
final drawNextProvider = Provider<DrawNext>((ref) => const DrawNext());

/// A `{team}` placeholder lokalizált csapatcímkéi.
///
/// Alapértelmezésben a v1 magyar címkéi; a presentation-réteg ezt írja majd
/// felül az ARB-ből származó értékekkel. A domain (`DrawNext`) csak ezt a
/// leképezést kapja, l10n-t nem ismer.
final teamLabelsProvider = Provider<Map<Team, String>>((ref) {
  return const {Team.first: 'A csapat', Team.second: 'B csapat'};
});

/// A játék-session állapotgépe: a setup ↔ áttekintő ↔ futó játék átmenetek.
final gameSessionProvider = NotifierProvider<GameSessionNotifier, GameSession>(
  GameSessionNotifier.new,
);

/// A [GameSession] állapotát kezelő `Notifier` (lásd ADR-0003).
///
/// A setup két csapatba veszi fel a neveket ([add]/[remove]); a [proceed]
/// (IGYUNK) a feltételes csapatalkotást végzi és [GameTeams]-re vált; onnan a
/// [start] (KEZDÉS) a `StartGame`→`DrawNext` láncot futtatja és [GamePlaying]-re
/// vált, a [redraw] újrasorsol (csak auto-splitnél), a [backToSetup] visszalép
/// szerkesztésre. A [next] lépteti a kártyát; a [quit] a keret megőrzésével az
/// áttekintőbe tér vissza. A véletlen és a use case-ek providerekből jönnek, így
/// tesztben felülírhatók.
class GameSessionNotifier extends Notifier<GameSession> {
  /// A futó játékhoz tartozó sablon-térkép (id → sablon), a [start]-nál
  /// pillanatképként rögzítve, hogy egy háttér-tartalomfrissítés ne cserélje ki
  /// a pakli mögötti sablonokat menet közben. A notifier élettartamával együtt
  /// nullázódik.
  Map<String, TaskTemplate>? _templatesById;

  @override
  GameSession build() => const GameSetup();

  /// Felvesz egy nevet a [team] csapatba (trimmelve). Üres nevet, illetve a két
  /// csapaton keresztül már meglévő nevet figyelmen kívül hagy.
  void add(String name, Team team) {
    final session = state;
    if (session is! GameSetup) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        session.firstNames.contains(trimmed) ||
        session.secondNames.contains(trimmed)) {
      return;
    }
    state = switch (team) {
      Team.first => GameSetup(
        firstNames: [...session.firstNames, trimmed],
        secondNames: session.secondNames,
      ),
      Team.second => GameSetup(
        firstNames: session.firstNames,
        secondNames: [...session.secondNames, trimmed],
      ),
    };
  }

  /// Töröl egy nevet a [team] csapatból.
  void remove(String name, Team team) {
    final session = state;
    if (session is! GameSetup) {
      return;
    }
    state = switch (team) {
      Team.first => GameSetup(
        firstNames: [...session.firstNames]..remove(name),
        secondNames: session.secondNames,
      ),
      Team.second => GameSetup(
        firstNames: session.firstNames,
        secondNames: [...session.secondNames]..remove(name),
      ),
    };
  }

  /// Feltételes csapatalkotás (IGYUNK): üres második csapat + legalább két név
  /// az elsőben → véletlen `DrawTeams`-felosztás; egyébként kézi keret (első
  /// lista → [Team.first], második → [Team.second]). Csak [GameSetup]-ban és
  /// [GameSetup.canProceed] esetén hat. Az eredmény [GameTeams].
  void proceed() {
    final session = state;
    if (session is! GameSetup || !session.canProceed) {
      return;
    }
    if (session.secondNames.isEmpty) {
      final roster = ref.read(drawTeamsProvider)(
        session.firstNames,
        ref.read(randomProvider),
      );
      state = GameTeams(roster: roster, wasAutoSplit: true);
    } else {
      state = GameTeams(
        roster: _manualRoster(session.firstNames, session.secondNames),
        wasAutoSplit: false,
      );
    }
  }

  /// Újrasorsolja a csapatokat az áttekintőben — csak akkor, ha a keret
  /// auto-splitből jött ([GameTeams.wasAutoSplit]). A keret jelenlegi neveiből
  /// új `DrawTeams`-felosztást készít.
  void redraw() {
    final session = state;
    if (session is! GameTeams || !session.wasAutoSplit) {
      return;
    }
    final names = [for (final player in session.roster.players) player.name];
    final roster = ref.read(drawTeamsProvider)(names, ref.read(randomProvider));
    state = GameTeams(roster: roster, wasAutoSplit: true);
  }

  /// Visszalép az áttekintőből a setupba szerkesztésre: a keret két csapatából
  /// visszaállítja a `firstNames`/`secondNames` listákat.
  void backToSetup() {
    final session = state;
    if (session is! GameTeams) {
      return;
    }
    state = GameSetup(
      firstNames: [for (final player in session.roster.first) player.name],
      secondNames: [for (final player in session.roster.second) player.name],
    );
  }

  /// Elindítja a játékot (KEZDÉS): felépíti a paklit, és megjeleníti az első
  /// kártyát. Csak [GameTeams]-ből hat. A tartalmat a [taskContentProvider]-ből
  /// tölti (offline-first), majd a pakli mögötti sablonokat pillanatképként
  /// rögzíti a session idejére.
  Future<void> start() async {
    final session = state;
    if (session is! GameTeams) {
      return;
    }
    final roster = session.roster;
    if (!roster.isStartable) {
      return;
    }

    final content = await ref.read(taskContentProvider.future);
    final templates = content.templates;
    final random = ref.read(randomProvider);

    final startResult = ref.read(startGameProvider)(templates, roster, random);
    final gameState = switch (startResult) {
      Success(:final value) => value,
      Failure() => throw StateError(
        'NoPlayableTemplates indítható kerettel — a bundled tartalom '
        'séma-tesztjének ezt ki kell zárnia.',
      ),
    };

    final templatesById = {
      for (final template in templates) template.id: template,
    };
    _templatesById = templatesById;

    final drawn = ref.read(drawNextProvider)(
      gameState,
      templatesById,
      ref.read(teamLabelsProvider),
      random,
    );
    state = GamePlaying(state: drawn.state, card: drawn.card, roster: roster);
  }

  /// A következő kártyára léptet. Csak futó játékban ([GamePlaying]) hat.
  void next() {
    final session = state;
    final templatesById = _templatesById;
    if (session is! GamePlaying || templatesById == null) {
      return;
    }
    final drawn = ref.read(drawNextProvider)(
      session.state,
      templatesById,
      ref.read(teamLabelsProvider),
      ref.read(randomProvider),
    );
    state = GamePlaying(
      state: drawn.state,
      card: drawn.card,
      roster: session.roster,
    );
  }

  /// Kilép a futó játékból, és a keret megőrzésével az áttekintőbe tér vissza.
  void quit() {
    final session = state;
    if (session is! GamePlaying) {
      return;
    }
    _templatesById = null;
    state = GameTeams(roster: session.roster, wasAutoSplit: false);
  }

  /// A két névlistából kézi keretet épít: az [first] a [Team.first]-be, a
  /// [second] a [Team.second]-be, változatlan sorrendben.
  Roster _manualRoster(List<String> first, List<String> second) {
    return Roster([
      for (final name in first) Player(name: name, team: Team.first),
      for (final name in second) Player(name: name, team: Team.second),
    ]);
  }
}
