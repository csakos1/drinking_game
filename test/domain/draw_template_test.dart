import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/draw_template.dart';
import 'package:igyal2/src/domain/game_state.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/start_game.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/task_type.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  const startGame = StartGame();
  const draw = DrawTemplate();

  // masterSize darab, mindig játszható (anyone/1) sablonból álló kezdőállapot.
  // Így a pakli-mechanika elkülönül a szűréstől (azt a StartGame teszt fedi).
  GameState startState({required int masterSize, required int seed}) {
    final templates = [
      for (var i = 0; i < masterSize; i++)
        TaskTemplate(
          id: 'c$i',
          type: TaskType.jatek,
          constraint: SlotConstraint.anyone,
          playerCount: 1,
          text: '{p1}',
        ),
    ];
    const roster = Roster([
      Player(name: 'A', team: Team.first),
      Player(name: 'B', team: Team.second),
    ]);
    final result = startGame(templates, roster, Random(seed));
    return switch (result) {
      Success(:final value) => value,
      Failure() => fail('startState: váratlan Failure.'),
    };
  }

  // n kártyát húz, végigfűzve az állapotot; visszaadja a húzott id-ket.
  List<String> drawN(GameState start, Random random, int n) {
    var state = start;
    final ids = <String>[];
    for (var i = 0; i < n; i++) {
      final result = draw(state, random);
      ids.add(result.templateId);
      state = result.state;
    }
    return ids;
  }

  group('DrawTemplate egy húzás', () {
    test('a sor elejéről húz, és lépteti az állapotot', () {
      final state = startState(masterSize: 3, seed: 1);
      final expectedFirst = state.remaining.first;
      final result = draw(state, Random(1));
      expect(result.templateId, expectedFirst);
      expect(result.state.remaining, hasLength(2));
      expect(result.state.lastTemplateId, expectedFirst);
    });
  });

  group('DrawTemplate egy paklinyi húzás', () {
    test('egy passz a teljes mestert kiadja, ismétlés nélkül', () {
      final state = startState(masterSize: 5, seed: 2);
      final ids = drawN(state, Random(2), 5);
      expect(ids.toSet(), state.playableIds.toSet());
      expect(ids, hasLength(5));
    });

    test('kimerülés után újrakeveredik egy teljes passz', () {
      final state = startState(masterSize: 4, seed: 3);
      final ids = drawN(state, Random(3), 8);
      expect(ids.sublist(0, 4).toSet(), state.playableIds.toSet());
      expect(ids.sublist(4, 8).toSet(), state.playableIds.toSet());
    });
  });

  group('DrawTemplate ismétlés-tilalom', () {
    test('m>1: nincs két egymást követő azonos kártya (a határon sem)', () {
      for (var seed = 0; seed < 20; seed++) {
        final state = startState(masterSize: 4, seed: seed);
        final ids = drawN(state, Random(seed + 100), 20);
        for (var i = 1; i < ids.length; i++) {
          expect(ids[i], isNot(ids[i - 1]), reason: 'seed=$seed, i=$i');
        }
      }
    });

    test('m==1: nincs alternatíva, a kártya ismétlődhet', () {
      final state = startState(masterSize: 1, seed: 1);
      final ids = drawN(state, Random(1), 3);
      expect(ids.toSet(), hasLength(1));
      expect(ids, hasLength(3));
    });
  });

  group('DrawTemplate determinizmus', () {
    test('azonos seedek → azonos húzási sorrend', () {
      final ids1 = drawN(startState(masterSize: 5, seed: 7), Random(9), 15);
      final ids2 = drawN(startState(masterSize: 5, seed: 7), Random(9), 15);
      expect(ids1, ids2);
    });
  });
}
