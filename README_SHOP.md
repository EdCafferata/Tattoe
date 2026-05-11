# Tattoe App — Shop

Alles wat de shop-rol doet, bevat en kan instellen.

---

## Navigatiestroom

```
ShopFlowView
├── Niet ingelogd                        → ShopLoginView
├── Ingelogd, geen naam                  → ShopNAWView
├── Ingelogd, geen abonnementType        → ShopAbonnementKiezenView
├── Ingelogd, abonnement verlopen        → ShopAbonnementVerlopenView
└── Alles in orde                        → ShopModeKeuzeView
                                              ├── ALS KLANT  → ShopAlsKlantView
                                              └── SHOP BEHEREN → ShopDashboardView
```

---

## Schermen

### ShopLoginView / ShopEmailLoginView / ShopEmailRegisterView
- Zelfde patroon als Artiest en Klant
- Registratieformulier bevat extra zakelijke velden:
  - Bedrijfsnaam, KVK-nummer, BTW-nummer
  - Voornaam, achternaam, e-mail, wachtwoord
  - Telefoonnummer, adres

### ShopNAWView
- Zakelijke gegevens aanvullen na Apple login
- Secties: BEDRIJF, ACCOUNT, ADRES
- Account verwijderen knop

### ShopAbonnementKiezenView
- Koptekst: "KIES JE PLAN"
- Subtitel: "30 dagen gratis uitproberen"
- Vier AbonnementPlanKaart components (Starter, Studio, Pro, Enterprise)
- Knop "GRATIS STARTEN" voor Starter/Studio/Pro → trial start direct
- Knop "NEEM CONTACT OP" voor Enterprise → opent e-mailclient met vooringevulde tekst
- Trial van 30 dagen start automatisch bij keuze

### ShopAbonnementVerlopenView
- Zelfde plankaarten maar knop heet "STARTEN"
- Huidig geselecteerde plan is gemarkeerd
- Enterprise → e-mail contact

### ShopModeKeuzeView
- Winkelicoon + naam + locatie
- Plan badge (bijv. "STUDIO") + "X dagen gratis" als trial actief is
- Twee keuzes:
  - **ALS KLANT** — Klantweergave van de shop bekijken
  - **SHOP BEHEREN** — Afspraken, artiesten en instellingen beheren
- UITLOGGEN knop

### ShopDashboardView
Beheerscherm:
- **Koptekst:** shopnaam, locatie, knoppen AANPASSEN, BEHEER, UITLOGGEN
- **BERICHTEN** sectie (met ongelezen count)
- **AFSPRAKEN** sectie (openstaande aanvragen)
- **ARTIESTEN** sectie: lijst van artiesten gekoppeld aan dit shop (via CloudKit)
- **INFO** sectie: telefoon, adres, KVK, BTW
- AandachtBanner bovenaan zichtbaar als `aandacht > 0`

### ShopAlsKlantView
Hoe het shop eruitziet voor klanten:
- Winkelicoon, naam, locatie
- Badge "KLANTWEERGAVE"
- Lijst van artiesten in dit shop
- CONTACT sectie: telefoon, adres

### ShopAfsprakenView
- Lijst van alle afspraken via shop e-mail of artiest e-mail
- Naam klant, datum/tijd, notitie, status
- **Status labels voor shop:**
  - `aangevraagd` → OK / NEE knoppen
  - `arties_akkoord` → OK / NEE knoppen ("Artiest akkoord – jouw beurt")
  - `wacht_klant` → "Wacht op bevestiging klant"
  - `bevestigd` → Agenda + Printen + Afzeggen knoppen
- Bevestigingsdialoog bij afzeggen

### ShopBerichtenView
- Berichten gesorteerd op datum
- Kleurgecodeerd per type
- Tap → markeer als gelezen

### ShopBeheerView
Administratiescherm (bereikbaar via BEHEER knop in dashboard):

**Jaarkiezer**
- Huidig jaar + 4 voorgaande jaren

**Statistieken (voor gekozen jaar)**
- Totaal afspraken
- Bevestigd afspraken
- Drukste maand
- Klant met meeste afspraken

**Maandoverzicht**
- Per maand: aantal afspraken + aantal bevestigd

**Export knoppen**
- **CSV exporteren** → `exportAfsprakenCSV()` → share sheet
  - Kolommen: Datum; Tijd; Klant naam; Klant e-mail; Artiest e-mail; Shop e-mail; Status; Notitie
  - UTF-8 BOM voor Excel-compatibiliteit
  - Gesorteerd op datum oplopend
- **PDF jaar overzicht** → A4 PDF per maand met afsprakenlijst → share sheet

---

## Abonnementen & trial

### Trial
- Duur: **30 dagen** vanaf `registratieDatum`
- `trialActief`: true als < 30 dagen na registratie
- `dagenResterend`: aantal resterende dagen
- `heeftToegang`: true als (betaald abonnement actief) OF (trial actief)

### Plannen

| Plan | Prijs | Artiesten | Sessies | Shops |
|---|---|---|---|---|
| STARTER | €9,99 / maand | 1 | 1 apparaat | 1 |
| STUDIO | €49,99 / maand | 10 | 2 apparaten | 1 |
| PRO | €99,99 / maand | Onbeperkt | Onbeperkt | 1 locatie |
| ENTERPRISE | Op aanvraag | Onbeperkt | Onbeperkt | Meerdere |

### StoreKit 2

- Product IDs: `info.cafferata.tattoe.sub.starter` / `.studio` / `.pro`
- Type: **Auto-renewable subscription** (via App Store Connect subscription group)
- `controleerAbonnementen()` — Herstelt actieve subscriptions bij opstart/herinstallatie
- `koopAbonnement(planId:)` — Start App Store aankoopdialoog
- `verwerkTransactie(_ tx:)` — Verwerkt verlenging én intrekking (refund)
- `activeerAbonnement(type:)` — Zet `abonnementActief = true` + slaat type op
- Transactielistener actief als `Task.detached` op achtergrond
- Intrekking detectie: `tx.revocationDate != nil` → `abonnementActief = false`

---

## State (ShopStore)

| Property | Type | Beschrijving |
|---|---|---|
| `shop` | `Shop?` | Ingelogd profiel |
| `isLoggedIn` | `Bool` | Authenticatiestatus |
| `isCheckingCloud` | `Bool` | CloudKit sync bezig |
| `berichten` | `[Bericht]` | Ontvangen berichten |
| `afsprakenaandacht` | `Int` | Afspraken die aandacht vragen |
| `ongelezen` | `Int` (computed) | Ongelezen berichten |
| `aandacht` | `Int` (computed) | `ongelezen + afsprakenaandacht` (voor badge) |
| `trialActief` | `Bool` (computed) | Trial nog actief |
| `dagenResterend` | `Int` (computed) | Resterend trialdagen |
| `heeftToegang` | `Bool` (computed) | Heeft toegang (betaald of trial) |

---

## Functies (ShopStore)

| Functie | Wat het doet |
|---|---|
| `save(_ shop:)` | Lokaal opslaan + CloudKit sync |
| `saveLocal(_ shop:)` | Alleen lokaal (DEBUG) |
| `kiesAbonnement(type:)` | Eerste plankeuze + start trial |
| `controleerAbonnementen()` | Herstel actieve StoreKit subscriptions |
| `koopAbonnement(planId:)` | Koop via App Store (geeft Bool terug) |
| `verwerkTransactie(_ tx:)` | Verwerk verlenging / intrekking |
| `activeerAbonnement(type:)` | Zet betaald abonnement actief |
| `keurAfspraakGoed(_ a:)` | Afspraak goedkeuren → bericht naar partijen |
| `weigerAfspraak(_ a:)` | Afspraak weigeren |
| `annuleerAfspraak(_ a:)` | Afspraak afzeggen |
| `laadAfsprakenaandacht()` | Telt `aangevraagd` + `arties_akkoord` afspraken |
| `updateBadge()` | Badge instellen op `aandacht` |
| `syncNu()` | Directe sync (na moduswissel) |
| `markeerGelezen(_ id:)` | Bericht gelezen markeren |
| `verwijderAccount()` | Account verwijderen |

---

## CloudKit interacties

| Actie | Methode |
|---|---|
| Shopprofiel opslaan | `CloudKitManager.shared.saveShop()` |
| Publiek profiel opslaan | `CloudKitManager.shared.savePubliekShop()` |
| Shopprofiel ophalen | `CloudKitManager.shared.fetchShop()` |
| Berichten ophalen | `CloudKitManager.shared.fetchBerichten(email:)` |
| Afspraken ophalen | `CloudKitManager.shared.fetchAfspraken(shopEmail:)` |
| Afspraakstatus bijwerken | `CloudKitManager.shared.updateAfspraakStatus()` |
| Bericht sturen | `CloudKitManager.shared.saveBericht()` |
| Account verwijderen | `CloudKitManager.shared.verwijderShop()` |

---

## Sync

- Achtergrond sync elke **5 minuten** via `syncVanCloud()` (sneller dan artiest/klant)
- Haalt bij: bijgewerkte afspraakstatussen + berichten
- `syncNu()` forceert directe sync (bijv. na moduswissel)

---

## Lokale opslag

| Sleutel | Inhoud |
|---|---|
| `UserDefaults: shop_logged_in` | Bool inlogstatus |
| `UserDefaults: shop_data` | JSON van Shop-profiel |
| `UserDefaults: shop_gelezen_berichten` | Set van gelezen bericht-ID's |

---

## Notificaties & badge

- Vraagt toestemming voor **badge-only** bij opstarten
- Badge = `ongelezen + afsprakenaandacht`
- `afsprakenaandacht` telt afspraken met status `aangevraagd` of `arties_akkoord`
- AandachtBanner in dashboard zichtbaar als `aandacht > 0`

---

## Afspraken-workflow (shop)

```
Klant vraagt aan (aangevraagd)
  → Shop en artiest keuren elk goed (volgorde maakt niet uit)
  → Als artiest al akkoord: shop ziet "Artiest akkoord – jouw beurt"
  → Shop keurt goed → status: wacht_klant
  → Klant bevestigt → status: bevestigd
  → Shop kan bevestigde afspraak toevoegen aan agenda, printen, afzeggen
```

---

## Datamodel Shop

| Veld | Type | Beschrijving |
|---|---|---|
| `id` | `String` | UUID |
| `authMethode` | `String` | "apple" of "email" |
| `voornaam`, `achternaam` | `String` | Naam eigenaar |
| `bedrijfsnaam` | `String` | Officiële winkelnaam |
| `kvk` | `String` | KVK-nummer |
| `btw` | `String` | BTW-nummer |
| `email` | `String` | Login e-mail |
| `wachtwoordHash` | `String` | Gehashed wachtwoord |
| `telefoon` | `String` | Telefoonnummer |
| `straat`, `huisnummer`, `postcode`, `stad` | `String` | Adres |
| `abonnementType` | `String` | "starter", "studio", "pro", "enterprise", "" |
| `abonnementActief` | `Bool` | Betaald abonnement actief |
| `registratieDatum` | `Date` | Startdatum trial |

---

## DEV / debug

- `SHOP_TEST_DATA` environment variable injecteert testdata bij opstarten
- TestData.swift levert 4 testafspraken + 3 testberichten voor shop
- Testshop: dragontattoo@test.nl (Dragon Tattoo, Eindhoven)
- Testdata samengevoegd met CloudKit resultaten (deduplicatie op ID)
