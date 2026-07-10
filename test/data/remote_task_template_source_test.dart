import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:igyal2/src/data/remote_task_template_source.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/domain/result.dart';

void main() {
  final uri = Uri.parse('https://example.test/tasks.json');

  TaskSourceError errorOf(Result<String, TaskSourceError> result) {
    return switch (result) {
      Success() => fail('Failure-t vártunk.'),
      Failure(:final error) => error,
    };
  }

  group('RemoteTaskTemplateSource', () {
    test('2xx + nem üres törzs → Success a törzzsel', () async {
      final client = MockClient((_) async => http.Response('{"version":1}', 200));
      final source = RemoteTaskTemplateSource(uri, client: client);

      final result = await source.load();

      final json = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(json, '{"version":1}');
    });

    test('nem 2xx státusz → TaskSourceNetworkFailure', () async {
      final client = MockClient((_) async => http.Response('nope', 404));
      final source = RemoteTaskTemplateSource(uri, client: client);

      expect(errorOf(await source.load()), isA<TaskSourceNetworkFailure>());
    });

    test('üres törzs → TaskSourceNetworkFailure', () async {
      final client = MockClient((_) async => http.Response('', 200));
      final source = RemoteTaskTemplateSource(uri, client: client);

      expect(errorOf(await source.load()), isA<TaskSourceNetworkFailure>());
    });

    test('hálózati kivétel → TaskSourceNetworkFailure', () async {
      final client = MockClient((_) async => throw http.ClientException('boom'));
      final source = RemoteTaskTemplateSource(uri, client: client);

      expect(errorOf(await source.load()), isA<TaskSourceNetworkFailure>());
    });

    test('időtúllépés → TaskSourceNetworkFailure', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{"version":1}', 200);
      });
      final source = RemoteTaskTemplateSource(
        uri,
        client: client,
        timeout: const Duration(milliseconds: 10),
      );

      expect(errorOf(await source.load()), isA<TaskSourceNetworkFailure>());
    });
  });
}
