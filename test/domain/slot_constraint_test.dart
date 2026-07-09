import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';

void main() {
  group('SlotConstraint.fromSlug', () {
    test('minden ismert slug feloldódik', () {
      for (final constraint in SlotConstraint.values) {
        expect(SlotConstraint.fromSlug(constraint.slug), constraint);
      }
    });

    test('ismeretlen slug null-t ad', () {
      expect(SlotConstraint.fromSlug('valami'), isNull);
    });

    test('a slug case-sensitive', () {
      expect(SlotConstraint.fromSlug('AnyOne'), isNull);
    });
  });

  group('SlotConstraint.isValidPlayerCount', () {
    test('anyone: legalább 1', () {
      expect(SlotConstraint.anyone.isValidPlayerCount(0), isFalse);
      expect(SlotConstraint.anyone.isValidPlayerCount(1), isTrue);
      expect(SlotConstraint.anyone.isValidPlayerCount(5), isTrue);
    });

    test('sameTeam: legalább 2', () {
      expect(SlotConstraint.sameTeam.isValidPlayerCount(1), isFalse);
      expect(SlotConstraint.sameTeam.isValidPlayerCount(2), isTrue);
      expect(SlotConstraint.sameTeam.isValidPlayerCount(3), isTrue);
    });

    test('oppositeTeams: pontosan 2', () {
      expect(SlotConstraint.oppositeTeams.isValidPlayerCount(1), isFalse);
      expect(SlotConstraint.oppositeTeams.isValidPlayerCount(2), isTrue);
      expect(SlotConstraint.oppositeTeams.isValidPlayerCount(3), isFalse);
    });

    test('wholeTeam: pontosan 0', () {
      expect(SlotConstraint.wholeTeam.isValidPlayerCount(0), isTrue);
      expect(SlotConstraint.wholeTeam.isValidPlayerCount(1), isFalse);
    });

    test('everyone: pontosan 0', () {
      expect(SlotConstraint.everyone.isValidPlayerCount(0), isTrue);
      expect(SlotConstraint.everyone.isValidPlayerCount(2), isFalse);
    });

    test('negatív playerCount minden megkötésre érvénytelen', () {
      for (final constraint in SlotConstraint.values) {
        expect(constraint.isValidPlayerCount(-1), isFalse);
      }
    });
  });

  group('SlotConstraint.isSatisfiableBy', () {
    test('anyone: az összlétszám számít', () {
      expect(
        SlotConstraint.anyone.isSatisfiableBy(
          firstTeamSize: 2,
          secondTeamSize: 1,
          playerCount: 3,
        ),
        isTrue,
      );
      expect(
        SlotConstraint.anyone.isSatisfiableBy(
          firstTeamSize: 2,
          secondTeamSize: 1,
          playerCount: 4,
        ),
        isFalse,
      );
    });

    test('sameTeam: a nagyobbik csapat létszáma számít', () {
      expect(
        SlotConstraint.sameTeam.isSatisfiableBy(
          firstTeamSize: 3,
          secondTeamSize: 1,
          playerCount: 3,
        ),
        isTrue,
      );
      expect(
        SlotConstraint.sameTeam.isSatisfiableBy(
          firstTeamSize: 2,
          secondTeamSize: 2,
          playerCount: 3,
        ),
        isFalse,
      );
    });

    test('oppositeTeams: mindkét csapatban kell legalább egy fő', () {
      expect(
        SlotConstraint.oppositeTeams.isSatisfiableBy(
          firstTeamSize: 1,
          secondTeamSize: 1,
          playerCount: 2,
        ),
        isTrue,
      );
      expect(
        SlotConstraint.oppositeTeams.isSatisfiableBy(
          firstTeamSize: 3,
          secondTeamSize: 0,
          playerCount: 2,
        ),
        isFalse,
      );
    });

    test('wholeTeam és everyone mindig játszható', () {
      for (final constraint in [
        SlotConstraint.wholeTeam,
        SlotConstraint.everyone,
      ]) {
        expect(
          constraint.isSatisfiableBy(
            firstTeamSize: 1,
            secondTeamSize: 0,
            playerCount: 0,
          ),
          isTrue,
        );
      }
    });

    test('a két csapatméret szerepe szimmetrikus', () {
      for (final constraint in SlotConstraint.values) {
        final ab = constraint.isSatisfiableBy(
          firstTeamSize: 3,
          secondTeamSize: 1,
          playerCount: 2,
        );
        final ba = constraint.isSatisfiableBy(
          firstTeamSize: 1,
          secondTeamSize: 3,
          playerCount: 2,
        );
        expect(ab, ba, reason: '$constraint nem szimmetrikus');
      }
    });
  });

  group('SlotConstraint értékkészlet', () {
    test('öt megkötés van', () {
      expect(SlotConstraint.values, hasLength(5));
    });
  });
}
