import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igyal2/src/application/content_providers.dart';
import 'package:igyal2/src/application/game_session.dart';
import 'package:igyal2/src/domain/draw_next.dart';
import 'package:igyal2/src/domain/draw_teams.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/result.dart';
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

/// A játék-session állapotgépe: a setup ↔ futó játék átmeneteket vezérli.
final gameSessionProvider = NotifierProvider<GameSessionNotifier, GameSession>(
  GameSessionNotifier.new,
);

/// A [GameSession] állapotát kezelő `Notifier`.
///
/// A setup-műveletek (név hozzáadása/törlése, sorsolás, kézi korrekció) a
/// [GameSetup]-ot léptetik; az [start] a `StartGame`→`DrawNext` láncot futtatja
/// és [GamePlaying]-re vált; a [next] lépteti a kártyát; a [quit] a keret
/// megőrzésével visszatér a setup-ba. A véletlen és a use case-ek providerekből
/// jönnek, így tesztben felülírhatók.
class GameSessionNotifier extends Notifier<GameSession> {
  /// A futó játékhoz tartozó sablon-térkép (id → sablon), az [start]-nál
  /// pillanatképként rögzítve, hogy egy háttér-tartalomfrissítés ne cserélje ki
  /// a pakli mögötti sablonokat menet közben. A notifier élettartamával együtt
  /// nullázódik.
  Map<String, TaskTemplate>? _templatesById;

  @override
  GameSession build() => const GameSetup(names: []);

  /// Hozzáad egy nevet a setup-listához (trimmelve). Üres vagy már meglévő
  /// nevet figyelmen kívül hagy. A névlista változása üríti a sorsolt keretet.
  void addName(String name) {
    final session = state;
    if (session is! GameSetup) {
      return;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty || session.names.contains(trimmed)) {
      return;
    }
    state = GameSetup(names: [...session.names, trimmed]);
  }

  /// Töröl egy nevet a setup-listából. A névlista változása üríti a sorsolt
  /// keretet.
  void removeName(String name) {
    final session = state;
    if (session is! GameSetup || !session.names.contains(name)) {
      return;
    }
    state = GameSetup(names: [...session.names]..remove(name));
  }

  /// Két csapatba sorsolja a jelenlegi neveket. Legalább két név kell hozzá.
  void drawTeams() {
    final session = state;
    if (session is! GameSetup || session.names.length < 2) {
      return;
    }
    final roster = ref.read(drawTeamsProvider)(
      session.names,
      ref.read(randomProvider),
    );
    state = GameSetup(names: session.names, roster: roster);
  }

  /// A [player] átmozgatása a másik csapatba (kézi korrekció). Sorsolt keret
  /// nélkül nincs hatása.
  void moveToOtherTeam(Player player) {
    final session = state;
    if (session is! GameSetup) {
      return;
    }
    final roster = session.roster;
    if (roster == null) {
      return;
    }
    state = GameSetup(
      names: session.names,
      roster: roster.moveToOtherTeam(player),
    );
  }

  /// Elindítja a játékot: felépíti a paklit, és megjeleníti az első kártyát.
  ///
  /// Csak indítható keretből ([GameSetup.canStart]) hat. A tartalmat a
  /// [taskContentProvider]-ből tölti (offline-first, gyors, lokális), majd a
  /// pakli mögötti sablonokat pillanatképként rögzíti a session idejére.
  Future<void> start() async {
    final session = state;
    if (session is! GameSetup) {
      return;
    }
    final roster = session.roster;
    if (roster == null || !roster.isStartable) {
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

  /// Kilép a futó játékból, és a keret megőrzésével visszatér a setup-ba.
  void quit() {
    final session = state;
    if (session is! GamePlaying) {
      return;
    }
    _templatesById = null;
    state = GameSetup(
      names: [for (final player in session.roster.players) player.name],
      roster: session.roster,
    );
  }
}
