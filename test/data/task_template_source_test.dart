import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/data/task_template_source.dart';
import 'package:igyal2/src/domain/result.dart';

/// Rögzített eredményt adó teszt-implementáció: a [TaskTemplateSource]
/// szerződését (nyers JSON `Result`-ban) igazolja, tényleges I/O nélkül.
class _FixedSource implements TaskTemplateSource {
  const _FixedSource(this._result);

  final Result<String, TaskSourceError> _result;

  @override
  Future<Result<String, TaskSourceError>> load() async => _result;
}

void main() {
  group('TaskTemplateSource szerződés', () {
    test('a siker ága a nyers JSON stringet adja', () async {
      const source = _FixedSource(Success('{"version":1}'));

      final result = await source.load();

      final json = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(json, '{"version":1}');
    });

    test('a hiba ága a TaskSourceError-t adja', () async {
      const source = _FixedSource(
        Failure(TaskSourceNotFound('nincs tartalom')),
      );

      final result = await source.load();

      final error = switch (result) {
        Success() => fail('Failure-t vártunk.'),
        Failure(:final error) => error,
      };
      expect(error, isA<TaskSourceNotFound>());
      expect(error.message, 'nincs tartalom');
    });
  });
}
