# Igyál 2 — Architektúra

**Ez a dokumentum a projekt viszonyítási pontja („north star").** Minden
architekturális kérdésben ez az irányadó. Módosítása docs-first folyamattal
történik: ADR a `docs/decisions/` alatt → e dokumentum szinkronizálása → kód,
külön commitokban.

Kapcsolódó ADR-ek:

- [ADR-0001](docs/decisions/0001-task-template-schema.md) — task-template séma
  és megkötés-modell.

## 1. Hatókör

**v1 cél** — a teljes core loop egyetlen Android-eszközön (sideload APK):

- Setup: játékosnevek felvétele, csapatbeosztás (véletlen sorsolás vagy kézi
  korrekció), indítás.
- Kártyafolyam: teljes képernyős feladatkártyák, bárhova koppintás = következő
  kártya, nincs visszalépés, nincs pontozás. A játék addig fut, amíg a
  játékosok ki nem lépnek.
- Tartalom: verziózott JSON (bundled asset + távoli statikus másolat),
  offline-first.

**Nem-célok v1-ben:** pontozás, appon belüli tartalomszerkesztő, többeszközös
játék, iOS. A v0 gyűjtő (`igyal_web`) szándékosan nincs összekötve az appal; a
v2 webes szerkesztő tervezett — csak a varratait építjük ki (7. fejezet),
magát nem.

**Vezérelvek:**

- **Részeg felhasználók.** Nagy tapintható felületek, nagy, magas kontrasztú
  tipográfia (sötét szobában is olvasható), halálosan egyszerű flow;
  destruktív művelet csak megerősítéssel.
- **Offline-first.** A tartalomletöltés soha nem blokkolja és nem degradálja a
  játékot; házibulin nincs megbízható hálózat.
- **A játékoslista játék közben sérthetetlen.** Véletlen visszalépés vagy
  törlés nem teheti tönkre a bulit.

## 2. Rétegstruktúra

```
lib/
  main.dart
  src/
    domain/         # tiszta Dart: entitások, sablonmotor, sorsolás, validáció
    data/           # TaskTemplateSource implementációk, repository, cache
    application/    # Riverpod providerek, Notifierek, use case-vezérlés
    presentation/   # képernyők, widgetek, téma
  l10n/             # ARB fájlok
assets/
  content/tasks.json
docs/
  decisions/        # ADR-ek (NNNN-slug.md)
```

Függőségi irány befelé: presentation → application → domain; data → domain. A
data-implementációkat az application köti be providereken keresztül (DIP;
tesztben provider-override).

**Domain-tisztaság:** a domain rétegben megengedett import kizárólag
`dart:core`, `dart:convert`, `dart:math`, más domain-fájl és — egyetlen
indokolt kivételként — a `package:meta` (annotáció-only, pl. `@immutable`;
a Dart SDK szállítja, futásidejű viselkedése nincs). Tilos: Flutter,
`dart:io`, minden más külső csomag, bármely másik réteg. Betartatás:
fegyelem + lint + a `domain_purity_test` guard, ami a `lib/src/domain/`
fájljait scanneli tiltott importokra (a domain-tesztek nem importálnak
Fluttert a domain-forrásba).

## 3. Domain-modell

- `Team` — enum: `first`, `second`. A domain szándékosan semleges neveket
  használ szín helyett; a megjelenített csapatszín (piros/kék) és a
  lokalizált címke („piros csapat", „kék csapat") tisztán presentation-/
  l10n-felelősség. A domain csak az enum-értéket ismeri.
- `Player` — immutable: `name` (trimmelt, nem üres, a játékoslistán belül
  egyedi), `team`.
- `Roster` — immutable setup-aggregátum: a játékosok listája
  csapat-hovatartozással; a csapatnézetek (`first`, `second`) és az
  `isStartable` (mindkét csapat ≥ 1 fő) a `Player.team`-ből származnak, a
  kézi korrekció (`moveToOtherTeam`) egyetlen mezőt billent.
- `TaskType` — enum a gyűjtő hat típusával: `jatek`, `parbaj`, `virus`,
  `feladat`, `activity`, `egyeb`. Tisztán prezentációs kategória (badge/szín),
  játéklogikát nem hordoz (ADR-0001).
- `SlotConstraint` — sealed/enum: `anyone`, `sameTeam`, `oppositeTeams`,
  `wholeTeam`, `everyone`.
- `TaskTemplate` — immutable: `id`, `type`, `constraint`, `playerCount`,
  `text`.
- `TaskContent` — validált egész: `version` + a sablonok listája.
- `GameState` — immutable, `copyWith`: keret (`List<Player>`), hátralévő pakli
  (template-id-k kevert sorrendben), `appearanceCounts` (név →
  megjelenésszám), az előző kártyán név szerint szereplő játékosok, az utolsó
  `wholeTeam`-kártya csapata.
- `ResolvedCard` — a motor kimenete: `templateId`, `type`, feloldott szöveg.
- `Result<T, E>` — sealed Success/Failure a várható hibákra (JSON-parszolás,
  tartalom-validáció). Kivétel csak programozói hibára és
  infrastruktúra-hibára.

## 4. Task-template JSON séma (1. verzió)

A döntést és az elvetett alternatívákat az ADR-0001 rögzíti; itt a normatív
specifikáció.

```json
{
  "version": 1,
  "templates": [
    {
      "id": "jatek-001",
      "type": "jatek",
      "constraint": "anyone",
      "playerCount": 1,
      "text": "{p1} igyon kettőt, ha ma már káromkodott!"
    },
    {
      "id": "feladat-002",
      "type": "feladat",
      "constraint": "sameTeam",
      "playerCount": 2,
      "text": "{p1} és {p2} cseréljen el egy ruhadarabot!"
    },
    {
      "id": "parbaj-003",
      "type": "parbaj",
      "constraint": "oppositeTeams",
      "playerCount": 2,
      "text": "{p1} és {p2} szkanderezzen, a vesztes igyon kettőt!"
    },
    {
      "id": "virus-004",
      "type": "virus",
      "constraint": "wholeTeam",
      "playerCount": 0,
      "text": "A {team} minden tagja igyon egyet!"
    },
    {
      "id": "egyeb-005",
      "type": "egyeb",
      "constraint": "everyone",
      "playerCount": 0,
      "text": "Mindenki igyon egyet, aki ült már repülőn!"
    }
  ]
}
```

### Mezők

| Mező | Típus | Szabály |
|---|---|---|
| `version` | int | kötelező; jelenleg támogatott érték: 1 |
| `templates` | lista | kötelező, nem üres |
| `id` | string | kötelező, nem üres, fájlon belül egyedi, stabil editori azonosító |
| `type` | string | a hat típus-slug egyike |
| `constraint` | string | az öt megkötés egyike |
| `playerCount` | int | a megkötés szabálya szerint (lásd lent) |
| `text` | string | kötelező, nem üres; placeholder-szabályok lent |

### Az öt megkötés szemantikája

| `constraint` | `playerCount` | Feloldás |
|---|---|---|
| `anyone` | ≥ 1 | playerCount különböző játékos, csapattól függetlenül |
| `sameTeam` | ≥ 2 | egy sorsolt csapat playerCount különböző tagja |
| `oppositeTeams` | = 2 | `{p1}` és `{p2}` ellentétes csapatokból; hogy `{p1}` melyikből jön, véletlen |
| `wholeTeam` | = 0 | nincs játékos-slot; a `{team}` egy sorsolt csapat címkéjére oldódik fel |
| `everyone` | = 0 | nincs placeholder; a szöveg mindenkire vonatkozik |

### Placeholder-szabályok

- Játékos-placeholderek: `{p1}` … `{pN}`, ahol N = `playerCount`. A szövegben
  mindegyik legalább egyszer szerepel, hézag és többlet nélkül (`{p1}` és
  `{p3}` `{p2}` nélkül → hiba).
- `{team}` kizárólag `wholeTeam`-sablonban szerepelhet, ott legalább egyszer.
- Más `{…}` token nem megengedett.
- Írási konvenció `wholeTeam`-hez: a névelőt a sablon írja („A {team} minden
  tagja…"), a feloldás kisbetűs címkét ad („piros csapat"), így a magyar
  névelő mindig „A".

### Validáció

Domain-feladat, tiszta függvény: nyers JSON string →
`Result<TaskContent, List<ContentValidationError>>`. Minden hibát összegyűjt
(editori hasznosság), nem az első hibánál áll meg. **Mindent-vagy-semmit:**
egyetlen érvénytelen sablon a teljes tartalmat érvényteleníti — hibás tartalom
sosem kerül részlegesen használatba; a pipeline ilyenkor a korábbi érvényes
tartalmat szolgálja ki (7. fejezet).

Hibaosztályok (sealed): `MalformedJson` (dokumentum-szintű JSON-/
szerkezethiba), `MalformedTemplate` (sablonszintű strukturális hiba: hiányzó
vagy rossz típusú kötelező mező), `UnsupportedVersion`, `EmptyTemplateList`,
`DuplicateId`, `UnknownType`, `UnknownConstraint`, `InvalidPlayerCount`,
`PlaceholderMismatch` (hiányzó, többlet, ismeretlen vagy rossz helyű token),
`BlankText`. A sablonhoz kötött hibák hordozzák az érintett `id`-t (ha
kiolvasható volt), a dokumentum-szintűek `null` `templateId`-t adnak.

Nem támogatott `version` → `unsupportedVersion`: az app elutasítja és logolja,
nem crashel. Sémabővítés = verzióemelés + új ADR.

### Forrásfüggetlenség

A séma és a domain-modell semmit nem feltételez a tartalom eredetéről (nincs
benne URL, fájlnév, DB-fogalom). Ez a v2-készség architekturális garanciájának
séma-oldali fele; a réteghatár-oldali felét a 7. fejezet rögzíti.

## 5. Sablonmotor

Tiszta függvények immutable bemeneteken; minden véletlenszerűség injektált
`Random`-ból jön (élesben `Random()`, tesztben seedelt) → minden viselkedés
determinisztikusan tesztelhető.

### Pakli-elv

- Játékindításkor a játszható sablonokból pakli épül: az id-k megkeverve;
  húzás ismétlés nélkül; kimerüléskor újrakeverés.
- Újrakeverési határon nincs kártyaismétlés: ha a pakli mérete > 1, az új
  keverés első lapja nem egyezhet meg az előző kártyával.

### Játszhatósági szűrő

A pakli csak az aktuális kerettel kielégíthető sablonokat tartalmazza:

- `anyone`: összjátékosszám ≥ playerCount;
- `sameTeam`: a nagyobbik csapat létszáma ≥ playerCount;
- `oppositeTeams`: mindkét csapat ≥ 1 fő (az indítási feltétel garantálja);
- `wholeTeam`, `everyone`: mindig játszható.

A kiszűrt sablonok logolódnak (debug). Üres játszható pakli → domain-hiba
(`Result`), a presentation jelzi; a bundled tartalom tesztje garantálja, hogy
1v1 kerettel is van játszható sablon, így élesben nem fordulhat elő.

### Fair játékosválasztás — invariánsok

1. Csak a megkötésnek megfelelő játékosok jöhetnek szóba.
2. A választás a megjelenésszámmal fordítottan súlyozott (súly ∝
   1 / (1 + megjelenésszám)) → hosszú távon mindenki nagyjából egyenlően
   szerepel, és minden jogosult játékos valószínűsége pozitív marad.
3. Nincs közvetlen ismétlés: az előző kártyán név szerint szereplő játékosok
   kizárva, ha a megkötés a maradék játékosokból is kielégíthető; ha nem (pl.
   1v1 keret), a kizárás feloldódik.
4. A megjelenésszám csak név szerinti szereplést számol (`anyone`, `sameTeam`,
   `oppositeTeams`). `wholeTeam`/`everyone` kártya nem növeli az egyéni
   számlálókat, és utána a következő kártyára nem vonatkozik egyéni kizárás.
5. `sameTeam`: a csapat a playerCount-ot kielégítő csapatok közül
   véletlenszerűen sorsolódik; a tagok a 2–3. pont szerint.
6. `wholeTeam`: a csapat egyenletes véletlennel sorsolódik, de két egymást
   követő `wholeTeam`-kártya nem találhatja el ugyanazt a csapatot.

### Feloldás

`drawNext(GameState, templatesById, teamLabels, Random) →
(ResolvedCard, GameState)` jellegű tiszta lépés. A
`teamLabels: Map<Team, String>` a hívótól (application, l10n-ből) érkezik — a
domain lokalizáció-agnosztikus marad.

## 6. Csapatsorsolás

A use case a `DrawTeams` (`Roster call(List<String> names, Random
random)`); a kimenet egy `Roster`. Az újrasorsolás a `call` ismételt
hívása, a kézi korrekció a `Roster.moveToOtherTeam`.

- Bemenet: érvényes játékoslista (trimmelt, nem üres, egyedi nevek) és
  injektált `Random`.
- Véletlen sorsolás: keverés, majd ⌈n/2⌉ / ⌊n/2⌋ felosztás; páratlan
  létszámnál véletlen, melyik csapat kap eggyel több tagot.
- Újrasorsolás: független ismételt hívás.
- Kézi korrekció: játékos áthelyezése a másik csapatba a setup-képernyőn. A
  ⌈n/2⌉/⌊n/2⌋ garancia a véletlen sorsolásra vonatkozik; a kézi szerkesztés
  felboríthatja az egyensúlyt — ez megengedett.
- Indítási feltétel (a „Kezdés" gomb aktív): mindkét csapatban legalább 1 fő.
  Más korlát nincs.

## 7. Tartalom-pipeline

### Források és absztrakció

A tartalomforrást a data-rétegbeli `TaskTemplateSource` interfész absztrahálja
(nyers JSON-t ad, `Result`-tal). Implementációk v1-ben:

- `BundledAssetTaskTemplateSource` — `assets/content/tasks.json`;
- `CachedFileTaskTemplateSource` — lokális cache-fájl az app
  adatkönyvtárában;
- `RemoteTaskTemplateSource` — statikus hosting (raw.githubusercontent.com /
  GitHub Pages), az URL a data-réteg konfigurációjában él.

Az orchestráció a data-rétegbeli repositoryban (`TaskContentRepository`):
forrás → domain-validáció → domain-entitások. **A domain és az application
kizárólag validált `List<TaskTemplate>`-et lát.** Forrás-specifikus fogalom
(URL, HTTP, cache-fájl) nem léphet át ezen a határon.

**v2-garancia:** a v2 backend (elsődleges jelölt: a saját VPS-en futó gyűjtő
validált task-JSON-endpointtá fejlesztése; fallback: Supabase — külön ADR a
milestone indulásakor) bevezetése pontosan egy data-rétegbeli implementáció
cseréje vagy hozzáadása; a domaint és a presentationt nem érinti.

### Betöltési és frissítési folyamat

- Olvasási sorrend a játéktartalomhoz: érvényes cache → bundled asset. A cache
  olvasáskor is validálódik; érvénytelen cache (sérült fájl, nem támogatott
  verzió) figyelmen kívül marad és törlődik, a bundled asset szolgál ki.
- App-induláskor háttérben, fire-and-forget frissítés: fetch (rövid
  timeouttal) → validálás → **atomi cache-csere** (temp fájlba írás + rename).
  Bármely lépés hibája némán (logolva) elnyelődik; a játék a meglévő
  tartalommal fut. A frissítés soha nem blokkolja és nem késlelteti a UI-t.
- **A játék teljes értékűen fut offline** — hálózat nélkül a cache vagy a
  bundled asset szolgál.

### Editori leképzés (v0 gyűjtő → séma)

A gyűjtő exportjából (`/export.json` vagy SQLite) jövő nyersanyagot a user
kézzel kurálja a séma szerinti tartalommá — editori lépés, nem applogika.
Konvenciók: X → `{p1}`, Y → `{p2}`; a gyűjtőbeli típus átvihető `type`-ként; a
`constraint`-et a tartalom alapján az editor választja (egy „párbaj"
jellemzően `oppositeTeams`, de ez nem sémaszabály).

## 8. Perzisztencia

- `shared_preferences`: kizárólag az utolsó játékoslista nevei (kényelmi
  prefill a setup-képernyőn). Játékindításkor íródik; a csapatbeosztás nem
  perzisztálódik.
- Futó játékállapot in-memory. Process death elveszti a futó játékot — vállalt
  v1 trade-off; a prefillelt nevek miatt az újraindítás néhány koppintás.
- A véletlen megsemmisítés elleni védelem a presentationben:
  kártyafolyamból kilépés és játékoslista-törlés csak megerősítéssel
  (10. fejezet).

## 9. Állapotkezelés (application réteg)

- Riverpod classic stílusban, codegen nélkül: kézzel deklarált `Provider` /
  `NotifierProvider`.
- A data-implementációk providereken keresztül kötődnek be (DIP); tesztben
  provider-override.
- A use case-ek `T call(Input input)` alakú, domainre épülő egységek; a
  Notifierek vékonyak: állapotot tartanak és domain-függvényeket hívnak.
- A `Random` providerből jön (élesben `Random()`, tesztben seedelt) — a
  determinizmus a widget-tesztekig ér.

## 10. Prezentáció

- Képernyők: Setup (nevek + csapatok + „Kezdés") → Kártyafolyam.
- Kártyafolyam: teljes képernyős kártya, bárhova koppintás = következő; nincs
  visszalépés; a rendszer-visszagomb `PopScope`-pal elfogva, kilépés csak
  megerősítő dialógussal.
- Részeg-UX: nagy tapintható felületek, nagy és magas kontrasztú tipográfia,
  type-alapú kártyaszín/badge, csapatszínek (piros/kék) a setupon.
- i18n: ARB-fájlok (`l10n/`), `gen_l10n`; v1-ben csak magyar, de minden
  UI-string ARB-ből jön.

## 11. Minőségkapuk

- Lint: `very_good_analysis`; az analyze `--fatal-infos --fatal-warnings`
  kapcsolókkal fut.
- Formátum: `dart format`, page_width 100 (az `analysis_options.yaml`
  formatter szekciójában). A very_good alapértelmezett
  `lines_longer_than_80_chars` lintje **ki van kapcsolva**: a formatter
  100-ig egy sorba tördel, a 80 oszlopos lint viszont ez alatt panaszkodna,
  így a kettő egymásnak feszülne és nem lenne egyszerre kielégíthető. A
  mérvadó sorhossz egységesen 100; a formatter és a linter így egyetért,
  nincs kézi 80-as igazítgatás (eltérés a Foretack `final`-be emelős
  konvenciójától, tudatosan).
- Pre-flight minden commit előtt (nincs Melos, közvetlen parancslánc):

```bash
flutter analyze --fatal-infos --fatal-warnings \
  && dart format --output=none --set-exit-if-changed . \
  && flutter test
```

- CI (GitHub Actions): ugyanez a hármas fut minden pushra és PR-re.

## 12. Tesztstratégia

- **Domain-lefedettség ≥ 95%.** A sablonmotor és a csapatsorsolás minden
  megkötés-kombinációra és élhelyzetre tesztelt: 1v1 minimum, páratlan
  létszám, az aktuális kerettel kielégíthetetlen megkötés, pakli-kimerülés +
  újrakeverés (a határon átívelő ismétlés tilalma), fairness-eloszlás seedelt
  RNG-vel, a közvetlen játékosismétlés tilalma és annak feloldása 1v1-nél.
- Validáció-tesztek minden hibaosztályra (ismeretlen verzió/típus/megkötés,
  placeholder-eltérés, duplikált id, üres szöveg, hibaösszegyűjtés).
- AAA / Given-When-Then szerkezet; viselkedést tesztelünk, nem implementációt;
  a tiszta domain-kódhoz nincs mock.
- Widget-tesztek (könnyűek): setup-validáció (üres/duplikált név,
  Kezdés-feltétel) és a kártyaléptetési flow.
- Tartalom-teszt: a bundled `assets/content/tasks.json` a valódi validátoron
  fut át, és garantálja, hogy 1v1 kerettel is van játszható sablon → hibás
  tartalom nem shippelhető.
- Lefedettség mérése: `flutter test --coverage` + lcov, a domain-fájlokra;
  a küszöb CI-be emelése későbbi opció.

## 13. Verziókezelés és ADR-folyamat

- `main` mindig zöld; `feature/`, `bugfix/`, `refactor/` ágak.
- Conventional Commits angolul: subject ≤ 72 karakter, felszólító mód, nincs
  záró pont; nem triviális commithoz kötelező body (mit + miért).
- Egy commit = egy logikai változás; szelektív `git add <fájlok>` (soha `-A`);
  commit `git commit -F - <<'MSG'` heredoccal.
- Docs-first: ADR (`docs/decisions/NNNN-slug.md`) → `ARCHITECTURE.md` sync →
  kód, külön commitokban. Várhatóan 5–10 ADR összesen; a v2 backend-választás
  saját ADR-t kap a milestone indulásakor.
- Session-kezdés: `git fetch && git pull` + állapot-ellenőrzés; szerkesztés
  előtt a tényleges fájltartalom ellenőrzése (verify-before-acting).
