# Tattoe App — Algemeen

Gedeelde functies, technische keuzes en alles dat niet specifiek bij één rol hoort.

---

## App-architectuur

```
Rol-keuze scherm (ContentView)
├── ARTIEST  → ArtiesFlowView  (ArtiesStore  @StateObject)
├── KLANT    → KlantFlowView   (KlantStore   @StateObject)
└── SHOP     → ShopFlowView    (ShopStore    @StateObject)
```

Elke rol heeft een volledig gescheiden:
- **Store** (`*Store.swift`) — data, CloudKit, authenticatie, sync
- **Flow** (`*Flow.swift`) — SwiftUI views, navigatie, UI

Stores zijn `ObservableObject` met `@Published` properties. Views observeren via `@StateObject` of `@ObservedObject`.

---

## Authenticatie

Beide methoden worden ondersteund voor alle drie rollen:

### Sign in with Apple
- Gebruikt `ASAuthorizationAppleIDProvider`
- `authMethode = "apple"`
- Stuurt Apple User ID naar CloudKit voor account-lookup
- In DEBUG: slaat direct op zonder CloudKit-check

### E-mail / wachtwoord
- `authMethode = "email"`
- Wachtwoord wordt gehashed opgeslagen (nooit plaintext)
- "Wachtwoord vergeten?" flow via `WachtwoordResetView`

---

## CloudKit

Alle data leeft in **CloudKit** (Apple's gratis database voor iOS-apps).

### Databases
- **Privé database**: persoonlijke profieldata (alleen voor de eigenaar)
- **Publieke database**: ontdekkingsprofielen (shops + artiesten, leesbaar voor iedereen)

### Recordtypes
| RecordType | Beschrijving |
|---|---|
| `Arties` | Privé artiest-profiel |
| `PubliekArties` | Publiek ontdekkingsprofiel artiest |
| `Klant` | Privé klant-profiel |
| `Shop` | Privé shop-profiel |
| `PubliekShop` | Publiek ontdekkingsprofiel shop |
| `Afspraak` | Afspraak met status + alle e-mails |
| `Bericht` | Notificatiebericht naar één ontvanger |
| `ArtiestFotos` | Profiel- en portfoliofoto's van artiest |

### Indexes (vereist in CloudKit Dashboard voor productie)
De volgende velden moeten als **queryable index** worden aangemaakt:
- `PubliekArties.email`
- `PubliekShop.email`
- `Afspraak.klantEmail`
- `Afspraak.artiesEmail`
- `Afspraak.shopEmail`
- `Bericht.ontvangerEmail`

---

## Sync tijden

| Rol | Interval | Reden |
|---|---|---|
| Artiest | 10 minuten | Profieldata wijzigt zelden |
| Klant | 10 minuten | Profieldata wijzigt zelden |
| Shop | 5 minuten | Afspraken moeten snel zichtbaar zijn |

### Hoe sync werkt
1. Bij inloggen start `startSync()` een `Task` op de achtergrond
2. De task slaapt X minuten via `Task.sleep(nanoseconds:)`
3. Na het slapen roept hij `syncVanCloud()` aan
4. `syncVanCloud()` haalt profiel, berichten én afsprakenaandacht op
5. Loop herhaalt zich tot `isLoggedIn == false`
6. `syncNu()` (alleen Shop) forceert directe sync zonder te wachten

### Wat wordt gesynchroniseerd
- Bijgewerkt profiel (naam, adres, etc.)
- Nieuwe berichten
- Bijgewerkte afspraakstatussen (voor aandacht-teller)
- Favoriete artiest/shop profiel (alleen Klant)

---

## Afspraak datamodel

| Veld | Type | Beschrijving |
|---|---|---|
| `id` | `String` | UUID |
| `klantEmail` | `String` | E-mail aanvrager |
| `klantNaam` | `String` | Naam aanvrager |
| `artiesEmail` | `String` | E-mail artiest |
| `shopEmail` | `String` | E-mail shop |
| `datum` | `Date` | Datum en tijd |
| `notitie` | `String` | Omschrijving opdracht |
| `status` | `String` | Zie workflow hieronder |

### Afspraak statusworkflow

```
aangevraagd
  ├── Artiest keurt goed  → arties_akkoord
  │     └── Shop ook akkoord → wacht_klant
  ├── Shop keurt goed     → shop_akkoord
  │     └── Artiest ook akkoord → wacht_klant
  ├── Artiest weigert     → geweigerd
  └── Shop weigert        → geweigerd

wacht_klant
  ├── Klant bevestigt → bevestigd
  └── Klant annuleert → geannuleerd

bevestigd
  └── Artiest of shop zegt af → geannuleerd
```

### Statuslabels per rol

| Status | Artiest ziet | Klant ziet | Shop ziet |
|---|---|---|---|
| `aangevraagd` | OK / NEE | "Wacht op artiest/shop" | OK / NEE |
| `arties_akkoord` | — | "Deels goedgekeurd" | OK / NEE (artiest al akkoord) |
| `shop_akkoord` | OK / NEE (shop al akkoord) | "Deels goedgekeurd" | — |
| `wacht_klant` | "Wacht op klant" | BEVESTIGEN knop | "Wacht op klant" |
| `bevestigd` | Agenda / Print / Afzeggen | Print / Annuleer | Agenda / Print / Afzeggen |
| `geannuleerd` | "Afgezegd" | "Geannuleerd" | "Afgezegd" |
| `geweigerd` | "Geweigerd" | "Geweigerd" | "Geweigerd" |

---

## Berichten systeem

Berichten zijn eenrichtingsnotificaties van CloudKit. Elke statuswijziging stuurt een of meer berichten:

| Type | Ontvanger | Wanneer |
|---|---|---|
| `aangevraagd` | Artiest + Shop | Klant vraagt afspraak aan |
| `arties_akkoord` | Shop | Artiest heeft goedgekeurd |
| `shop_akkoord` | Artiest | Shop heeft goedgekeurd |
| `wacht_klant` | Klant | Beide partijen akkoord |
| `bevestigd` | Artiest + Shop | Klant bevestigt |
| `geannuleerd` | Artiest + Shop + Klant | Annulering |
| `geweigerd` | Klant | Weigering |

Berichten worden opgehaald via `fetchBerichten(email:)` en lokaal bijgehouden als gelezen via `UserDefaults`.

---

## App-icon badge

Alle drie rollen gebruiken `UNUserNotificationCenter.current().setBadgeCount()`.

| Rol | Badge telt |
|---|---|
| Artiest | Ongelezen berichten + afspraken status `aangevraagd`/`shop_akkoord` |
| Klant | Ongelezen berichten + afspraken status `wacht_klant` |
| Shop | Ongelezen berichten + afspraken status `aangevraagd`/`arties_akkoord` |

- Toestemmingstype: **badge-only** (geen geluid, geen notificaties)
- Wordt bij elke sync bijgewerkt

---

## AandachtBanner

Gedeeld component (`AandachtBanner.swift`) zichtbaar in alle drie dashboards.

```swift
AandachtBanner(
    berichten: store.ongelezen,
    afspraken: store.afsprakenaandacht,
    onBerichten: { ... },
    onAfspraken: { ... }
)
```

- Wit balkje van 40pt hoogte, bel-icoon links
- Alleen zichtbaar als `berichten + afspraken > 0`
- Tik op berichtendeel → navigeert naar berichten
- Tik op afsprakendeel → navigeert naar afspraken

---

## PDF generatie (AfspraakPDF.swift)

### deelAfspraak(_ a:, afdrukVoor:)
Maakt PDF en opent iOS share sheet. Share sheet bevat standaard: Preview, Print, Markup, Copy, Save to Files.

### maakAfspraakPDF(_ a:, afdrukVoor:)
A4 formaat (595 × 842 pt). Layout:
- Koptekst: "TATTOE" + lijn + "AFSPRAAKBEVESTIGING"
- Sectie DATUM & STATUS
- Sectie KLANT (naam + e-mail)
- Sectie ARTIEST (e-mail, alleen als niet leeg)
- Sectie SHOP (e-mail, alleen als niet leeg)
- Sectie NOTITIE / OPDRACHT (vrije tekst)
- Sectie AFDRUK VOOR (optioneel, bijv. "Jim Orie")
- Voettekst: "Gegenereerd op [datum] via Tattoe App"

Datumformaat in PDF: `EEEE d MMMM yyyy 'om' HH:mm` (bijv. "woensdag 12 mei 2026 om 14:30")

### exportAfsprakenCSV(_ afspraken:, jaar:)
Voor Shop Beheer / belastingdienst export:
- Scheidingsteken: puntkomma (;) voor Excel-compatibiliteit
- Encoding: UTF-8 met BOM (`0xEF 0xBB 0xBF`) — zodat Excel accenten correct toont
- Kolommen: Datum; Tijd; Klant naam; Klant e-mail; Artiest e-mail; Shop e-mail; Status; Notitie
- Gesorteerd op datum oplopend
- Bestandsnaam: `tattoe_afspraken_{jaar}.csv`
- Opgeslagen in tijdelijke map (`FileManager.default.temporaryDirectory`)

---

## Afbeeldingen

- Formaat: JPEG
- Maximale resolutie: 1080 × 1080 px
- Compressiekwaliteit: 0.8
- Opgeslagen als lokaal bestand én geüpload naar CloudKit
- Artiesten: profielfoto + 9 portfolio + 9 voorbeeldtattoos

---

## Wachtwoord reset

`WachtwoordResetView` is gedeeld door alle drie rollen:
- Veld voor e-mailadres
- Verstuurt resetverzoek (via CloudKit of e-mail)
- Beschikbaar via "Wachtwoord vergeten?" link in e-mail loginscherm

---

## Privacy manifest (PrivacyInfo.xcprivacy)

Vereist door Apple voor App Store indiening. Declareert:

| API | Reden |
|---|---|
| UserDefaults | CA92.1 (eigen app-data) |
| Naam | Voor profielbeheer |
| E-mail | Voor authenticatie |
| Foto's | Voor portfolio upload |

---

## StoreKit 2 — technische details

Alleen relevant voor Shop-rol, maar architectureel algemeen.

- Import: `import StoreKit`
- Transactielistener start als `Task.detached` bij `ShopStore.init()`
- `Transaction.currentEntitlements` gecontroleerd bij elke opstart → herstelt abonnement na herinstallatie
- `Transaction.updates` stream verwerkt nieuwe aankopen en verlengingen in realtime
- Revocatie (terugbetaling door Apple): `tx.revocationDate != nil` → `abonnementActief = false`
- Alle transacties worden gefinished via `await tx.finish()`

---

## Gedeelde UI-componenten

| Component | Beschrijving |
|---|---|
| `InkField` | Standaard invoerveld (label, secure/normaal, content-type, keyboard-type) |
| `AandachtBanner` | Wit notificatiebalkje voor alle drie dashboards |
| `TattoeMachineIcon` | Canvas-getekend tattoomachine-icoon |
| `TattoePinView` | Map-pin annotatie voor kaartweergave |
| `AbonnementPlanKaart` | Herbruikbare plankaart in Shop abonnementschermen |
| `WachtwoordResetView` | Gedeeld wachtwoord-resetscherm |

---

## Agenda-integratie (EventKit)

Bevestigde afspraken kunnen worden toegevoegd aan de iOS Agenda:
- Triggert via "Agenda" knop bij `bevestigd` afspraken
- Vraagt toestemming via `EKEventStore.requestAccess(to: .event)`
- Bevestigingsdialoog getoond vóór toevoeging
- Beschikbaar bij Artiest en Shop (niet bij Klant)

---

## Testdata (TestData.swift)

Alleen actief in `#if DEBUG` builds.

### Test shops (met coördinaten)
- Dragon Tattoo — Eindhoven (`dragontattoo@test.nl`)
- Black Ink Collective — Tilburg (`blackink@test.nl`)
- Sacred Skin — 's-Hertogenbosch (`sacredskin@test.nl`)
- Inkwell Art — Helmond
- Meridian Tattoo — Eindhoven (`meridian@test.nl`)

### Test artiesten
- Lars van den Berg — Traditional, Eindhoven
- Mila Hartmann — Watercolour, Tilburg
- Remy Claessens — Blackwork, 's-Hertogenbosch
- Sofie de Boer — Realism, Eindhoven

### Test e-mails
| Rol | E-mail |
|---|---|
| Klant | `test-klant@tattoe.nl` |
| Artiest (Jim Orie) | `jim@orie.nl` |
| Shop (Dragon Tattoo) | `dragontattoo@test.nl` |

### Datumhulpfunctie
`dag(_ offset: Int)` — geeft `Date` terug als `now + offset * 86400 seconden`, gebruikt voor relatieve testdatums.

### Deduplicatie
Testdata wordt samengevoegd met CloudKit-resultaten. Duplicaten worden verwijderd op basis van `id`. Testdata wint nooit van echte CloudKit data bij gelijk ID.

---

## Design-taal

| Keuze | Waarde |
|---|---|
| Achtergrond | Zwart (`Color.black`) |
| Primaire tekst | Wit |
| Accent tekst | Grijs |
| Invoervelden | 8pt hoekradius, donkere achtergrond |
| Titels | Letter-spacing / tracking op hoofdletters |
| Taal | Nederlands (nl_NL) |
| Datum/tijd formaat | Dutch locale, "EEEE d MMMM yyyy 'om' HH:mm" |
| Navigatie | `.fullScreenCover` (geen NavigationStack) |

---

## Bundle & App Store

| Veld | Waarde |
|---|---|
| Bundle ID | `info.cafferata.tattoe` |
| StoreKit Starter | `info.cafferata.tattoe.sub.starter` |
| StoreKit Studio | `info.cafferata.tattoe.sub.studio` |
| StoreKit Pro | `info.cafferata.tattoe.sub.pro` |
| Subscription Group | Aangemaakt in App Store Connect |
| Type | Auto-renewable subscription |

> **Let op:** Verwijderde product-IDs kunnen niet hergebruikt worden in App Store Connect. De `.sub.` infix is ingevoerd na het verwijderen van de originele consumable producten.
