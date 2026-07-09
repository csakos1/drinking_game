import 'dart:math';

import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/start_game_error.dart';
import 'package:igyal2/src/domain/task_template.dart';

/// A játék indítása: a kezdő [GameState] (pakli) felépítése.
///
/// Tiszta use case, a véletlen az injektált [Random]-ból jön. A [call] a
/// kerettel játszható sablonokat szűri ki (a `SlotConstraint.isSatisfiableBy`
/// szabályai szerint), az id-kből fix mestert képez, majd ezt megkeverve adja
/// a kezdő húzási sort. Ha egyetlen sablon sem játszható, [Failure]
/// [NoPlayableTemplates]-szel — a pakli-mechanika ilyenkor nem indulhat.
class StartGame {
  /// Létrehoz egy [StartGame] use case-t.
  const StartGame();

  /// A [templates] validált sablonokból és a [roster] keretből felépíti a
  /// kezdő [GameState]-et a [random] segítségével.
  ///
  /// Előfeltétel (a setup garantálja, ezért `assert`): a [roster] indítható
  /// (mindkét csapatban ≥ 1 fő). A sablonok forrás-agnosztikusak és már
  /// validáltak (a data-réteg állítja elő őket).
  Result<GameState, StartGameError> call(
    List<TaskTemplate> templates,
    Roster roster,
    Random random,
  ) {
    assert(
      roster.isStartable,
      'Csak indítható kerettel hívható (mindkét csapatban ≥ 1 fő); a setup '
      'garantálja.',
    );

    final firstSize = roster.firstCount;
    final secondSize = roster.secondCount;

    final playableIds = <String>[
      for (final template in templates)
        if (template.constraint.isSatisfiableBy(
          firstTeamSize: firstSize,
          secondTeamSize: secondSize,
          playerCount: template.playerCount,
        ))
          template.id,
    ];

    if (playableIds.isEmpty) {
      return const Failure(NoPlayableTemplates());
    }

    final remaining = [...playableIds]..shuffle(random);

    return Success(
      GameState(
        frame: [...roster.players],
        playableIds: playableIds,
        remaining: remaining,
        lastTemplateId: null,
      ),
    );
  }
}
