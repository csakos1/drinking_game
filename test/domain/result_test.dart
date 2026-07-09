import 'package:flutter_test/flutter_test.dart';
import 'package:igyal2/src/domain/result.dart';

void main() {
  group('Result.fold', () {
    test('Success az onSuccess ágat hívja', () {
      const Result<int, String> result = Success(42);
      final folded = result.fold((v) => 'ok:$v', (e) => 'err:$e');
      expect(folded, 'ok:42');
    });

    test('Failure az onFailure ágat hívja', () {
      const Result<int, String> result = Failure('baj');
      final folded = result.fold((v) => 'ok:$v', (e) => 'err:$e');
      expect(folded, 'err:baj');
    });
  });

  group('Result.map', () {
    test('Success értékét transzformálja', () {
      const Result<int, String> result = Success(3);
      final mapped = result.map((v) => v * 2);
      expect(mapped, const Success<int, String>(6));
    });

    test('Failure-t változatlanul továbbad', () {
      const Result<int, String> result = Failure('baj');
      final mapped = result.map((v) => v * 2);
      expect(mapped, const Failure<int, String>('baj'));
    });
  });

  group('Result predikátumok', () {
    test('isSuccess / isFailure Success esetén', () {
      const Result<int, String> result = Success(1);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('isSuccess / isFailure Failure esetén', () {
      const Result<int, String> result = Failure('x');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });
  });

  group('Result egyenlőség', () {
    test('azonos Success-ek egyenlők', () {
      expect(const Success<int, String>(5), const Success<int, String>(5));
    });

    test('eltérő Success-ek nem egyenlők', () {
      expect(
        const Success<int, String>(5),
        isNot(const Success<int, String>(6)),
      );
    });

    test('Success és Failure nem egyenlő', () {
      expect(
        const Success<int, String>(5),
        isNot(const Failure<int, String>('5')),
      );
    });
  });
}
