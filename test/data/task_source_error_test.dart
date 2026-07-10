import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/data/task_source_error.dart';

void main() {
  group('message', () {
    test('minden ág visszaadja a leírását', () {
      expect(const TaskSourceNotFound('nincs cache').message, 'nincs cache');
      expect(const TaskSourceUnreadable('sérült fájl').message, 'sérült fájl');
      expect(
        const TaskSourceNetworkFailure('időtúllépés').message,
        'időtúllépés',
      );
    });
  });

  group('egyenlőség és hashCode', () {
    test('azonos ág + azonos üzenet → egyenlő, hashCode is', () {
      const a = TaskSourceNotFound('x');
      const b = TaskSourceNotFound('x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('eltérő üzenet nem egyenlő', () {
      expect(
        const TaskSourceUnreadable('a'),
        isNot(const TaskSourceUnreadable('b')),
      );
    });

    test('különböző ágak azonos üzenettel nem egyenlők', () {
      expect(
        const TaskSourceNotFound('x'),
        isNot(const TaskSourceNetworkFailure('x')),
      );
      expect(
        const TaskSourceUnreadable('x'),
        isNot(const TaskSourceNotFound('x')),
      );
    });
  });

  group('toString', () {
    test('tartalmazza az ág nevét és az üzenetet', () {
      expect(
        const TaskSourceNetworkFailure('502').toString(),
        'TaskSourceNetworkFailure(502)',
      );
    });
  });
}
