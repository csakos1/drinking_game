# ADR-0003 — Setup csapatalkotás modell (két-csapatos bevitel)

- **Státusz:** elfogadva
- **Dátum:** 2026-07-10

## Kontextus

Az `ARCHITECTURE.md` 6. fejezete a csapatalkotást eddig egyetlen lapos névlista
köré építette: a felhasználó neveket vitt be csapat nélkül, a rendszer a
`DrawTeams` use case-szel véletlenül, egyenlően két csapatba osztotta
(⌈n/2⌉ / ⌊n/2⌋), a kézi korrekció pedig játékosonként, a
`Roster.moveToOtherTeam`-mel történt. Az application-réteg ehhez igazodott
(`GameSetup(names, roster)` + `addName`/`removeName`/`drawTeams`/
`moveToOtherTeam`).

A presentation-terv (a felhasználó UI-vázlata) ettől eltérő setup-élményt kíván:

- **két külön csapat-input** ("Első csapat" / "Második csapat"), ahol a nevet
  közvetlenül a kívánt csapatba írjuk;
- ha **csak az első csapat** kap nevet → a rendszer véletlenül, egyenlően
  szétosztja (a korábbi auto-split viselkedés);
- ha **mindkét csapat** kap nevet → azok a kézzel összeállított csapatok, akár
  egyenlőtlen létszámmal is (a felhasználó döntése);
- a névbevitel után egy **áttekintő képernyő** mutatja a kész csapatokat, és
  onnan indul a játék.

A domain (`DrawTeams`, `Roster`, `Player`) mindkét igényt lefedi; a különbség a
setup-UX és az application-réteg állapotgépe. A `moveToOtherTeam`-alapú
"sorsolj-majd-igazíts" korrekció a bulin körülményes, ha eleve eldöntött
csapatok vannak (több embert kell egyesével átdobni).

## Döntés

### 1. Setup: két névlista, kereszt-egyediséggel

A `GameSetup` állapot két névlistát tart: `firstNames` és `secondNames`. A nevek
trimmeltek, nem üresek, és **a két listán keresztül is egyediek** (egy név csak
egy csapatban lehet). A bevitel csapatonként történik: `add(name, team)` /
`remove(name, team)`.

### 2. IGYUNK: feltételes csapatalkotás

Az "IGYUNK" (a setup-képernyő fő gombja) a `proceed()` akciót hívja:

- ha `secondNames` üres és `firstNames` legalább két nevet tartalmaz →
  `DrawTeams(firstNames)` véletlen, egyenlő felosztás (auto-split);
- egyébként (mindkét lista nem üres) → **kézi** `Roster`: a `firstNames` a
  `Team.first`-be, a `secondNames` a `Team.second`-be kerül, változatlanul.

Az aktiválási feltétel (`GameSetup.canProceed`) pontosan e két eset diszjunkciója.
Az eredmény egy köztes `GameTeams` állapot, amely tárolja a kész `Roster`-t és egy
`wasAutoSplit` jelzőt.

### 3. Áttekintő képernyő: `GameTeams`

A `GameTeams` a kész csapatokat mutatja; a "KEZDÉS" a `start()`-tal a játékba lép
(`GamePlaying`). Két további művelet:

- **újrasorsolás** (`redraw()`) — csak `wasAutoSplit == true` esetén; a keret
  neveiből új `DrawTeams`-felosztás;
- **vissza a setupra** (`backToSetup()`) — a keret két csapatából visszaállítja a
  `firstNames`/`secondNames` listákat szerkesztésre.

Egyéni játékos-átmozgatás (a régi `moveToOtherTeam` a review-képernyőn) v1-ben
**nincs**: a kézi csapatot a bevitelnél állítjuk össze. A `Roster.moveToOtherTeam`
a domainben marad, későbbi felhasználásra.

### 4. Állapotgép

```
GameSetup(firstNames, secondNames)
    │  proceed()  (IGYUNK)
    ▼
GameTeams(roster, wasAutoSplit)  ── redraw() ──┐  (csak auto-split)
    │  start()  (KEZDÉS)     ◄─────────────────┘
    │  backToSetup()  ──►  GameSetup
    ▼
GamePlaying(state, card, roster)
    │  next()  (kártya)
    │  quit()  ──►  GameTeams(roster, wasAutoSplit: false)
```

A `DrawTeams`/`StartGame`/`DrawNext` use case-ek és a seedelt `Random` továbbra is
providerekből jönnek (tesztben felülírhatók); a determinizmus változatlan. A futó
játék sablonjai a `start()`-nál pillanatképként rögzülnek, hogy a háttér-frissítés
ne cserélje ki a paklit menet közben.

## Következmények

- A domain érintetlen: `DrawTeams`, `Roster`, `Player` változatlanul
  újrahasznosul; csak az application-réteg `GameSession`/`GameSessionNotifier`
  cserélődik.
- A korábbi lapos-listás setup-API (`addName`/`removeName`/`drawTeams`/
  `moveToOtherTeam` a notifieren) megszűnik; az `ARCHITECTURE.md` 6. fejezete
  ehhez igazodik.
- Az egyenlőtlen kézi csapatok megengedettek (a ⌈n/2⌉/⌊n/2⌋ garancia csak az
  auto-splitre vonatkozik); a `Roster.isStartable` (mindkét csapatban ≥ 1 fő) az
  egyetlen indítási feltétel.

## Elvetett alternatívák

- **A lapos-listás modell megtartása + kézi átmozgatás** — elvetve: a bulin
  körülményes eleve eldöntött csapatoknál, és nem illik a felhasználó
  UI-tervéhez.
- **`GameTeams` áttekintő nélkül, közvetlen setup→játék** — elvetve: a felhasználó
  a kész csapatokat a kezdés előtt látni akarja (gyors korrekció, "vak" kezdés
  elkerülése).
- **Egyéni átmozgatás az áttekintőn v1-ben** — elhalasztva: a kézi összeállítás a
  bevitelnél megvan; a `Roster.moveToOtherTeam` a domainben marad.
