import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/resolved_card.dart';
import 'package:igyal2/src/domain/task_type.dart';

void main() {
  const base = ResolvedCard(
    templateId: 'jatek-001',
    type: TaskType.jatek,
    text: 'Anna igyon!',
  );

  group('ResolvedCard egyenlőség', () {
    test('minden mező azonos → egyenlő, hashCode is', () {
      const other = ResolvedCard(
        templateId: 'jatek-001',
        type: TaskType.jatek,
        text: 'Anna igyon!',
      );
      expect(base, other);
      expect(base.hashCode, other.hashCode);
    });

    test('eltérő text nem egyenlő', () {
      const other = ResolvedCard(
        templateId: 'jatek-001',
        type: TaskType.jatek,
        text: 'Béla igyon!',
      );
      expect(base, isNot(other));
    });

    test('eltérő type nem egyenlő', () {
      const other = ResolvedCard(
        templateId: 'jatek-001',
        type: TaskType.parbaj,
        text: 'Anna igyon!',
      );
      expect(base, isNot(other));
    });

    test('eltérő templateId nem egyenlő', () {
      const other = ResolvedCard(
        templateId: 'jatek-002',
        type: TaskType.jatek,
        text: 'Anna igyon!',
      );
      expect(base, isNot(other));
    });
  });
}
