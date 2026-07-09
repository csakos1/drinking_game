import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/select_slot.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/slot_selection.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  const select = SelectSlot();

  List<Player> makeFrame(List<String> firstNames, List<String> secondNames) {
    return [
      for (final name in firstNames) Player(name: name, team: Team.first),
      for (final name in secondNames) Player(name: name, team: Team.second),
    ];
  }

  // Kényelmi hívó alapértelmezésekkel, hogy a tesztek rövidek maradjanak.
  SlotSelection choose({
    required List<Player> frame,
    required SlotConstraint constraint,
    required int playerCount,
    required Random random,
    Map<String, int> appearanceCounts = const {},
    Set<String> excludedNames = const {},
    Team? lastWholeTeam,
  }) {
    return select(
      frame: frame,
      constraint: constraint,
      playerCount: playerCount,
      appearanceCounts: appearanceCounts,
      excludedNames: excludedNames,
      lastWholeTeam: lastWholeTeam,
      random: random,
    );
  }

  List<Player> playersOf(SlotSelection selection) {
    return switch (selection) {
      PlayerSlots(:final players) => players,
      _ => fail('PlayerSlots-ot vártunk, kaptunk: $selection'),
    };
  }

  Team teamOf(SlotSelection selection) {
    return switch (selection) {
      TeamSlot(:final team) => team,
      _ => fail('TeamSlot-ot vártunk, kaptunk: $selection'),
    };
  }

  group('SelectSlot megkötés-irányítás', () {
    final frame = makeFrame(['A', 'B'], ['C', 'D']);

    test('everyone → NoSlot', () {
      expect(
        choose(
          frame: frame,
          constraint: SlotConstraint.everyone,
          playerCount: 0,
          random: Random(1),
        ),
        isA<NoSlot>(),
      );
    });

    test('wholeTeam → TeamSlot', () {
      expect(
        choose(
          frame: frame,
          constraint: SlotConstraint.wholeTeam,
          playerCount: 0,
          random: Random(1),
        ),
        isA<TeamSlot>(),
      );
    });

    test('anyone → a playerCount-nak megfelelő számú, különböző slot', () {
      final players = playersOf(
        choose(
          frame: frame,
          constraint: SlotConstraint.anyone,
          playerCount: 2,
          random: Random(1),
        ),
      );
      expect(players, hasLength(2));
      expect(players.map((p) => p.name).toSet(), hasLength(2));
    });
  });

  group('SelectSlot sameTeam', () {
    test('minden slot ugyanabból a csapatból', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      for (var seed = 0; seed < 100; seed++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.sameTeam,
            playerCount: 2,
            random: Random(seed),
          ),
        );
        expect(players.map((p) => p.team).toSet(), hasLength(1));
      }
    });

    test('csak a playerCount-ot kielégítő csapatból választ', () {
      // first=3, second=1, playerCount=3 → csak az első csapat jöhet.
      final frame = makeFrame(['A', 'B', 'C'], ['D']);
      for (var seed = 0; seed < 100; seed++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.sameTeam,
            playerCount: 3,
            random: Random(seed),
          ),
        );
        expect(players.map((p) => p.team).toSet(), {Team.first});
        expect(players, hasLength(3));
      }
    });
  });

  group('SelectSlot oppositeTeams', () {
    test('egy-egy fő két különböző csapatból, {p1} csapata véletlen', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      final firstSlotTeams = <Team>{};
      for (var seed = 0; seed < 100; seed++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.oppositeTeams,
            playerCount: 2,
            random: Random(seed),
          ),
        );
        expect(players, hasLength(2));
        expect(players[0].team, isNot(players[1].team));
        firstSlotTeams.add(players[0].team);
      }
      expect(firstSlotTeams, {Team.first, Team.second});
    });
  });

  group('SelectSlot közvetlen ismétlés kizárása', () {
    test('anyone: elég jelölt esetén a kizárt név sosem jön', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      for (var seed = 0; seed < 200; seed++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.anyone,
            playerCount: 2,
            excludedNames: const {'A'},
            random: Random(seed),
          ),
        );
        expect(players.map((p) => p.name), isNot(contains('A')));
      }
    });

    test('1v1 oppositeTeams: mindkettő kizárva → a kizárás feloldódik', () {
      final frame = makeFrame(['A'], ['B']);
      for (var seed = 0; seed < 50; seed++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.oppositeTeams,
            playerCount: 2,
            excludedNames: const {'A', 'B'},
            random: Random(seed),
          ),
        );
        expect(players.map((p) => p.name).toSet(), {'A', 'B'});
      }
    });
  });

  group('SelectSlot wholeTeam váltakozás', () {
    final frame = makeFrame(['A'], ['B']);

    test('előző first → most second', () {
      expect(
        teamOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.wholeTeam,
            playerCount: 0,
            lastWholeTeam: Team.first,
            random: Random(1),
          ),
        ),
        Team.second,
      );
    });

    test('előző second → most first', () {
      expect(
        teamOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.wholeTeam,
            playerCount: 0,
            lastWholeTeam: Team.second,
            random: Random(1),
          ),
        ),
        Team.first,
      );
    });

    test('nincs előző → mindkét csapat előfordul', () {
      final teams = <Team>{};
      for (var seed = 0; seed < 50; seed++) {
        teams.add(
          teamOf(
            choose(
              frame: frame,
              constraint: SlotConstraint.wholeTeam,
              playerCount: 0,
              random: Random(seed),
            ),
          ),
        );
      }
      expect(teams, {Team.first, Team.second});
    });
  });

  group('SelectSlot súlyozott eloszlás', () {
    test('egyenlő számlálóknál az eloszlás közel egyenletes', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      final tally = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      final random = Random(12345);
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.anyone,
            playerCount: 1,
            random: random,
          ),
        );
        tally.update(players.single.name, (value) => value + 1);
      }
      for (final count in tally.values) {
        expect(count, greaterThan(750));
        expect(count, lessThan(1250));
      }
    });

    test('nagy megjelenésszámú játékos jóval ritkábban jön', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      final tally = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      final random = Random(777);
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final players = playersOf(
          choose(
            frame: frame,
            constraint: SlotConstraint.anyone,
            playerCount: 1,
            appearanceCounts: const {'A': 99},
            random: random,
          ),
        );
        tally.update(players.single.name, (value) => value + 1);
      }
      expect(tally['A'], lessThan(100));
      expect(tally['B'], greaterThan(700));
      expect(tally['C'], greaterThan(700));
      expect(tally['D'], greaterThan(700));
    });
  });

  group('SelectSlot determinizmus', () {
    test('azonos seed és bemenet → azonos választás', () {
      final frame = makeFrame(['A', 'B'], ['C', 'D']);
      final a = choose(
        frame: frame,
        constraint: SlotConstraint.anyone,
        playerCount: 2,
        appearanceCounts: const {'A': 3},
        random: Random(42),
      );
      final b = choose(
        frame: frame,
        constraint: SlotConstraint.anyone,
        playerCount: 2,
        appearanceCounts: const {'A': 3},
        random: Random(42),
      );
      expect(a, b);
    });
  });
}
