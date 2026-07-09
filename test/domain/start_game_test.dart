import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/start_game.dart';
import 'package:igyal2/src/domain/start_game_error.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/task_type.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  const startGame = StartGame();

  TaskTemplate template(
    String id,
    SlotConstraint constraint,
    int playerCount,
  ) {
    return TaskTemplate(
      id: id,
      type: TaskType.jatek,
      constraint: constraint,
      playerCount: playerCount,
      text: 'nem számít a pakli-szinten',
    );
  }

  // firstSize játékos az első, secondSize a második csapatba.
  Roster roster(int firstSize, int secondSize) {
    return Roster([
      for (var i = 0; i < firstSize; i++) Player(name: 'A$i', team: Team.first),
      for (var i = 0; i < secondSize; i++) Player(name: 'B$i', team: Team.second),
    ]);
  }

  GameState successValue(Result<GameState, StartGameError> result) {
    return switch (result) {
      Success(:final value) => value,
      Failure() => fail('Success-t vártunk.'),
    };
  }

  group('StartGame happy path', () {
    test('minden játszható sablon a pakliba kerül', () {
      final templates = [
        template('anyone-1', SlotConstraint.anyone, 1),
        template('opp-1', SlotConstraint.oppositeTeams, 2),
        template('every-1', SlotConstraint.everyone, 0),
      ];
      final state = successValue(
        startGame(templates, roster(2, 2), Random(1)),
      );
      expect(state.playableIds.toSet(), {'anyone-1', 'opp-1', 'every-1'});
      expect(state.remaining.toSet(), state.playableIds.toSet());
      expect(state.remaining, hasLength(3));
      expect(state.lastTemplateId, isNull);
    });

    test('a keret a frame-be kerül', () {
      final state = successValue(
        startGame(
          [template('anyone-1', SlotConstraint.anyone, 1)],
          roster(1, 1),
          Random(1),
        ),
      );
      expect(state.frame, hasLength(2));
      expect(state.frame.map((p) => p.name).toSet(), {'A0', 'B0'});
    });
  });

  group('StartGame játszhatósági szűrés', () {
    test('a kerettel nem játszható sablon kimarad', () {
      final templates = [
        template('anyone-1', SlotConstraint.anyone, 1),
        // sameTeam 3 fő: a legnagyobb csapat itt csak 2 → kimarad.
        template('same-3', SlotConstraint.sameTeam, 3),
      ];
      final state = successValue(
        startGame(templates, roster(2, 2), Random(1)),
      );
      expect(state.playableIds, ['anyone-1']);
    });

    test('egyetlen sablon sem játszható → NoPlayableTemplates', () {
      final templates = [
        template('anyone-big', SlotConstraint.anyone, 10),
      ];
      final result = startGame(templates, roster(1, 1), Random(1));
      final error = switch (result) {
        Success() => fail('Failure-t vártunk.'),
        Failure(:final error) => error,
      };
      expect(error, isA<NoPlayableTemplates>());
    });
  });

  group('StartGame determinizmus és előfeltétel', () {
    test('azonos seed → azonos húzási sor', () {
      final templates = [
        for (var i = 0; i < 6; i++) template('c$i', SlotConstraint.anyone, 1),
      ];
      final a = successValue(startGame(templates, roster(1, 1), Random(9)));
      final b = successValue(startGame(templates, roster(1, 1), Random(9)));
      expect(a.remaining, b.remaining);
    });

    test('nem indítható keret → assert', () {
      final templates = [template('anyone-1', SlotConstraint.anyone, 1)];
      expect(
        () => startGame(templates, roster(2, 0), Random(1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
