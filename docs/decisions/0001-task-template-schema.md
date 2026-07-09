# ADR-0001 — Task-template séma és megkötés-modell

- **Státusz:** elfogadva
- **Dátum:** 2026-07-09

## Kontextus

A teljes sablonmotor (a v1 legkritikusabb domain-területe) a task-template JSON
sémára épül, ezért ez az első és legnagyobb hatású tervezési döntés. Kényszerek:

- Öt slot-megkötést kell kifejezni: `anyone`, `sameTeam`, `oppositeTeams`,
  `wholeTeam`, `everyone`.
- A nyersanyag a v0 gyűjtőből jön: a barátok X/Y játékosnév-konvencióval és hat
  típussal (`jatek`, `parbaj`, `virus`, `feladat`, `activity`, `egyeb`) írnak;
  a séma szerinti tartalommá alakítás kézi editori lépés.
- Forrásfüggetlenség (v2-készség): a séma nem feltételezheti, hogy a tartalom
  fájlból, repóból vagy adatbázisból érkezik.
- A séma verziózott; ismeretlen verziót az app elutasít és logol, nem crashel.

## Döntés

### 1. Sablonszintű megkötés, explicit játékosszámmal

Egy sablon pontosan egy `constraint`-et és egy `playerCount`-ot deklarál; a
szöveg `{p1}` … `{pN}` placeholderekkel hivatkozik a szerepekre (`wholeTeam`
esetén `{team}`-mel).

```json
{
  "id": "parbaj-003",
  "type": "parbaj",
  "constraint": "oppositeTeams",
  "playerCount": 2,
  "text": "{p1} és {p2} szkanderezzen, a vesztes igyon kettőt!"
}
```

Szemantika (normatívan az `ARCHITECTURE.md` 4. fejezetében): `anyone` →
playerCount ≥ 1 különböző játékos; `sameTeam` → playerCount ≥ 2 egy sorsolt
csapatból; `oppositeTeams` → pontosan 2, ellentétes csapatokból; `wholeTeam` →
playerCount = 0, a `{team}` egy sorsolt csapat címkéjére oldódik fel;
`everyone` → playerCount = 0, nincs placeholder.

Indoklás: a gyűjtő X/Y konvenciója a gyakorlatban legfeljebb két megnevezett
szereplőt jelent; erre a sablonszintű modell pontosan elegendő. A validáció
triviális (a szövegbeli placeholder-halmaz azonos a deklarált slotokkal), a
resolver egy exhaustive `switch` a sealed constraint felett, a tesztmátrix
kicsi marad.

### 2. A `type` tisztán prezentációs kategória

A gyűjtő hat típusa megmarad a sémában, de kizárólag megjelenítést vezérel
(kártya-badge/szín); a `constraint`-től teljesen független. A „párbaj →
jellemzően `oppositeTeams`" összefüggés editori konvenció a kurálásnál, nem
sémaszabály. A domainben sealed/enum `TaskType`; ismeretlen érték validációs
hiba.

### 3. Verziózás és mindent-vagy-semmit validáció

Gyökérszintű egész `version` mező (jelenleg: 1). Nem támogatott verzió → a
teljes tartalom elutasítva és logolva. Egyetlen érvénytelen sablon a teljes
fájlt érvényteleníti; a tartalom-pipeline ilyenkor a korábbi érvényes
tartalmat (cache / bundled asset) szolgálja ki. A validációs hibák listaként
gyűlnek össze, nem az első hibánál áll meg a folyamat (editori hasznosság).

Indoklás: a részleges elfogadás (hibás sablonok csendes átugrása) editori
hibákat rejtene el, és nem-determinisztikussá tenné, mi kerül a pakliba. Az
atomi „vagy minden érvényes, vagy semmi" illeszkedik az atomi cache-cseréhez.

## Következmények

Előnyök: egyszerű, teljesen validálható séma; kis, kimerítően tesztelhető
megkötés-mátrix; mechanikus kurálási munka (X → `{p1}`, Y → `{p2}`, típus
átvitele, constraint-választás); a sémában nincs forrás-specifikus fogalom
(URL, fájl, DB), így v2-kész.

Vállalt korlátok:

- Egy sablonon belül nem keverhető megkötés (pl. egy `anyone` + egy `sameTeam`
  pár). Ha valaha tartalmi igény lesz rá, az sémaverzió-emelés és új ADR, nem
  hack.
- `oppositeTeams` fixen kétszereplős; több résztvevős csapatközi feladat
  `wholeTeam`-ként vagy `everyone`-ként fejezhető ki.
- A `type` nem hordoz játéklogikát; a type↔constraint tartalmi összhang
  editori felelősség.

## Elvetett alternatívák

1. **Slot-szintű relációs modell** (megkötések slot-párok között, pl. p1–p2
   `sameTeam`, p3 `anyone`). Kifejezőbb, de a validáció és a fair kiválasztás
   tesztmátrixa többszörösére nő, és jelenleg nincs tartalom, ami igényelné
   (YAGNI). Verzióemeléssel később bevezethető.
2. **A `type` elhagyása.** Egyszerűbb séma, de elveszik a kártya-kategorizálás
   UX-értéke és a gyűjtő taxonómiájával való kontinuitás; visszahozása
   verzióemelést igényelne.
3. **type→constraint csatolás** (a típus determinálja a megkötést). Legitim
   tartalmat tiltana (egy „vírus" lehet `wholeTeam` és `anyone` is), és
   redundáns információt kényszerítene a sémába.
