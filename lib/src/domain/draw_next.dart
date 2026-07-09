import 'dart:math';

import 'package:igyal2/src/domain/draw_template.dart';
import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/resolved_card.dart';
import 'package:igyal2/src/domain/select_slot.dart';
import 'package:igyal2/src/domain/slot_selection.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/team.dart';

/// A sablonmotor záró lépése: a következő feloldott kártya előállítása.
///
/// Tiszta use case; a véletlen az injektált [Random]-ból jön. Láncolja a
/// pakli-húzást (`DrawTemplate`), a fair szereplőválasztást (`SelectSlot`) és a
/// placeholder-feloldást, majd a választás típusa szerint lépteti a
/// [GameState] fairness-mezőit (`ARCHITECTURE.md` 5. fejezet, 4. invariáns):
/// a névre feloldódó kártyák növelik a szereplők számlálóját és őket teszik a
/// következő kizárt nevekké; a `wholeTeam`/`everyone` nem növel és üríti a
/// kizárt neveket; a `wholeTeam` rögzíti a csapatot a váltakozáshoz.
///
/// A `DrawTemplate` és a `SelectSlot` tiszta és determinisztikus, ezért inline
/// példányosul (nincs mock-igény, nincs injektálás).
class DrawNext {
  /// Létrehoz egy [DrawNext] use case-t.
  const DrawNext();

  /// A [state] pakliból húz és feloldja a következő kártyát a [random]
  /// segítségével.
  ///
  /// A [templatesById] a húzott id feloldásához kell (a pakli csak id-ket
  /// tárol); a [teamLabels] a `{team}` lokalizált címkéjét adja (a hívótól,
  /// l10n-ből). Visszaadja a feloldott `card`-ot és a léptetett `state`-et.
  ({ResolvedCard card, GameState state}) call(
    GameState state,
    Map<String, TaskTemplate> templatesById,
    Map<Team, String> teamLabels,
    Random random,
  ) {
    const drawTemplate = DrawTemplate();
    final drawn = drawTemplate(state, random);
    final templateId = drawn.templateId;

    // A pakli csak validált id-ket tartalmaz; ha mégsem, az programozói bug
    // (nem várható eset), ezért dobás, nem Result.
    final template = templatesById[templateId];
    assert(
      template != null,
      'A pakliban lévő id nincs a templatesById-ban: $templateId',
    );
    if (template == null) {
      throw StateError('Ismeretlen sablon-id a pakliban: $templateId');
    }

    // A húzás csak a pakli-mezőket léptette; a fairness-mezők még a kártya
    // előtti értéket hordozzák, így a választás helyes bemenetet kap.
    const selectSlot = SelectSlot();
    final selection = selectSlot(
      frame: drawn.state.frame,
      constraint: template.constraint,
      playerCount: template.playerCount,
      appearanceCounts: drawn.state.appearanceCounts,
      excludedNames: drawn.state.previousParticipants,
      lastWholeTeam: drawn.state.lastWholeTeam,
      random: random,
    );

    final card = ResolvedCard(
      templateId: templateId,
      type: template.type,
      text: _resolve(template.text, selection, teamLabels),
    );
    return (card: card, state: _advance(drawn.state, selection));
  }

  String _resolve(
    String text,
    SlotSelection selection,
    Map<Team, String> teamLabels,
  ) {
    return switch (selection) {
      NoSlot() => text,
      TeamSlot(:final team) => text.replaceAll(
        '{team}',
        _labelFor(team, teamLabels),
      ),
      PlayerSlots(:final players) => _resolvePlayers(text, players),
    };
  }

  /// A `{p1}`..`{pN}` tokeneket egyetlen menetben cseréli a nevekre (így egy
  /// névbe ágyazott `{pK}` sem okoz újra-behelyettesítést).
  String _resolvePlayers(String text, List<Player> players) {
    return text.replaceAllMapped(RegExp(r'\{p(\d+)\}'), (match) {
      final digits = match.group(1);
      // A (\d+) csoport a minta illeszkedésekor mindig kötött; a null-ágat
      // explicit kezeljük a ! elkerülésére.
      if (digits == null) {
        return match.group(0) ?? '';
      }
      return players[int.parse(digits) - 1].name;
    });
  }

  String _labelFor(Team team, Map<Team, String> teamLabels) {
    final label = teamLabels[team];
    // A hívó szerződése garantálja a címkét; a fallback csak azt biztosítja,
    // hogy egy hiányzó címke ne állítsa meg a bulit (a domain nem l10n).
    assert(label != null, 'Hiányzó teamLabel: $team');
    return label ?? team.name;
  }

  GameState _advance(GameState state, SlotSelection selection) {
    return switch (selection) {
      // everyone: nincs egyéni számlálás, és utána nincs egyéni kizárás.
      NoSlot() => state.copyWith(previousParticipants: const <String>{}),
      // wholeTeam: nincs egyéni számlálás; a csapat rögzül a váltakozáshoz.
      TeamSlot(:final team) => state.copyWith(
        previousParticipants: const <String>{},
        lastWholeTeam: team,
      ),
      PlayerSlots(:final players) => _advancePlayers(state, players),
    };
  }

  GameState _advancePlayers(GameState state, List<Player> players) {
    final names = [for (final player in players) player.name];
    final counts = {...state.appearanceCounts};
    for (final name in names) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return state.copyWith(
      appearanceCounts: counts,
      previousParticipants: names.toSet(),
    );
  }
}
