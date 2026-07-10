import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/data/task_content_repository.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/content_validation_error.dart';
import 'package:igyal2/src/domain/content_validator.dart';
import 'package:igyal2/src/domain/result.dart';
import 'package:igyal2/src/domain/task_content.dart';

// Nyers JSON markerek: a stub validátor input alapján dönt (nem tartalom
// szerint), így a repository-teszt független a valós sémától.
const _validCache = 'valid-cache';
const _validBundled = 'valid-bundled';
const _validRemote = 'valid-remote';
const _invalid = 'invalid';

/// A sikeres validáció eredménye — üres tartalom elég, a repository nem
/// vizsgálja a sablonokat.
const _validContent = TaskContent(version: 1, templates: []);

/// Stub validátor: a [_validRaw] halmazban lévő nyers stringeket fogadja el
/// érvényesnek, mindent mást elutasít. Nem a valós sémát futtatja — a
/// repository orchestrációját izoláltan teszteljük.
class _StubValidator extends ContentValidator {
  _StubValidator(this._validRaw);

  final Set<String> _validRaw;

  @override
  Result<TaskContent, List<ContentValidationError>> validate(String rawJson) {
    if (_validRaw.contains(rawJson)) {
      return const Success<TaskContent, List<ContentValidationError>>(
        _validContent,
      );
    }
    return const Failure<TaskContent, List<ContentValidationError>>(
      <ContentValidationError>[],
    );
  }
}

/// Csak olvasható fake forrás egy előre beállított eredménnyel; számolja a
/// `load()` hívásokat (annak ellenőrzésére, hogy a bundled nem lett-e
/// feleslegesen megérintve).
class _FakeSource implements TaskTemplateSource {
  _FakeSource(this._result);

  final Result<String, TaskSourceError> _result;
  int loadCount = 0;

  @override
  Future<Result<String, TaskSourceError>> load() async {
    loadCount++;
    return _result;
  }
}

/// Írható fake cache: beállított `load()`/`save()`/`clear()` eredményekkel,
/// naplózza a mentett tartalmakat és a törlések számát.
class _FakeCache implements TaskTemplateCache {
  _FakeCache({
    required Result<String, TaskSourceError> loadResult,
    Result<void, TaskSourceError> saveResult = const Success<void, TaskSourceError>(null),
    Result<void, TaskSourceError> clearResult = const Success<void, TaskSourceError>(null),
  }) : _loadResult = loadResult,
       _saveResult = saveResult,
       _clearResult = clearResult;

  final Result<String, TaskSourceError> _loadResult;
  final Result<void, TaskSourceError> _saveResult;
  final Result<void, TaskSourceError> _clearResult;

  final List<String> savedPayloads = [];
  int clearCount = 0;

  @override
  Future<Result<String, TaskSourceError>> load() async => _loadResult;

  @override
  Future<Result<void, TaskSourceError>> save(String rawJson) async {
    savedPayloads.add(rawJson);
    return _saveResult;
  }

  @override
  Future<Result<void, TaskSourceError>> clear() async {
    clearCount++;
    return _clearResult;
  }
}

TaskContentRepository _buildRepository({
  required TaskTemplateSource bundled,
  required TaskTemplateCache cache,
  TaskTemplateSource? remote,
  Set<String> valid = const {},
  List<String>? logs,
}) {
  return TaskContentRepository(
    bundled: bundled,
    cache: cache,
    remote: remote ?? _FakeSource(const Failure(TaskSourceNotFound('n/a'))),
    validator: _StubValidator(valid),
    logger: logs?.add,
  );
}

void main() {
  group('TaskContentRepository.loadContent', () {
    test('érvényes cache-t ad vissza, a bundledhez nem nyúl', () async {
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(loadResult: const Success(_validCache));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        valid: {_validCache, _validBundled},
      );

      final content = await repo.loadContent();

      expect(content, _validContent);
      expect(bundled.loadCount, 0);
      expect(cache.clearCount, 0);
    });

    test('cache NotFound → némán a bundled padlóra esik', () async {
      final logs = <String>[];
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        valid: {_validBundled},
        logs: logs,
      );

      final content = await repo.loadContent();

      expect(content, _validContent);
      expect(bundled.loadCount, 1);
      expect(cache.clearCount, 0);
      expect(logs, isEmpty);
    });

    test('cache olvashatatlan → logol és a bundledre esik', () async {
      final logs = <String>[];
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceUnreadable('io')),
      );
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        valid: {_validBundled},
        logs: logs,
      );

      final content = await repo.loadContent();

      expect(content, _validContent);
      expect(cache.clearCount, 0);
      expect(logs, isNotEmpty);
    });

    test('érvénytelen cache → eldobja és a bundledre esik', () async {
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(loadResult: const Success(_invalid));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        valid: {_validBundled},
      );

      final content = await repo.loadContent();

      expect(content, _validContent);
      expect(cache.clearCount, 1);
      expect(bundled.loadCount, 1);
    });

    test('érvénytelen cache + érvénytelen bundled → StateError', () async {
      final bundled = _FakeSource(const Success(_invalid));
      final cache = _FakeCache(loadResult: const Success(_invalid));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
      );

      await expectLater(repo.loadContent(), throwsStateError);
      expect(cache.clearCount, 1);
    });

    test('cache NotFound + olvashatatlan bundled → StateError', () async {
      final bundled = _FakeSource(
        const Failure(TaskSourceUnreadable('io')),
      );
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final repo = _buildRepository(bundled: bundled, cache: cache);

      await expectLater(repo.loadContent(), throwsStateError);
    });
  });

  group('TaskContentRepository.refreshInBackground', () {
    test('érvényes remote → a nyers JSON-t cache-be menti', () async {
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final remote = _FakeSource(const Success(_validRemote));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        remote: remote,
        valid: {_validRemote},
      );

      await repo.refreshInBackground();

      expect(cache.savedPayloads, [_validRemote]);
    });

    test('remote hiba → nem ment, logol', () async {
      final logs = <String>[];
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final remote = _FakeSource(
        const Failure(TaskSourceNetworkFailure('down')),
      );
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        remote: remote,
        logs: logs,
      );

      await repo.refreshInBackground();

      expect(cache.savedPayloads, isEmpty);
      expect(logs, isNotEmpty);
    });

    test('érvénytelen remote tartalom → nem ment, logol', () async {
      final logs = <String>[];
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final remote = _FakeSource(const Success(_invalid));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        remote: remote,
        logs: logs,
      );

      await repo.refreshInBackground();

      expect(cache.savedPayloads, isEmpty);
      expect(logs, isNotEmpty);
    });

    test('cache mentési hiba → nem dob, logol', () async {
      final logs = <String>[];
      final bundled = _FakeSource(const Success(_validBundled));
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
        saveResult: const Failure(TaskSourceUnreadable('tele a disk')),
      );
      final remote = _FakeSource(const Success(_validRemote));
      final repo = _buildRepository(
        bundled: bundled,
        cache: cache,
        remote: remote,
        valid: {_validRemote},
        logs: logs,
      );

      await repo.refreshInBackground();

      expect(cache.savedPayloads, [_validRemote]);
      expect(logs, isNotEmpty);
    });
  });
}
