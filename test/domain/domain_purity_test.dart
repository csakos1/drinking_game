import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A domain-réteg tisztaságát őrző teszt.
///
/// Végigolvassa a `lib/src/domain/` összes Dart-forrásfájlját, és
/// elhasal, ha bármelyikben tiltott import/export szerepel. A domain csak
/// `dart:core`-t (implicit), `dart:convert`-et, `dart:math`-ot és saját,
/// domainen belüli fájlt importálhat — sem Fluttert, sem `dart:io`-t, sem
/// más réteget vagy külső csomagot.
///
/// Ez az `ARCHITECTURE.md` 2. fejezetének „lint + teszt" garanciáját
/// váltja valóra, külső eszköz (custom_lint) nélkül. Maga a teszt
/// használhat `dart:io`-t, mert nem a domain forrása; csak a vizsgált
/// fájlok tartalmát korlátozza.
void main() {
  group('domain purity', () {
    // A domain forráskönyvtára a repógyökérhez képest. A teszt a
    // package gyökeréből fut (flutter test), így ez a relatív út stabil.
    final domainDir = Directory('lib/src/domain');

    // Engedélyezett dart:-könyvtárak a domainben.
    const allowedDartLibraries = {'dart:core', 'dart:convert', 'dart:math'};

    // A domain saját package-prefixe: a domainen belüli import ezzel
    // kezdődik. Minden más package: import tiltott, egyetlen indokolt
    // kivétellel: a package:meta annotáció-only (pl. @immutable), a Dart
    // SDK szállítja, futásidejű viselkedése nincs — nem sérti a domain
    // platform-/Flutter-mentességét.
    const domainPackagePrefix = 'package:igyal2/src/domain/';
    const allowedExternalPackages = {'package:meta/'};

    // Import/export sorok kiszűrése; a from-részben egyszeres vagy
    // dupla idézőjel is állhat.
    final importRegExp = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );

    test('a domain könyvtár létezik', () {
      expect(
        domainDir.existsSync(),
        isTrue,
        reason: 'Hiányzik: ${domainDir.path}',
      );
    });

    test('egyetlen domain-fájl sem importál tiltott forrást', () {
      final dartFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(
        dartFiles,
        isNotEmpty,
        reason: 'Nincs domain Dart-fájl a vizsgálathoz.',
      );

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final match in importRegExp.allMatches(content)) {
          final uri = match.group(1);
          // A regex 1-es csoportja a match létekor mindig kötött, de a
          // null-ellenőrzést a ! helyett explicit ággal kezeljük.
          if (uri == null) {
            continue;
          }

          final isAllowed =
              allowedDartLibraries.contains(uri) ||
              uri.startsWith(domainPackagePrefix) ||
              allowedExternalPackages.any(uri.startsWith) ||
              // Relatív, domainen belüli import (nincs séma-prefix).
              (!uri.startsWith('dart:') && !uri.startsWith('package:'));

          if (!isAllowed) {
            violations.add('${file.path}: $uri');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Tiltott import a domain rétegben:\n${violations.join('\n')}\n'
            'A domain csak dart:core/convert/math-ot és saját fájlt '
            'importálhat.',
      );
    });
  });
}
