/// A feladatkártya megjelenítési kategóriája.
///
/// Tisztán prezentációs szerepe van (kártya-badge és -szín); a
/// játéklogikát (hány szereplő, milyen megkötés) nem ez, hanem a
/// `SlotConstraint` és a `playerCount` határozza meg. A hat érték a v0
/// gyűjtő taxonómiájával egyezik; az `egyeb` a „nem sorolható be" eset
/// gyűjtőmedencéje.
///
/// A [slug] a JSON-ban tárolt ASCII-azonosító; a magyar címke a
/// presentation-rétegben, l10n-ből jön.
enum TaskType {
  /// Játék.
  jatek('jatek'),

  /// Párbaj.
  parbaj('parbaj'),

  /// Vírus.
  virus('virus'),

  /// Feladat.
  feladat('feladat'),

  /// Activity.
  activity('activity'),

  /// Egyéb (gyűjtőmedence a be nem sorolható feladatoknak).
  egyeb('egyeb')
  ;

  const TaskType(this.slug);

  /// A JSON-ban tárolt ASCII-slug (pl. `"parbaj"`).
  final String slug;

  /// A [slug]-hoz tartozó [TaskType], vagy `null`, ha nincs ilyen.
  ///
  /// A validátor ezt használja: `null` esetén a sablon ismeretlen típusú.
  /// Szándékosan `null`-t ad dobás helyett, mert az ismeretlen típus
  /// várható tartalmi hiba (Result-ág), nem programozói bug.
  static TaskType? fromSlug(String slug) {
    for (final type in TaskType.values) {
      if (type.slug == slug) {
        return type;
      }
    }
    return null;
  }
}
