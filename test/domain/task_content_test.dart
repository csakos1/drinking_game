import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/task_content.dart';
import 'package:igyal2/src/domain/task_template.dart';
import 'package:igyal2/src/domain/task_type.dart';

void main() {
  const template = TaskTemplate(
    id: 'jatek-001',
    type: TaskType.jatek,
    constraint: SlotConstraint.anyone,
    playerCount: 1,
    text: '{p1} igyon!',
  );

  group('TaskContent egyenlőség', () {
    test('azonos version és sablonok egyenlők', () {
      const a = TaskContent(version: 1, templates: [template]);
      const b = TaskContent(version: 1, templates: [template]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('eltérő version nem egyenlő', () {
      const a = TaskContent(version: 1, templates: [template]);
      const b = TaskContent(version: 2, templates: [template]);
      expect(a, isNot(b));
    });

    test('eltérő sablonlista-hossz nem egyenlő', () {
      const a = TaskContent(version: 1, templates: [template]);
      const b = TaskContent(version: 1, templates: []);
      expect(a, isNot(b));
    });

    test('eltérő sablon nem egyenlő', () {
      const other = TaskTemplate(
        id: 'masik',
        type: TaskType.parbaj,
        constraint: SlotConstraint.oppositeTeams,
        playerCount: 2,
        text: '{p1} {p2}',
      );
      const a = TaskContent(version: 1, templates: [template]);
      const b = TaskContent(version: 1, templates: [other]);
      expect(a, isNot(b));
    });
  });
}
