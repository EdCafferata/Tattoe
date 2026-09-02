# Tattoe

🔒 Laatste security check: 2026-09-02 21:27 CEST

SwiftUI iOS-app voor tattooshops, tattoo-artiesten en klanten: digitale klantregistratie, ondertekende consent-PDF's, openingstijden- en agendabeheer, en meer — in één app met drie rollen.

**Status:** in ontwikkeling, TestFlight-builds via Fastlane.
**Eigenaar:** Ed Cafferata, ondersteund door The IT Crowd.

## Rollen
- **Klant** — registratie, consent tekenen, afspraken
- **Artiest** — klantbeheer, sessiehistorie
- **Shop** — openingstijden, weekagenda, klant- en artiestbeheer

Zie de rol-specifieke documentatie voor details: [README_ALGEMEEN.md](README_ALGEMEEN.md) (architectuur), [README_KLANT.md](README_KLANT.md), [README_ARTIEST.md](README_ARTIEST.md), [README_SHOP.md](README_SHOP.md).

## Techniek
- SwiftUI, CloudKit (container `iCloud.info.cafferata.tattoe`)
- Bundle ID: `info.cafferata.tattoe`
- Xcode-project: `Tattoe.xcodeproj`, scheme `tattoe`

## Build & TestFlight
Project is gepind op Homebrew Ruby (`.ruby-version`), niet system-Ruby:
```bash
/opt/homebrew/opt/ruby/bin/bundle exec fastlane beta
```
Zie [SECURITY.md](SECURITY.md) voor het security-beleid.
