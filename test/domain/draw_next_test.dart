import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/draw_next.dart';
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
  const drawNext = DrawNext();
  const labels = {Team.first: 'piros', Team.second: 'kék'};
  final placeholder = RegExp(r'\{[^}]*\}');

  List<Player> makeFrame(List<String> firstNames, List<String> secondNames) {
    return [
      for (final name in firstNames) Player(name: name, team: Team.first),
      for (final name in secondNames) Player(name: name, team: Team.second),
    ];
  }

  TaskTemplate template(
    String id,
    SlotConstraint constraint,
    int playerCount,
    String text,
  ) {
    return TaskTemplate(
      id: id,
      type: TaskType.jatek,
      constraint: constraint,
      playerCount: playerCount,
      text: text,
    );
  }

  Map<String, TaskTemplate> byId(List<TaskTemplate> templates) {
    return {for (final t in templates) t.id: t};
  }

  GameState startWith(List<TaskTemplate> templates, List<Player> frame, int s) {
    final result = const StartGame()(templates, Roster(frame), Random(s));
    return switch (result) {
      Success(:final value) => value,
      Failure() => fail('StartGame váratlan Failure.'),
    };
  }

  group('DrawNext feloldás', () {
    test('anyone: {p1}/{p2} nevekre oldódik, nem marad placeholder', () {
      final templates = [template('a', SlotConstraint.anyone, 2, '{p1} és {p2}')];
      final frame = makeFrame(['Anna', 'Béla'], ['Csaba', 'Dóra']);
      final result = drawNext(
        startWith(templates, frame, 1),
        byId(templates),
        labels,
        Random(1),
      );
      expect(placeholder.hasMatch(result.card.text), isFalse);
      final names = frame.map((p) => p.name).toSet();
      for (final participant in result.state.previousParticipants) {
        expect(names, contains(participant));
        expect(result.card.text, contains(participant));
      }
    });

    test('wholeTeam: {team} a címkére oldódik', () {
      final templates = [
        template('w', SlotConstraint.wholeTeam, 0, 'A {team} igyon'),
      ];
      final frame = makeFrame(['Anna'], ['Béla']);
      final result = drawNext(
        startWith(templates, frame, 1),
        byId(templates),
        labels,
        Random(1),
      );
      expect(placeholder.hasMatch(result.card.text), isFalse);
      expect(['A piros igyon', 'A kék igyon'], contains(result.card.text));
    });

    test('everyone: a szöveg érintetlen', () {
      final templates = [
        template('e', SlotConstraint.everyone, 0, 'Mindenki igyon'),
      ];
      final result = drawNext(
        startWith(templates, makeFrame(['Anna'], ['Béla']), 1),
        byId(templates),
        labels,
        Random(1),
      );
      expect(result.card.text, 'Mindenki igyon');
    });
  });

  group('DrawNext állapot-léptetés', () {
    final frame = makeFrame(['Anna', 'Béla'], ['Csaba', 'Dóra']);

    test('anyone növeli a szereplők számlálóját és kizárja őket', () {
      final templates = [template('a', SlotConstraint.anyone, 2, '{p1} {p2}')];
      final result = drawNext(
        startWith(templates, frame, 1),
        byId(templates),
        labels,
        Random(1),
      );
      final participants = result.state.previousParticipants;
      expect(participants, hasLength(2));
      for (final name in participants) {
        expect(result.state.appearanceCounts[name], 1);
      }
    });

    test('wholeTeam nem növel, üríti a kizártakat, rögzíti a csapatot', () {
      final templates = [
        template('w', SlotConstraint.wholeTeam, 0, 'A {team}'),
      ];
      final result = drawNext(
        startWith(templates, frame, 1),
        byId(templates),
        labels,
        Random(1),
      );
      expect(result.state.appearanceCounts, isEmpty);
      expect(result.state.previousParticipants, isEmpty);
      expect(result.state.lastWholeTeam, isNotNull);
    });

    test('everyone nem növel és üríti a kizártakat', () {
      final templates = [
        template('e', SlotConstraint.everyone, 0, 'Mindenki'),
      ];
      final result = drawNext(
        startWith(templates, frame, 1),
        byId(templates),
        labels,
        Random(1),
      );
      expect(result.state.appearanceCounts, isEmpty);
      expect(result.state.previousParticipants, isEmpty);
      expect(result.state.lastWholeTeam, isNull);
    });
  });

  group('DrawNext wholeTeam váltakozás (részsorozat)', () {
    test('egymást követő wholeTeam-kártyák különböző csapatra esnek', () {
      final templates = [
        template('w1', SlotConstraint.wholeTeam, 0, 'A {team}'),
        template('w2', SlotConstraint.wholeTeam, 0, 'A {team} igyon'),
        template('a1', SlotConstraint.anyone, 1, '{p1}'),
        template('a2', SlotConstraint.anyone, 1, '{p1} igyál'),
      ];
      final map = byId(templates);
      final frame = makeFrame(['Anna', 'Béla'], ['Csaba', 'Dóra']);
      for (var seed = 0; seed < 30; seed++) {
        var state = startWith(templates, frame, seed);
        final random = Random(seed + 500);
        Team? lastWholeTeam;
        for (var i = 0; i < 40; i++) {
          final result = drawNext(state, map, labels, random);
          final constraint = map[result.card.templateId]?.constraint;
          if (constraint == SlotConstraint.wholeTeam) {
            final team = result.state.lastWholeTeam;
            if (lastWholeTeam != null) {
              expect(team, isNot(lastWholeTeam), reason: 'seed=$seed');
            }
            lastWholeTeam = team;
          }
          state = result.state;
        }
      }
    });
  });

  group('DrawNext közvetlen ismétlés', () {
    test('anyone/1: egymást követő kártyák nem ismétlik a szereplőt', () {
      final templates = [
        for (var i = 0; i < 5; i++) template('a$i', SlotConstraint.anyone, 1, '{p1}'),
      ];
      final map = byId(templates);
      final frame = makeFrame(['Anna', 'Béla'], ['Csaba', 'Dóra']);
      var state = startWith(templates, frame, 1);
      final random = Random(9);
      String? previous;
      for (var i = 0; i < 30; i++) {
        final result = drawNext(state, map, labels, random);
        final name = result.state.previousParticipants.single;
        if (previous != null) {
          expect(name, isNot(previous));
        }
        previous = name;
        state = result.state;
      }
    });
  });

  group('DrawNext determinizmus és hiba', () {
    test('azonos seed → azonos kártyaszöveg-sorozat', () {
      final templates = [
        template('a', SlotConstraint.anyone, 2, '{p1} és {p2}'),
        template('w', SlotConstraint.wholeTeam, 0, 'A {team}'),
        template('e', SlotConstraint.everyone, 0, 'Mindenki'),
      ];
      final map = byId(templates);
      final frame = makeFrame(['Anna', 'Béla'], ['Csaba', 'Dóra']);

      List<String> run() {
        var state = startWith(templates, frame, 7);
        final random = Random(11);
        final texts = <String>[];
        for (var i = 0; i < 20; i++) {
          final result = drawNext(state, map, labels, random);
          texts.add(result.card.text);
          state = result.state;
        }
        return texts;
      }

      expect(run(), run());
    });

    test('ismeretlen sablon-id → assert (debug)', () {
      const state = GameState(
        frame: [
          Player(name: 'Anna', team: Team.first),
          Player(name: 'Béla', team: Team.second),
        ],
        playableIds: ['x'],
        remaining: ['x'],
        lastTemplateId: null,
      );
      expect(
        () => drawNext(state, const <String, TaskTemplate>{}, labels, Random(1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
