import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/data/bundled_asset_task_template_source.dart';
import 'package:igyal2/src/data/task_source_error.dart';
import 'package:igyal2/src/domain/result.dart';

/// Memóriában tárolt asset-térképet szolgáló fake bundle. A hiányzó kulcsra
/// `FlutterError`-t dob, ahogy a valódi `rootBundle` is (Error, nem Exception).
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._byPath);

  final Map<String, String> _byPath;

  @override
  Future<ByteData> load(String key) async {
    final content = _byPath[key];
    if (content == null) {
      throw FlutterError('Nincs ilyen asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(content));
    return ByteData.sublistView(bytes);
  }
}

void main() {
  group('BundledAssetTaskTemplateSource', () {
    test('a regisztrált asset tartalmát adja Success-ként', () async {
      final bundle = _FakeAssetBundle({
        'assets/content/tasks.json': '{"version":1}',
      });
      final source = BundledAssetTaskTemplateSource(bundle: bundle);

      final result = await source.load();

      final json = switch (result) {
        Success(:final value) => value,
        Failure() => fail('Success-t vártunk.'),
      };
      expect(json, '{"version":1}');
    });

    test('hiányzó asset → TaskSourceUnreadable', () async {
      final source = BundledAssetTaskTemplateSource(
        bundle: _FakeAssetBundle(const {}),
      );

      final result = await source.load();

      final error = switch (result) {
        Success() => fail('Failure-t vártunk.'),
        Failure(:final error) => error,
      };
      expect(error, isA<TaskSourceUnreadable>());
    });
  });
}
