import 'package:meta/meta.dart';

/// A játék indításakor felmerülő, várható hibák sealed hierarchiája.
///
/// Egyelőre egyetlen eset ([NoPlayableTemplates]); sealed, hogy a hívó oldali
/// `switch` kimerítő legyen, és későbbi bővítés fordítási hibával jelezzen. A
/// nem indítható keret (üres csapat) NEM ide tartozik: azt a setup garantálja,
/// a `StartGame` `assert`-tel őrzi (programozói hiba, nem várható eset).
@immutable
sealed class StartGameError {
  const StartGameError();
}

/// A kerettel egyetlen sablon sem játszható, így nincs mit paklizni.
///
/// A presentation ezt jelzi a felhasználónak; élesben a bundled tartalom
/// tesztje garantálja, hogy 1v1 kerettel is van játszható sablon, ezért
/// valódi eszközön nem fordulhat elő (`ARCHITECTURE.md` 5. és 12. fejezet).
@immutable
final class NoPlayableTemplates extends StartGameError {
  /// Létrehoz egy [NoPlayableTemplates] hibát.
  const NoPlayableTemplates();

  @override
  bool operator ==(Object other) => other is NoPlayableTemplates;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoPlayableTemplates()';
}
