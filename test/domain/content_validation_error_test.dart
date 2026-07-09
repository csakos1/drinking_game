import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/content_validation_error.dart';

void main() {
  group('templateId a hibaosztályokon', () {
    test('dokumentum-szintű hibák templateId-je null', () {
      expect(const MalformedJson('x').templateId, isNull);
      expect(
        const UnsupportedVersion(found: 2, supported: 1).templateId,
        isNull,
      );
      expect(const EmptyTemplateList().templateId, isNull);
    });

    test('sablonszintű hibák hordozzák a templateId-t', () {
      expect(const DuplicateId('t1').templateId, 't1');
      expect(const BlankText('t2').templateId, 't2');
      expect(
        const UnknownType(templateId: 't3', slug: 'x').templateId,
        't3',
      );
    });
  });

  group('hiba-egyenlőség', () {
    test('azonos UnknownType-ok egyenlők', () {
      expect(
        const UnknownType(templateId: 't', slug: 's'),
        const UnknownType(templateId: 't', slug: 's'),
      );
    });

    test('eltérő slug nem egyenlő', () {
      expect(
        const UnknownType(templateId: 't', slug: 's1'),
        isNot(const UnknownType(templateId: 't', slug: 's2')),
      );
    });

    test('azonos DuplicateId-k egyenlők, hashCode is', () {
      const a = DuplicateId('x');
      const b = DuplicateId('x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('különböző hibatípusok nem egyenlők azonos id-vel', () {
      expect(const DuplicateId('x'), isNot(const BlankText('x')));
    });

    test('EmptyTemplateList példányok egyenlők', () {
      expect(const EmptyTemplateList(), const EmptyTemplateList());
    });

    test('MalformedTemplate null templateId-vel egyenlő', () {
      expect(
        const MalformedTemplate(templateId: null, detail: 'd'),
        const MalformedTemplate(templateId: null, detail: 'd'),
      );
    });
  });
}
