import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/task_type.dart';

void main() {
  group('TaskType.fromSlug', () {
    test('minden ismert slug feloldódik a megfelelő értékre', () {
      // Given-When-Then: minden enum-érték slugja visszaadja önmagát.
      for (final type in TaskType.values) {
        expect(TaskType.fromSlug(type.slug), type);
      }
    });

    test('ismeretlen slug null-t ad', () {
      expect(TaskType.fromSlug('nincs-ilyen'), isNull);
    });

    test('üres slug null-t ad', () {
      expect(TaskType.fromSlug(''), isNull);
    });

    test('a slug különbözik a kis/nagybetűre', () {
      // A JSON-slug szigorúan kisbetűs; a nagybetűs változat ismeretlen.
      expect(TaskType.fromSlug('Parbaj'), isNull);
    });
  });

  group('TaskType.slug', () {
    test('mind a hat típus deklarált', () {
      // Ha valaha típust adunk/veszünk, ez a teszt jelez.
      expect(TaskType.values, hasLength(6));
    });
  });
}
