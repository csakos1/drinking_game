import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/draw_teams.dart';

void main() {
  const draw = DrawTeams();

  List<String> namesOf(int n) => [for (var i = 0; i < n; i++) 'J$i'];

  group('DrawTeams alap felosztás', () {
    test('1v1 minimum: mindkét csapat pontosan egy fő', () {
      final roster = draw(['Anna', 'Béla'], Random(1));
      expect(roster.firstCount, 1);
      expect(roster.secondCount, 1);
    });

    test('páros létszám: egyenlő felosztás', () {
      final roster = draw(namesOf(6), Random(1));
      expect(roster.firstCount, 3);
      expect(roster.secondCount, 3);
    });

    test('minden nevet pontosan egyszer oszt ki', () {
      final names = namesOf(7);
      final roster = draw(names, Random(1));
      expect(roster.players.map((p) => p.name).toSet(), names.toSet());
      expect(roster.players, hasLength(names.length));
    });
  });

  group('⌈n/2⌉ / ⌊n/2⌋ garancia', () {
    test('a csapatlétszámok legfeljebb eggyel térnek el és kiadják n-t', () {
      for (var n = 2; n <= 21; n++) {
        for (var seed = 0; seed < 8; seed++) {
          final roster = draw(namesOf(n), Random(seed));
          expect(roster.firstCount + roster.secondCount, n);
          final diff = (roster.firstCount - roster.secondCount).abs();
          expect(diff, lessThanOrEqualTo(1));
        }
      }
    });

    test('páros n-nél nincs eltérés', () {
      final roster = draw(namesOf(8), Random(5));
      expect(roster.firstCount, roster.secondCount);
    });

    test('páratlan n-nél pontosan eggyel tér el', () {
      final roster = draw(namesOf(5), Random(3));
      expect((roster.firstCount - roster.secondCount).abs(), 1);
    });
  });

  group('a nagyobbik fél csapata véletlen (páratlan létszám)', () {
    test('különböző seedekkel mindkét csapat kaphatja a plusz főt', () {
      final observedFirstCounts = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        observedFirstCounts.add(draw(namesOf(5), Random(seed)).firstCount);
      }
      // n=5 → a felosztás {2, 3}; hosszú távon mindkét irány előfordul.
      expect(observedFirstCounts, containsAll(<int>[2, 3]));
    });
  });

  group('determinizmus', () {
    test('azonos seed → azonos roster', () {
      final a = draw(namesOf(9), Random(42));
      final b = draw(namesOf(9), Random(42));
      expect(a, b);
    });

    test('újrasorsolás ugyanazzal a Random-mal érvényes keretet ad', () {
      final random = Random(7);
      final first = draw(namesOf(8), random);
      final second = draw(namesOf(8), random);
      final firstNames = first.players.map((p) => p.name).toSet();
      final secondNames = second.players.map((p) => p.name).toSet();
      // A keret ugyanaz; a felosztás lehet más, de mindkettő indítható.
      expect(firstNames, secondNames);
      expect(first.isStartable, isTrue);
      expect(second.isStartable, isTrue);
    });
  });

  group('előfeltételek (assert)', () {
    test('kettőnél kevesebb név → assert', () {
      expect(() => draw(['Anna'], Random(1)), throwsA(isA<AssertionError>()));
    });

    test('duplikált név → assert', () {
      expect(
        () => draw(['Anna', 'Anna'], Random(1)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('üres név → assert', () {
      expect(
        () => draw(['Anna', '  '], Random(1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
