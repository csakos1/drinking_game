import 'package:meta/meta.dart';

/// Kétágú eredménytípus a várható hibák kezelésére, kivétel nélkül.
///
/// A domain a kritikus határokon (JSON-parszolás, tartalom-validáció) ezt
/// használja: a várható hiba adatként utazik, nem `throw`-ként. Kivétel
/// csak programozói bugra és infrastruktúra-hibára marad.
///
/// Sealed: a [Success] és [Failure] a két lehetséges ág, így a hívó
/// oldali `switch` kimerítő lehet.
@immutable
sealed class Result<T, E> {
  const Result();

  /// Igaz, ha az eredmény [Success].
  bool get isSuccess => this is Success<T, E>;

  /// Igaz, ha az eredmény [Failure].
  bool get isFailure => this is Failure<T, E>;

  /// A két ágat egyetlen `R` értékre képezi le.
  ///
  /// A hívó mindkét esetre ad függvényt: [onSuccess] a sikeres értékre,
  /// [onFailure] a hibára. Ez a preferált fogyasztási mód, mert kimerítő.
  R fold<R>(R Function(T value) onSuccess, R Function(E error) onFailure) {
    return switch (this) {
      Success<T, E>(:final value) => onSuccess(value),
      Failure<T, E>(:final error) => onFailure(error),
    };
  }

  /// A sikeres értéket [transform]-mal alakítja, a hibát változatlanul
  /// továbbadja.
  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T, E>(:final value) => Success(transform(value)),
      Failure<T, E>(:final error) => Failure(error),
    };
  }
}

/// Sikeres eredmény: a [value] értéket hordozza.
@immutable
final class Success<T, E> extends Result<T, E> {
  /// Létrehoz egy sikeres eredményt a [value] értékkel.
  const Success(this.value);

  /// A sikeres művelet eredménye.
  final T value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Success<T, E> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Hibás eredmény: az [error] hibát hordozza.
@immutable
final class Failure<T, E> extends Result<T, E> {
  /// Létrehoz egy hibás eredményt az [error] hibával.
  const Failure(this.error);

  /// A hiba leírása (a domainben tipikusan sealed hibatípus vagy lista).
  final E error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Failure<T, E> && other.error == error;
  }

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
