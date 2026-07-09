import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/roster.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  Roster rosterOf(Map<String, Team> assignments) {
    return Roster([
      for (final entry in assignments.entries) Player(name: entry.key, team: entry.value),
    ]);
  }

  group('Roster csapatnézetek', () {
    test('first és second a csapat szerint szűr, sorrendtartóan', () {
      final roster = rosterOf({
        'Anna': Team.first,
        'Béla': Team.second,
        'Csaba': Team.first,
      });
      expect(roster.first.map((p) => p.name), ['Anna', 'Csaba']);
      expect(roster.second.map((p) => p.name), ['Béla']);
    });

    test('firstCount és secondCount a létszámot adja', () {
      final roster = rosterOf({
        'Anna': Team.first,
        'Béla': Team.second,
        'Csaba': Team.first,
      });
      expect(roster.firstCount, 2);
      expect(roster.secondCount, 1);
    });
  });

  group('Roster.isStartable', () {
    test('mindkét csapatban van fő → indítható', () {
      final roster = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      expect(roster.isStartable, isTrue);
    });

    test('üres második csapat → nem indítható', () {
      final roster = rosterOf({'Anna': Team.first, 'Béla': Team.first});
      expect(roster.isStartable, isFalse);
    });

    test('üres első csapat → nem indítható', () {
      final roster = rosterOf({'Anna': Team.second, 'Béla': Team.second});
      expect(roster.isStartable, isFalse);
    });
  });

  group('Roster.moveToOtherTeam', () {
    test('a játékost a másik csapatba billenti', () {
      final roster = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      final moved = roster.moveToOtherTeam(
        const Player(name: 'Anna', team: Team.first),
      );
      expect(moved.firstCount, 0);
      expect(moved.secondCount, 2);
    });

    test('csak a megnevezett játékost mozgatja, a többit nem', () {
      final roster = rosterOf({
        'Anna': Team.first,
        'Béla': Team.first,
        'Csaba': Team.second,
      });
      final moved = roster.moveToOtherTeam(
        const Player(name: 'Béla', team: Team.first),
      );
      expect(moved.first.map((p) => p.name), ['Anna']);
      expect(moved.second.map((p) => p.name).toSet(), {'Béla', 'Csaba'});
    });

    test('a sorrend megőrződik', () {
      final roster = rosterOf({
        'Anna': Team.first,
        'Béla': Team.second,
        'Csaba': Team.first,
      });
      final moved = roster.moveToOtherTeam(
        const Player(name: 'Béla', team: Team.second),
      );
      expect(moved.players.map((p) => p.name), ['Anna', 'Béla', 'Csaba']);
    });

    test('nem módosítja az eredeti rostert (immutable)', () {
      final roster = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      final moved = roster.moveToOtherTeam(
        const Player(name: 'Anna', team: Team.first),
      );
      expect(roster.firstCount, 1);
      expect(roster.secondCount, 1);
      expect(moved, isNot(roster));
    });

    test('ismeretlen név esetén assert-el elhasal (debug)', () {
      final roster = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      expect(
        () => roster.moveToOtherTeam(
          const Player(name: 'Zoltán', team: Team.first),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Roster egyenlőség', () {
    test('azonos játékosok azonos sorrendben egyenlők', () {
      final a = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      final b = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('eltérő csapatbeosztás nem egyenlő', () {
      final a = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      final b = rosterOf({'Anna': Team.second, 'Béla': Team.first});
      expect(a, isNot(b));
    });

    test('eltérő létszám nem egyenlő', () {
      final a = rosterOf({'Anna': Team.first, 'Béla': Team.second});
      final b = rosterOf({'Anna': Team.first});
      expect(a, isNot(b));
    });
  });
}
