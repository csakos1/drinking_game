import 'package:meta/meta.dart';

/// A tartalomforrás olvasása/lekérése során felmerülő hibák sealed
/// hierarchiája (data-réteg).
///
/// Szándékosan elkülönül a domain `ContentValidationError`-jától: ez I/O- és
/// hálózati hibát jelöl (a forrás elérhetetlensége), nem a tartalom
/// érvénytelenségét — azt a domain `ContentValidator`-a dönti el. A két
/// felelősség keverése sértené az SRP-t (lásd ADR-0002).
///
/// Sealed: a repository kimerítő `switch`-csel dönthet a forrásonkénti
/// viselkedésről (a [TaskSourceNotFound] néma továbblépés a következő
/// forrásra; a többi naplózandó, majd elnyelt).
@immutable
sealed class TaskSourceError {
  /// Bázis-konstruktor a leszármazottaknak.
  const TaskSourceError();

  /// Emberi olvasható leírás naplózáshoz.
  ///
  /// A pipeline a forráshibát némán elnyeli, de logolja (lásd
  /// `ARCHITECTURE.md` 7. fejezet), ezért minden ág ad egy üzenetet.
  String get message;
}

/// A forrásnál nincs elérhető tartalom: az asset vagy a cache-fájl hiányzik.
///
/// Nem „kemény" hiba — pl. első indításkor a cache még nem létezik. A
/// repository ilyenkor némán a következő forrásra lép.
@immutable
final class TaskSourceNotFound extends TaskSourceError {
  /// Létrehoz egy [TaskSourceNotFound] hibát a [message] leírással.
  const TaskSourceNotFound(this.message);

  @override
  final String message;

  @override
  bool operator ==(Object other) => other is TaskSourceNotFound && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TaskSourceNotFound($message)';
}

/// A forrás létezik, de az olvasása I/O-hibába ütközött (pl. jogosultsági
/// hiba, sérült fájl, dekódolási hiba).
@immutable
final class TaskSourceUnreadable extends TaskSourceError {
  /// Létrehoz egy [TaskSourceUnreadable] hibát a [message] leírással; a hívó
  /// tipikusan a kiváltó kivétel szövegét formázza bele.
  const TaskSourceUnreadable(this.message);

  @override
  final String message;

  @override
  bool operator ==(Object other) => other is TaskSourceUnreadable && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TaskSourceUnreadable($message)';
}

/// A távoli forrás lekérése sikertelen: időtúllépés, nem 2xx státusz, vagy
/// üres/olvashatatlan válasz.
@immutable
final class TaskSourceNetworkFailure extends TaskSourceError {
  /// Létrehoz egy [TaskSourceNetworkFailure] hibát a [message] leírással.
  const TaskSourceNetworkFailure(this.message);

  @override
  final String message;

  @override
  bool operator ==(Object other) => other is TaskSourceNetworkFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'TaskSourceNetworkFailure($message)';
}
