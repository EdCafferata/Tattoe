# Tattoe App — Klant

Alles wat de klant-rol doet, bevat en kan instellen.

---

## Navigatiestroom

```
KlantFlowView
├── Niet ingelogd              → KlantAppleLoginView / KlantEmailLoginView
├── Ingelogd, geen naam        → KlantNAWView
├── Ingelogd, geen consent     → KlantConsentView
└── Alles compleet             → KlantDashboardView
```

---

## Schermen

### KlantAppleLoginView / KlantEmailLoginView / KlantEmailRegisterView
- Zelfde patroon als Artiest-login
- Registratieformulier: voornaam, achternaam, e-mail, wachtwoord, telefoon, adres

### KlantNAWView
- Aanvullen adresgegevens na Apple login
- Account verwijderen knop aanwezig

### KlantConsentView
Vereiste stap vóór toegang tot dashboard. Vier uitklapbare kaarten met checkbox:
1. Toestemmingsformulier
2. Digitale handtekening bevestiging
3. Risico & nazorg informatie
4. Volledige risicoerkenning

- Knop "IK GA AKKOORD" is uitgeschakeld totdat alle 4 zijn aangevinkt
- Animatie op de knop bij activatie
- UITLOGGEN-knop beschikbaar onder de kaarten

### KlantDashboardView
Hoofdscherm van de klant:

**Koptekst**
- "WELKOM TERUG" + naam
- Knoppen: AANPASSEN, BERICHTEN, UITLOGGEN

**Shop & Artiest selector**
- Twee compacte rijen: SHOP / ARTIEST
- Toont "Niet gekozen" of de naam van het favoriete shop/artiest
- Rechtse knop: snel een afspraakaanvraag openen (KlantAfspraakAanvraagView)

**Actieknoppen**
- ONTDEK → KlantOntdekkenView (shops en artiesten bladeren)
- AFSPRAKEN → KlantAfsprakenoverzichtView

**Kaart (MapKit)**
- Toont 5 dichtstbijzijnde shops + zoekresultaten
- Favoriete shop = oranje pin, favoriete artiest = groene pin
- Zoomt automatisch op alle zichtbare pins
- Span: min 0.04° – max 0.12° graad
- Zoeken op stad/plaatsnaam (CLGeocoder + MapKit local search, radius 0.5°)
- Tap op pin → ShopInfoKaartje (naam + "Stel in als favoriet" knop)

**AandachtBanner**
- Zichtbaar als `aandacht > 0`
- Toont ongelezen berichten + afspraken die aandacht vragen
- Tik op deel → navigeert naar berichten of afspraken

### KlantOntdekkenView
- Segmentbediening: SHOPS / ARTIESTEN
- Zoekveld (plaatshouder wisselt per tab)
- Lijst: shops met locatie, artiesten met specialisatie + stijlen
- Tap → instellen als favoriet + scherm sluit
- Vinkje-icoon op huidig favoriete item
- In DEBUG: testdata samengevoegd met CloudKit resultaten

### KlantAfspraakAanvraagView
- Sheet-presentatie (half scherm)
- Kies shop en/of artiest
- Invullen: notitie / omschrijving opdracht, gewenste datum en tijd
- Versturen maakt Afspraak in CloudKit + bericht naar artiest/shop

### KlantBerichtenView
- Berichten gesorteerd op datum (nieuwste eerst)
- Type badges: NIEUWE AANVRAAG, AKKOORD ONTVANGEN, AFSPRAAK BEVESTIGD, etc.
- Tap op bericht → markeer als gelezen

### KlantAfsprakenoverzichtView
- Alle afspraken van de klant
- **Status weergave:**
  - `aangevraagd` → "Wacht op artiest / shop"
  - `arties_akkoord` / `shop_akkoord` → "Deels goedgekeurd"
  - `wacht_klant` → BEVESTIGEN knop zichtbaar
  - `bevestigd` → "Bevestigd ✓" + Printen knop
  - `geannuleerd` → "Afgezegd"
  - `geweigerd` → "Geweigerd"
- ANNULEER knop bij openstaande aanvragen
- Printen knop → PDF via share sheet (deelAfspraak)

---

## State (KlantStore)

| Property | Type | Beschrijving |
|---|---|---|
| `klant` | `Klant?` | Ingelogd profiel |
| `isLoggedIn` | `Bool` | Authenticatiestatus |
| `consentGegeven` | `Bool` | Juridisch akkoord afgevinkt |
| `isCheckingCloud` | `Bool` | CloudKit sync bezig |
| `favorietArties` | `ArtiestProfiel?` | Opgeslagen favoriete artiest |
| `favorietShop` | `ShopProfiel?` | Opgeslagen favoriet shop |
| `berichten` | `[Bericht]` | Ontvangen berichten |
| `afsprakenaandacht` | `Int` | Afspraken die bevestiging vragen |
| `ongelezen` | `Int` (computed) | Ongelezen berichten |
| `aandacht` | `Int` (computed) | `ongelezen + afsprakenaandacht` (voor badge) |

---

## Functies (KlantStore)

| Functie | Wat het doet |
|---|---|
| `save(_ klant:)` | Lokaal opslaan + CloudKit sync |
| `saveLocal(_ klant:)` | Alleen lokaal opslaan (DEBUG) |
| `saveConsent()` | Juridisch akkoord opslaan |
| `slaFavorietArties(_ profiel:)` | Favoriete artiest instellen + opslaan |
| `slaFavorietShop(_ profiel:)` | Favoriet shop instellen + opslaan |
| `bevestigAfspraak(_ afspraakId:)` | Afspraak bevestigen → bericht naar artiest/shop |
| `annuleerAfspraak(afspraakId:)` | Afspraak annuleren → bericht naar partijen |
| `inloggen(email:wachtwoord:)` | E-mail authenticatie |
| `checkCloud(appleUserID:)` | Bestaand profiel ophalen + favorieten herstellen |
| `laadAfsprakenaandacht()` | Telt afspraken met status `wacht_klant` |
| `updateBadge()` | App-icon badge instellen op `aandacht` |
| `markeerGelezen(_ id:)` | Bericht markeren als gelezen |
| `verwijderAccount()` | Account verwijderen uit CloudKit |

---

## CloudKit interacties

| Actie | Methode |
|---|---|
| Klantprofiel ophalen | `CloudKitManager.shared.fetchKlant()` |
| Klantprofiel opslaan | `CloudKitManager.shared.saveKlant()` |
| Berichten ophalen | `CloudKitManager.shared.fetchBerichten(email:)` |
| Afspraken ophalen | `CloudKitManager.shared.fetchAfspraken(klantEmail:)` |
| Afspraakstatus bijwerken | `CloudKitManager.shared.updateAfspraakStatus()` |
| Bericht sturen | `CloudKitManager.shared.saveBericht()` |
| Nieuwe afspraak aanmaken | `CloudKitManager.shared.saveAfspraak()` |
| Account verwijderen | `CloudKitManager.shared.verwijderKlant()` |

---

## Sync

- Achtergrond sync elke **10 minuten** via `syncVanCloud()`
- Haalt bij: favoriete shop/artiest profiel + berichten + afsprakenaandacht
- Herstart sync automatisch als favoriet shop of artiest wijzigt

---

## Lokale opslag

| Sleutel | Inhoud |
|---|---|
| `UserDefaults: klant_logged_in` | Bool inlogstatus |
| `UserDefaults: klant_data` | JSON van Klant-profiel |
| `UserDefaults: klant_gelezen_berichten` | Set van gelezen bericht-ID's |
| `UserDefaults: klant_consent` | Bool of consent gegeven is |
| `UserDefaults: klant_favoriet_arties` | JSON van favoriete ArtiestProfiel |
| `UserDefaults: klant_favoriet_shop` | JSON van favoriete ShopProfiel |

---

## Notificaties & badge

- Vraagt toestemming voor **badge-only** bij opstarten
- Badge = `ongelezen + afsprakenaandacht`
- `afsprakenaandacht` telt afspraken met status `wacht_klant` (klant moet bevestigen)
- AandachtBanner in dashboard zichtbaar als `aandacht > 0`

---

## Kaart & locatie

- `LocatieBeheerder`: CLLocationManager wrapper als Observable class
- Toestemming: `whenInUse` ("wanneer in gebruik")
- Nauwkeurigheid: 100 meter (`kCLLocationAccuracyHundredMeters`)
- Geocoding via `CLGeocoder`: adressen → coördinaten
- Zoekstraal voor tattoo shops: 0.5° graad via MapKit local search
- Afstandsberekening: eenvoudige kwadraatverschil (geen haversine)
- Zoomlogica: centreert op alle zichtbare pins, min 0.04° – max 0.12° span

---

## Consent systeem

De klant moet juridisch akkoord gaan voordat het dashboard toegankelijk is:

| Kaart | Inhoud |
|---|---|
| 1 | Toestemmingsformulier (tattoo plaatsen) |
| 2 | Digitale handtekening bevestiging |
| 3 | Risico & nazorg informatie |
| 4 | Volledige risicoerkenning |

- Alle 4 checkboxes moeten aangevinkt zijn
- Eenmalig per account (opgeslagen in UserDefaults + CloudKit)
- Kan niet worden overgeslagen

---

## Afspraken-workflow (klant)

```
Klant vraagt afspraak aan
  → Status: aangevraagd
  → Artiest keurt goed → arties_akkoord
  → Shop keurt ook goed → wacht_klant
     → BEVESTIGEN knop zichtbaar voor klant
     → Klant bevestigt → status: bevestigd
     → Klant negeert → kan nog annuleren
  → Klant kan op elk moment annuleren (tot bevestigd)
```

---

## Datamodel Klant

| Veld | Type | Beschrijving |
|---|---|---|
| `id` | `String` | UUID |
| `authMethode` | `String` | "apple" of "email" |
| `voornaam`, `achternaam` | `String` | Naam |
| `email` | `String` | Login e-mail |
| `wachtwoordHash` | `String` | Gehashed wachtwoord |
| `telefoon` | `String` | Telefoonnummer |
| `straat`, `huisnummer`, `postcode`, `stad` | `String` | Adres |
| `consentGegeven` | `Bool` | Juridisch akkoord |
| `favorietArtiesId` | `String` | ID van favoriete artiest |
| `favorietShopId` | `String` | ID van favoriet shop |

---

## DEV / debug

- TestData.swift levert 4 testafspraken + 3 testberichten voor klant
- Testklant e-mail: `test-klant@tattoe.nl`
- Testdata samengevoegd met CloudKit resultaten (deduplicatie op ID)
- DEV-knop in registratieformulier vult alle velden automatisch in
