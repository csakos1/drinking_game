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

  group('SlotConstraint értékkészlet', () {
    test('öt megkötés van', () {
      expect(SlotConstraint.values, hasLength(5));
    });
  });
}
