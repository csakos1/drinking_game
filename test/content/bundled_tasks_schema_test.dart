import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/content_validator.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/task_content.dart';

/// A bundled `tasks.json` séma-validációs tesztje.
///
/// A valódi [ContentValidator]-t futtatja a valódi tartalomfájlon (lemezről
/// olvasva, a package gyökeréhez képest), így törött tartalom sosem
/// shippelhet: ha a fájl érvénytelen, ez a teszt piros. Külön ellenőrzi az
/// 1v1-játszhatóságot is — enélkül a `StartGame` `NoPlayableTemplates`-szel
/// elhasalna a minimális (1+1 fős) kerettel.
void main() {
  group('bundled tasks.json', () {
    late TaskContent content;

    setUpAll(() {
      final raw = File('assets/content/tasks.json').readAsStringSync();
      final result = const ContentValidator().validate(raw);
      content = switch (result) {
        Success(:final value) => value,
        Failure(:final error) => throw StateError(
          'A bundled tasks.json érvénytelen: $error',
        ),
      };
    });

    test('átmegy a sémán, és nem üres', () {
      expect(content.version, 1);
      expect(content.templates, isNotEmpty);
    });

    test('van legalább egy 1v1-ben (1+1 fő) játszható sablon', () {
      // A minimális keret: egy-egy fő a két csapatban. Ha erre nincs
      // játszható sablon, a játék el sem indulna.
      final hasPlayable = content.templates.any(
        (template) => template.constraint.isSatisfiableBy(
          firstTeamSize: 1,
          secondTeamSize: 1,
          playerCount: template.playerCount,
        ),
      );
      expect(hasPlayable, isTrue);
    });
  });
}
