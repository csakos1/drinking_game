/// A sablon szereplőválasztási megkötése.
///
/// Meghatározza, hány és milyen viszonyban álló játékost igényel a sablon.
/// A pontos szemantikát az `ARCHITECTURE.md` 4. fejezete rögzíti; a
/// [slug] a JSON-ban tárolt ASCII-azonosító.
enum SlotConstraint {
  /// Tetszőleges játékos(ok), csapattól függetlenül; `playerCount >= 1`.
  anyone('anyone'),

  /// Egy sorsolt csapat több tagja; `playerCount >= 2`.
  sameTeam('sameTeam'),

  /// Pontosan két játékos, ellentétes csapatokból; `playerCount == 2`.
  oppositeTeams('oppositeTeams'),

  /// Nincs játékos-slot; a `{team}` egy sorsolt csapatra oldódik fel;
  /// `playerCount == 0`.
  wholeTeam('wholeTeam'),

  /// Mindenki; nincs placeholder; `playerCount == 0`.
  everyone('everyone')
  ;

  const SlotConstraint(this.slug);

  /// A JSON-ban tárolt ASCII-slug (pl. `"oppositeTeams"`).
  final String slug;

  /// A [slug]-hoz tartozó [SlotConstraint], vagy `null`, ha nincs ilyen.
  ///
  /// A validátor használja: `null` esetén a sablon ismeretlen megkötésű.
  static SlotConstraint? fromSlug(String slug) {
    for (final constraint in SlotConstraint.values) {
      if (constraint.slug == slug) {
        return constraint;
      }
    }
    return null;
  }

  /// Igaz, ha a [playerCount] megengedett ehhez a megkötéshez.
  ///
  /// Ez a séma szintaktikai szabálya (hány slotot deklarálhat a sablon);
  /// azt, hogy az aktuális keret ki tudja-e elégíteni, a sablonmotor
  /// játszhatósági szűrője dönti el, nem ez.
  bool isValidPlayerCount(int playerCount) => switch (this) {
    SlotConstraint.anyone => playerCount >= 1,
    SlotConstraint.sameTeam => playerCount >= 2,
    SlotConstraint.oppositeTeams => playerCount == 2,
    SlotConstraint.wholeTeam => playerCount == 0,
    SlotConstraint.everyone => playerCount == 0,
  };
}
