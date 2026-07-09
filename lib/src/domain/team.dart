/// A játék két csapata.
///
/// A domain szándékosan semleges neveket használ (`first`, `second`) szín
/// vagy címke helyett: a megjelenített csapatszín (piros/kék) és a
/// lokalizált címke tisztán presentation-/l10n-felelősség. Így a domain
/// megjelenítés- és nyelvfüggetlen marad.
enum Team {
  /// Az első csapat.
  first,

  /// A második csapat.
  second
  ;

  /// Az ellentétes csapat.
  ///
  /// Az `oppositeTeams` megkötés feloldásánál hasznos: egy adott csapatból
  /// kiindulva megadja a másikat.
  Team get opposite => switch (this) {
    Team.first => Team.second,
    Team.second => Team.first,
  };
}
