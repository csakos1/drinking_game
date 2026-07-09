import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/content_validation_error.dart';
import 'package:igyal2/src/domain/content_validator.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/slot_constraint.dart';
import 'package:igyal2/src/domain/task_content.dart';
import 'package:igyal2/src/domain/task_type.dart';

void main() {
  const validator = ContentValidator();

  // Egy érvényes sablon-térkép, amiből a tesztek szelektíven rontanak el
  // egy-egy mezőt. Így minden negatív eset egy jól definiált eltérés.
  Map<String, dynamic> validTemplate({
    String id = 'jatek-001',
    String type = 'jatek',
    String constraint = 'anyone',
    int playerCount = 1,
    String text = '{p1} igyon egyet!',
  }) {
    return {
      'id': id,
      'type': type,
      'constraint': constraint,
      'playerCount': playerCount,
      'text': text,
    };
  }

  String jsonWith(List<Map<String, dynamic>> templates, {int version = 1}) {
    return jsonEncode({'version': version, 'templates': templates});
  }

  // A Failure-hibalista kinyerése; ha Success-t kapunk, a teszt elhasal.
  List<ContentValidationError> errorsOf(
    Result<TaskContent, List<ContentValidationError>> result,
  ) {
    return switch (result) {
      Success() => fail('Success helyett Failure-t vártunk.'),
      Failure(:final error) => error,
    };
  }

  group('ContentValidator happy path', () {
    test('érvényes tartalom Success-t ad a sablonokkal', () {
      final json = jsonWith([
        validTemplate(),
        validTemplate(
          id: 'parbaj-002',
          type: 'parbaj',
          constraint: 'oppositeTeams',
          playerCount: 2,
          text: '{p1} és {p2} párbajozzon!',
        ),
        validTemplate(
          id: 'virus-003',
          type: 'virus',
          constraint: 'wholeTeam',
          playerCount: 0,
          text: 'A {team} igyon!',
        ),
        validTemplate(
          id: 'egyeb-004',
          type: 'egyeb',
          constraint: 'everyone',
          playerCount: 0,
          text: 'Mindenki igyon!',
        ),
      ]);

      final result = validator.validate(json);

      expect(result.isSuccess, isTrue);
      final content = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(content.version, 1);
      expect(content.templates, hasLength(4));
      expect(content.templates.first.type, TaskType.jatek);
      expect(content.templates[2].constraint, SlotConstraint.wholeTeam);
    });

    test('a sablonok sorrendje megőrződik', () {
      final json = jsonWith([
        validTemplate(id: 'a'),
        validTemplate(id: 'b'),
        validTemplate(id: 'c'),
      ]);

      final result = validator.validate(json);
      final content = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(content.templates.map((t) => t.id).toList(), ['a', 'b', 'c']);
    });
  });

  group('dokumentum-szintű hibák', () {
    test('érvénytelen JSON MalformedJson-t ad', () {
      final result = validator.validate('{ ez nem json');
      expect(errorsOf(result).single, isA<MalformedJson>());
    });

    test('nem objektum gyökér MalformedJson-t ad', () {
      final result = validator.validate('[1, 2, 3]');
      expect(errorsOf(result).single, isA<MalformedJson>());
    });

    test('hiányzó version MalformedJson-t ad', () {
      final result = validator.validate(
        jsonEncode({'templates': <dynamic>[]}),
      );
      expect(errorsOf(result).single, isA<MalformedJson>());
    });

    test('nem támogatott version UnsupportedVersion-t ad', () {
      final json = jsonWith([validTemplate()], version: 2);
      final error = errorsOf(validator.validate(json)).single;
      expect(
        error,
        isA<UnsupportedVersion>()
            .having((e) => e.found, 'found', 2)
            .having((e) => e.supported, 'supported', 1),
      );
    });

    test('hiányzó templates lista MalformedJson-t ad', () {
      final result = validator.validate(jsonEncode({'version': 1}));
      expect(errorsOf(result).single, isA<MalformedJson>());
    });

    test('üres templates lista EmptyTemplateList-et ad', () {
      final result = validator.validate(jsonWith([]));
      expect(errorsOf(result).single, isA<EmptyTemplateList>());
    });
  });

  group('sablonszintű strukturális hibák', () {
    test('nem objektum sablon MalformedTemplate-et ad', () {
      final json = jsonEncode({
        'version': 1,
        'templates': ['nem objektum'],
      });
      expect(
        errorsOf(validator.validate(json)).single,
        isA<MalformedTemplate>(),
      );
    });

    test('hiányzó id MalformedTemplate-et ad', () {
      final t = validTemplate()..remove('id');
      expect(
        errorsOf(validator.validate(jsonWith([t]))).single,
        isA<MalformedTemplate>(),
      );
    });

    test('hiányzó text MalformedTemplate-et ad', () {
      final t = validTemplate()..remove('text');
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is MalformedTemplate), isTrue);
    });

    test('nem egész playerCount MalformedTemplate-et ad', () {
      final t = validTemplate()..['playerCount'] = 'kettő';
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is MalformedTemplate), isTrue);
    });
  });

  group('mező-értékhibák', () {
    test('ismeretlen type UnknownType-ot ad', () {
      final t = validTemplate(type: 'ivaszat');
      final error = errorsOf(validator.validate(jsonWith([t]))).single;
      expect(
        error,
        isA<UnknownType>()
            .having((e) => e.templateId, 'templateId', 'jatek-001')
            .having((e) => e.slug, 'slug', 'ivaszat'),
      );
    });

    test('ismeretlen constraint UnknownConstraint-ot ad', () {
      final t = validTemplate(constraint: 'valami');
      final error = errorsOf(validator.validate(jsonWith([t]))).single;
      expect(error, isA<UnknownConstraint>());
    });

    test('üres text BlankText-et ad', () {
      final t = validTemplate(text: '   ');
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is BlankText), isTrue);
    });

    test('duplikált id DuplicateId-t ad', () {
      final json = jsonWith([
        validTemplate(),
        validTemplate(text: '{p1} igyon kettőt!'),
      ]);
      final errors = errorsOf(validator.validate(json));
      expect(errors.any((e) => e is DuplicateId), isTrue);
    });
  });

  group('playerCount-szabály', () {
    test('anyone playerCount 0 InvalidPlayerCount-ot ad', () {
      final t = validTemplate(playerCount: 0, text: 'nincs slot');
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is InvalidPlayerCount), isTrue);
    });

    test('sameTeam playerCount 1 InvalidPlayerCount-ot ad', () {
      // A playerCount default értéke 1, ami sameTeam-hez érvénytelen (>=2).
      final t = validTemplate(
        constraint: 'sameTeam',
        text: '{p1} egyedül',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is InvalidPlayerCount), isTrue);
    });

    test('oppositeTeams playerCount 3 InvalidPlayerCount-ot ad', () {
      final t = validTemplate(
        constraint: 'oppositeTeams',
        playerCount: 3,
        text: '{p1} {p2} {p3}',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is InvalidPlayerCount), isTrue);
    });

    test('wholeTeam playerCount 1 InvalidPlayerCount-ot ad', () {
      // A playerCount default értéke 1, ami wholeTeam-hez érvénytelen (0).
      final t = validTemplate(
        constraint: 'wholeTeam',
        text: 'A {team} igyon',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is InvalidPlayerCount), isTrue);
    });
  });

  group('placeholder-egyeztetés', () {
    test('hiányzó {p2} PlaceholderMismatch-et ad', () {
      final t = validTemplate(
        constraint: 'oppositeTeams',
        playerCount: 2,
        text: 'csak {p1} van itt',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is PlaceholderMismatch), isTrue);
    });

    test('többlet {p3} PlaceholderMismatch-et ad', () {
      final t = validTemplate(
        constraint: 'oppositeTeams',
        playerCount: 2,
        text: '{p1} {p2} {p3}',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is PlaceholderMismatch), isTrue);
    });

    test('ismeretlen token {P1} PlaceholderMismatch-et ad', () {
      final t = validTemplate(text: '{P1} igyon');
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is PlaceholderMismatch), isTrue);
    });

    test('wholeTeam-ben hiányzó {team} PlaceholderMismatch-et ad', () {
      final t = validTemplate(
        constraint: 'wholeTeam',
        playerCount: 0,
        text: 'nincs team token',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is PlaceholderMismatch), isTrue);
    });

    test('everyone-ban tiltott placeholder PlaceholderMismatch-et ad', () {
      final t = validTemplate(
        constraint: 'everyone',
        playerCount: 0,
        text: '{p1} nem lehet itt',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.any((e) => e is PlaceholderMismatch), isTrue);
    });

    test('sameTeam pontosan {p1}..{pN} Success (nincs hiba)', () {
      final t = validTemplate(
        id: 'st-1',
        constraint: 'sameTeam',
        playerCount: 3,
        text: '{p1}, {p2} és {p3} egy csapat',
      );
      expect(validator.validate(jsonWith([t])).isSuccess, isTrue);
    });
  });

  group('hibaösszegyűjtés és mindent-vagy-semmit', () {
    test('több hibás sablon minden hibát összegyűjt', () {
      final json = jsonWith([
        validTemplate(id: 'ok-1'),
        validTemplate(id: 'bad-1', type: 'ismeretlen'),
        validTemplate(id: 'bad-2', constraint: 'ismeretlen'),
      ]);
      final errors = errorsOf(validator.validate(json));
      // Legalább a két rossz sablon két hibája jelen van.
      expect(errors.length, greaterThanOrEqualTo(2));
      expect(errors.any((e) => e is UnknownType), isTrue);
      expect(errors.any((e) => e is UnknownConstraint), isTrue);
    });

    test('egyetlen hibás sablon az egész tartalmat érvényteleníti', () {
      final json = jsonWith([
        validTemplate(id: 'ok-1'),
        validTemplate(id: 'ok-2', text: '{p1} igyon!'),
        validTemplate(id: 'bad', type: 'ismeretlen'),
      ]);
      // Mindent-vagy-semmit: Failure, nem részleges Success.
      expect(validator.validate(json).isFailure, isTrue);
    });

    test('egy sablonon belül több hiba is összegyűlik', () {
      final t = validTemplate(
        type: 'ismeretlen',
        constraint: 'ismeretlen',
      );
      final errors = errorsOf(validator.validate(jsonWith([t])));
      expect(errors.length, greaterThanOrEqualTo(2));
    });
  });
}
