# Tattoe App — Artiest

Alles wat de artiest-rol doet, bevat en kan instellen.

---

## Navigatiestroom

```
ArtiesFlowView
├── Niet ingelogd        → ArtiesLoginView
├── Ingelogd, geen naam  → ArtiesNAWView
└── Profiel compleet     → ArtiesDashboardView
```

---

## Schermen

### ArtiesLoginView
- Inloggen met Apple (Sign in with Apple)
- E-mail inloggen knop → ArtiesEmailLoginView
- Registreren knop → ArtiesEmailRegisterView
- Foutmelding bij mislukte login

### ArtiesEmailLoginView
- Velden: e-mailadres, wachtwoord
- "Wachtwoord vergeten?" → WachtwoordResetView
- Laadspinner tijdens authenticatie
- Foutmeldingen in rood

### ArtiesEmailRegisterView
Secties:
- **ACCOUNT:** voornaam, achternaam, e-mail, wachtwoord (+ bevestiging)
- **ARTIEST:** kunstnaam, specialisatie
- **SHOPS:** multi-shop kiezer (optioneel via MultiShopZoekerView)
- **CONTACT:** telefoonnummer
- **ADRES:** straat, huisnummer, postcode, stad
- Validatie op alle verplichte velden
- DEV-knop vult testdata automatisch in

### ArtiesNAWView
- Aanvullen van adresgegevens na Apple login
- Shop(s) koppelen of aanpassen

### ArtiesDashboardView
- **Koptekst:** profielfoto (of placeholder), kunstnaam, specialisatie, locatie
- Knoppen: AANPASSEN, UITLOGGEN
- Secties: BERICHTEN (met ongelezen badge), AFSPRAKEN, MIJN SHOPS
- Bio, stijlen, ervaringsjaren, social media & website
- PORTFOLIO raster (max 9 foto's)
- VOORBEELD TATTOO'S raster (max 9 foto's)
- Hint "Vul je profiel in via AANPASSEN" als profiel onvolledig is
- AandachtBanner bovenaan zichtbaar als `aandacht > 0`

### ArtiesProfielBewerkenView
- URL-importeur (importeert data van eigen website)
- Profielfoto uploaden (PhotosPicker)
- Bio tekstveld
- Stijlen editor (tags toevoegen / verwijderen)
- Portfolio raster (9 cellen, tap om te wisselen)
- Voorbeeld-tattoos raster (9 cellen)
- Ervaringsjaren stepper
- Social media URLs: Instagram, Facebook, Pinterest, TikTok, Website
- Knop OPSLAAN (met laadstatus)
- Knop ACCOUNT VERWIJDEREN (met bevestigingsdialoog)

### ArtiesAfsprakenView
Toont alle afspraken van de ingelogde artiest:
- Naam klant, datum/tijd, notitie, status badge
- **Status labels:**
  - `aangevraagd` → OK / NEE knoppen
  - `shop_akkoord` → OK / NEE knoppen ("Shop akkoord – jouw beurt")
  - `wacht_klant` → "Wacht op bevestiging klant"
  - `bevestigd` → Agenda knop + Printen knop + Afzeggen knop
- Bevestigingsdialoog bij afzeggen

### ArtiesShopsBeheerView
- Lijst van gekoppelde shops met verwijderknop
- Shop toevoegen via ShopZoekerView
- Wijzigingen direct opgeslagen

### ShopZoekerView
- Laadt shops vanuit CloudKit
- Zoeken op naam of stad
- Tap om te selecteren en te sluiten

### MultiShopZoekerView
- Meerdere shops aanvinken (checkboxes)
- Teller op bevestigknop
- OVERSLAAN-knop als geen keuze gewenst

---

## State (ArtiesStore)

| Property | Type | Beschrijving |
|---|---|---|
| `arties` | `Arties?` | Ingelogd profiel |
| `isLoggedIn` | `Bool` | Authenticatiestatus |
| `isCheckingCloud` | `Bool` | CloudKit sync bezig |
| `profielFotoData` | `Data?` | Profielfoto |
| `portfolioFotos` | `[Data?]` | Max 9 portfolio afbeeldingen |
| `voorbeeldFotos` | `[Data?]` | Max 9 voorbeeldtattoos |
| `berichten` | `[Bericht]` | Ontvangen berichten |
| `afsprakenaandacht` | `Int` | Afspraken die aandacht vragen |
| `ongelezen` | `Int` (computed) | Aantal ongelezen berichten |
| `aandacht` | `Int` (computed) | `ongelezen + afsprakenaandacht` (voor badge) |

---

## Functies (ArtiesStore)

| Functie | Wat het doet |
|---|---|
| `save(_ arties:)` | Lokaal opslaan + CloudKit sync + `startSync()` |
| `saveLocal(_ arties:)` | Alleen lokaal opslaan (DEBUG) |
| `saveProfielFoto(_:)` | Foto uploaden, compress naar max 1080px @ 0.8 kwaliteit |
| `savePortfolioFoto(_:at:)` | Portfolio foto toevoegen op positie |
| `removePortfolioFoto(at:)` | Portfolio foto verwijderen |
| `saveVoorbeeldFoto(_:at:)` | Voorbeeldfoto toevoegen |
| `removeVoorbeeldFoto(at:)` | Voorbeeldfoto verwijderen |
| `checkCloud(appleUserID:)` | Bestaand profiel ophalen via Apple ID |
| `inloggen(email:wachtwoord:)` | E-mail authenticatie |
| `keurAfspraakGoed(_ a:)` | Afspraak goedkeuren → stuurt bericht naar klant/shop |
| `weigerAfspraak(_ a:)` | Afspraak weigeren → stuurt bericht |
| `annuleerAfspraak(_ a:)` | Afspraak afzeggen → update alle partijen |
| `markeerGelezen(_ id:)` | Bericht markeren als gelezen |
| `laadBerichten()` | Berichten + afsprakenaandacht ophalen |
| `laadAfsprakenaandacht()` | Telt afspraken met status `aangevraagd` of `shop_akkoord` |
| `updateBadge()` | App-icon badge instellen op `aandacht` |
| `logout()` | Alle data wissen |
| `verwijderAccount()` | Profiel verwijderen uit CloudKit |
| `devInloggen()` | *(DEBUG)* Automatisch inloggen als Jim Orie |

---

## CloudKit interacties

| Actie | Methode |
|---|---|
| Profiel opslaan (privé) | `CloudKitManager.shared.saveArties()` |
| Publiek profiel opslaan (ontdekken) | `CloudKitManager.shared.savePubliekArties()` |
| Profiel ophalen | `CloudKitManager.shared.fetchArties()` |
| Foto's ophalen | `CloudKitManager.shared.fetchArtiestFotos()` |
| Foto's uploaden | `CloudKitManager.shared.saveArtiestFotos()` |
| Berichten ophalen | `CloudKitManager.shared.fetchBerichten(email:)` |
| Afspraken ophalen | `CloudKitManager.shared.fetchAfspraken(artiesEmail:)` |
| Afspraakstatus bijwerken | `CloudKitManager.shared.updateAfspraakStatus()` |
| Bericht sturen | `CloudKitManager.shared.saveBericht()` |
| Account verwijderen | `CloudKitManager.shared.verwijderArties()` |

---

## Sync

- Achtergrond sync elke **10 minuten** via `syncVanCloud()`
- Haalt bij: bijgewerkt profiel + berichten + afsprakenaandacht
- Draait tot uitloggen of app-sluiting
- `save()` roept `startSync()` aan zodat sync direct start na opslaan

---

## Lokale opslag

| Sleutel / bestand | Inhoud |
|---|---|
| `UserDefaults: arties_logged_in` | Bool inlogstatus |
| `UserDefaults: arties_data` | JSON van Arties-profiel |
| `UserDefaults: arties_gelezen_berichten` | Set van gelezen bericht-ID's |
| `arties_profiel.jpg` | Gecomprimeerde profielfoto |
| `arties_portfolio_0..8.jpg` | Portfolio foto's |
| `arties_voorbeeld_0..8.jpg` | Voorbeeldtattoo foto's |

Afbeeldingen worden gecomprimeerd naar max 1080px breedte/hoogte @ 0.8 JPEG kwaliteit.

---

## Notificaties & badge

- Vraagt toestemming voor **badge-only** bij opstarten
- Badge = `ongelezen + afsprakenaandacht`
- Wordt bijgewerkt via `UNUserNotificationCenter.current().setBadgeCount()`
- AandachtBanner in dashboard zichtbaar als `aandacht > 0`

---

## Afspraken-workflow (artiest)

```
Klant vraagt aan (aangevraagd)
  → Artiest ziet OK / NEE
     → OK: status wordt arties_akkoord of bevestigd (als shop al akkoord)
     → NEE: status wordt geweigerd, klant ontvangt bericht
  → Als bevestigd: artiest kan aan agenda toevoegen, printen, afzeggen
```

---

## Datamodel Arties

| Veld | Type | Beschrijving |
|---|---|---|
| `id` | `String` | UUID |
| `authMethode` | `String` | "apple" of "email" |
| `voornaam`, `achternaam` | `String` | Naam |
| `kunstnaam` | `String` | Artiestennaam |
| `specialisatie` | `String` | Hoofdstijl (bijv. "Realism") |
| `email` | `String` | Login e-mail |
| `wachtwoordHash` | `String` | Gehashed wachtwoord |
| `telefoon` | `String` | Telefoonnummer |
| `straat`, `huisnummer`, `postcode`, `stad` | `String` | Adres |
| `shopEmails` | `[String]` | Gekoppelde shops |
| `bio` | `String` | Profieltekst |
| `stijlen` | `[String]` | Bijv. ["Traditional", "Blackwork"] |
| `ervaringJaren` | `Int` | Jaren ervaring |
| `instagram`, `facebook`, `pinterest`, `tiktok`, `website` | `String` | Social media |

---

## DEV / debug

- `devInloggen()` logt automatisch in als Jim Orie (jim@orie.nl)
- TestData.swift levert 3 testafspraken + 3 testberichten voor artiest
- Testdata wordt samengevoegd met CloudKit resultaten (deduplicatie op ID)
- DEV-knop in registratieformulier vult alle velden met dummydata
