import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/player.dart';
import 'package:igyal2/src/domain/slot_selection.dart';
import 'package:igyal2/src/domain/team.dart';

void main() {
  const a = Player(name: 'A', team: Team.first);
  const b = Player(name: 'B', team: Team.second);

  group('PlayerSlots', () {
    test('azonos játékosok azonos sorrendben egyenlők, hashCode is', () {
      expect(const PlayerSlots([a, b]), const PlayerSlots([a, b]));
      expect(
        const PlayerSlots([a, b]).hashCode,
        const PlayerSlots([a, b]).hashCode,
      );
    });

    test('eltérő sorrend nem egyenlő', () {
      expect(const PlayerSlots([a, b]), isNot(const PlayerSlots([b, a])));
    });

    test('eltérő hossz nem egyenlő', () {
      expect(const PlayerSlots([a]), isNot(const PlayerSlots([a, b])));
    });
  });

  group('TeamSlot', () {
    test('azonos csapat egyenlő, hashCode is', () {
      expect(const TeamSlot(Team.first), const TeamSlot(Team.first));
      expect(
        const TeamSlot(Team.first).hashCode,
        const TeamSlot(Team.first).hashCode,
      );
    });

    test('eltérő csapat nem egyenlő', () {
      expect(const TeamSlot(Team.first), isNot(const TeamSlot(Team.second)));
    });
  });

  group('NoSlot', () {
    test('minden NoSlot egyenlő', () {
      expect(const NoSlot(), const NoSlot());
    });

    test('NoSlot nem egyenlő más ággal', () {
      expect(const NoSlot(), isNot(const TeamSlot(Team.first)));
    });
  });
}
