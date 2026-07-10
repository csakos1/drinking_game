import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:igyal2/src/application/content_providers.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_cache.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';

void main() {
  const validJson =
      '{"version":1,"templates":[{"id":"jatek-001","type":"jatek",'
      '"constraint":"anyone","playerCount":1,"text":"{p1} iszik"}]}';

  const cacheJson =
      '{"version":1,"templates":[{"id":"cache-001","type":"jatek",'
      '"constraint":"anyone","playerCount":1,"text":"{p1} iszik"}]}';

  const bundledJson =
      '{"version":1,"templates":[{"id":"bundled-001","type":"jatek",'
      '"constraint":"anyone","playerCount":1,"text":"{p1} iszik"}]}';

  group('taskContentProvider', () {
    test('üres cache mellett a bundled padlót adja', () async {
      final container = ProviderContainer(
        overrides: [
          bundledTaskTemplateSourceProvider.overrideWith(
            (ref) => const _FakeSource(Success(validJson)),
          ),
          taskTemplateCacheProvider.overrideWith(
            (ref) => _FakeCache(
              loadResult: const Failure(TaskSourceNotFound('nincs')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(taskContentProvider.future);

      expect(content.version, 1);
      expect(content.templates, hasLength(1));
      expect(content.templates.single.id, 'jatek-001');
    });

    test('érvényes cache elsőbbséget élvez a bundleddel szemben', () async {
      final container = ProviderContainer(
        overrides: [
          bundledTaskTemplateSourceProvider.overrideWith(
            (ref) => const _FakeSource(Success(bundledJson)),
          ),
          taskTemplateCacheProvider.overrideWith(
            (ref) => _FakeCache(loadResult: const Success(cacheJson)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final content = await container.read(taskContentProvider.future);

      expect(content.templates.single.id, 'cache-001');
    });
  });

  group('triggerContentRefresh', () {
    test('beállított URL nélkül nem frissít és nem ment', () async {
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final container = ProviderContainer(
        overrides: [
          taskTemplateCacheProvider.overrideWith((ref) => cache),
        ],
      );
      addTearDown(container.dispose);

      await triggerContentRefresh(container);

      expect(cache.saveCalls, isEmpty);
    });

    test('beállított URL mellett frissít, ment és lezárja a klienst', () async {
      final cache = _FakeCache(
        loadResult: const Failure(TaskSourceNotFound('nincs')),
      );
      final client = _RecordingClient();
      final container = ProviderContainer(
        overrides: [
          remoteContentUriProvider.overrideWith(
            (ref) => Uri.parse('https://host.example/tasks.json'),
          ),
          refreshHttpClientProvider.overrideWith((ref) => client),
          bundledTaskTemplateSourceProvider.overrideWith(
            (ref) => const _FakeSource(Success(validJson)),
          ),
          remoteTaskTemplateSourceProvider.overrideWith(
            (ref) => const _FakeSource(Success(validJson)),
          ),
          taskTemplateCacheProvider.overrideWith((ref) => cache),
        ],
      );
      addTearDown(container.dispose);

      await triggerContentRefresh(container);

      expect(cache.saveCalls, hasLength(1));
      expect(cache.saveCalls.single, validJson);
      expect(client.closed, isTrue);
    });
  });
}

/// Rögzített [Result]-ot visszaadó egyszerű forrás-fake.
class _FakeSource implements TaskTemplateSource {
  const _FakeSource(this._result);

  final Result<String, TaskSourceError> _result;

  @override
  Future<Result<String, TaskSourceError>> load() async => _result;
}

/// Cache-fake: a `load()` rögzített eredményt ad, a `save()` a mentett JSON-okat
/// naplózza a verifikációhoz; a `clear()` mindig sikerrel tér vissza.
class _FakeCache implements TaskTemplateCache {
  _FakeCache({required Result<String, TaskSourceError> loadResult}) : _loadResult = loadResult;

  final Result<String, TaskSourceError> _loadResult;
  final List<String> saveCalls = [];

  @override
  Future<Result<String, TaskSourceError>> load() async => _loadResult;

  @override
  Future<Result<void, TaskSourceError>> save(String rawJson) async {
    saveCalls.add(rawJson);
    return const Success<void, TaskSourceError>(null);
  }

  @override
  Future<Result<void, TaskSourceError>> clear() async {
    return const Success<void, TaskSourceError>(null);
  }
}

/// HTTP-kliens fake, amely csak a `close()` hívást rögzíti; a `send()` sosem
/// hívódik (a távoli forrást magát fake-eljük).
class _RecordingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('A fake kliens send-je nem hívható.');
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}
