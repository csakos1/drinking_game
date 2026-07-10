import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/data/cached_file_task_template_source.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/domain/result.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('igyal2_cache_test');
  });

  tearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  group('load', () {
    test('nincs cache-fájl → TaskSourceNotFound', () async {
      final source = CachedFileTaskTemplateSource(dir);

      final result = await source.load();

      final error = switch (result) {
        Success() => fail('Failure-t vártunk.'),
        Failure(:final error) => error,
      };
      expect(error, isA<TaskSourceNotFound>());
    });

    test('létező cache-fájl tartalmát adja Success-ként', () async {
      await File('${dir.path}/tasks.json').writeAsString('{"version":1}');
      final source = CachedFileTaskTemplateSource(dir);

      final result = await source.load();

      final json = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(json, '{"version":1}');
    });
  });

  group('save', () {
    test('atomikusan létrehozza a cache-t, majd visszaolvasható', () async {
      final source = CachedFileTaskTemplateSource(dir);

      final saveResult = await source.save('{"version":1}');
      expect(saveResult.isSuccess, isTrue);

      final loadResult = await source.load();
      final json = switch (loadResult) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk a mentés után.'),
      };
      expect(json, '{"version":1}');
    });

    test('hiányzó könyvtárat létrehoz mentés előtt', () async {
      final nested = Directory('${dir.path}/nested/cache');
      final source = CachedFileTaskTemplateSource(nested);

      final saveResult = await source.save('{"version":1}');

      expect(saveResult.isSuccess, isTrue);
      expect(File('${nested.path}/tasks.json').existsSync(), isTrue);
    });

    test('sikeres mentés után nem marad .tmp fájl', () async {
      final source = CachedFileTaskTemplateSource(dir);

      await source.save('{"version":1}');

      expect(File('${dir.path}/tasks.json.tmp').existsSync(), isFalse);
    });
  });

  group('clear', () {
    test('létező cache-fájlt töröl, a fájl nem marad a lemezen', () async {
      // Given: van érvényes cache-fájl a lemezen.
      await File('${dir.path}/tasks.json').writeAsString('{"version":1}');
      final source = CachedFileTaskTemplateSource(dir);

      // When: clear.
      final clearResult = await source.clear();

      // Then: siker, és a fájl eltűnt.
      expect(clearResult.isSuccess, isTrue);
      expect(File('${dir.path}/tasks.json').existsSync(), isFalse);
    });

    test('hiányzó cache-fájl esetén is Success', () async {
      // Given: nincs cache-fájl (nincs mit törölni).
      final source = CachedFileTaskTemplateSource(dir);

      // When: clear.
      final clearResult = await source.clear();

      // Then: no-throw szerződés — a hiányzó fájl nem hiba.
      expect(clearResult.isSuccess, isTrue);
    });

    test('törlés után load → TaskSourceNotFound', () async {
      // Given: van cache-fájl, majd töröljük.
      await File('${dir.path}/tasks.json').writeAsString('{"version":1}');
      final source = CachedFileTaskTemplateSource(dir);

      // When: clear, aztán load.
      await source.clear();
      final result = await source.load();

      // Then: a törlés valóban eltávolította a padlót → NotFound.
      final error = switch (result) {
        Success() => fail('Failure-t vártunk törlés után.'),
        Failure(:final error) => error,
      };
      expect(error, isA<TaskSourceNotFound>());
    });
  });
}
