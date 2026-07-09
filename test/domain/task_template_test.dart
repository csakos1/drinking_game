import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/task_type.dart';

void main() {
  const base = TaskTemplate(
    id: 'parbaj-003',
    type: TaskType.parbaj,
    constraint: SlotConstraint.oppositeTeams,
    playerCount: 2,
    text: '{p1} és {p2} szkanderezzen!',
  );

  group('TaskTemplate egyenlőség', () {
    test('minden mező azonos esetén egyenlő', () {
      const other = TaskTemplate(
        id: 'parbaj-003',
        type: TaskType.parbaj,
        constraint: SlotConstraint.oppositeTeams,
        playerCount: 2,
        text: '{p1} és {p2} szkanderezzen!',
      );
      expect(base, other);
      expect(base.hashCode, other.hashCode);
    });

    test('eltérő id nem egyenlő', () {
      const other = TaskTemplate(
        id: 'parbaj-004',
        type: TaskType.parbaj,
        constraint: SlotConstraint.oppositeTeams,
        playerCount: 2,
        text: '{p1} és {p2} szkanderezzen!',
      );
      expect(base, isNot(other));
    });

    test('eltérő text nem egyenlő', () {
      const other = TaskTemplate(
        id: 'parbaj-003',
        type: TaskType.parbaj,
        constraint: SlotConstraint.oppositeTeams,
        playerCount: 2,
        text: 'más szöveg',
      );
      expect(base, isNot(other));
    });

    test('eltérő type nem egyenlő', () {
      const other = TaskTemplate(
        id: 'parbaj-003',
        type: TaskType.jatek,
        constraint: SlotConstraint.oppositeTeams,
        playerCount: 2,
        text: '{p1} és {p2} szkanderezzen!',
      );
      expect(base, isNot(other));
    });
  });
}
