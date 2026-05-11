#if DEBUG
import Foundation
import CoreLocation

enum TestData {

    // MARK: - Shops

    static let shops: [ShopProfiel] = [
        ShopProfiel(id: "dragontattoo@test.nl",  bedrijfsnaam: "Dragon Tattoo",       woonplaats: "Eindhoven",          email: "dragontattoo@test.nl"),
        ShopProfiel(id: "blackink@test.nl",       bedrijfsnaam: "Black Ink Collective", woonplaats: "Tilburg",            email: "blackink@test.nl"),
        ShopProfiel(id: "sacredskin@test.nl",     bedrijfsnaam: "Sacred Skin",          woonplaats: "'s-Hertogenbosch",   email: "sacredskin@test.nl"),
        ShopProfiel(id: "inkwell@test.nl",        bedrijfsnaam: "Inkwell Art",          woonplaats: "Helmond",            email: "inkwell@test.nl"),
        ShopProfiel(id: "meridian@test.nl",       bedrijfsnaam: "Meridian Tattoo",      woonplaats: "Eindhoven",          email: "meridian@test.nl"),
    ]

    static let shopLocaties: [String: CLLocationCoordinate2D] = [
        "dragontattoo@test.nl": CLLocationCoordinate2D(latitude: 51.4379, longitude: 5.4786),
        "blackink@test.nl":     CLLocationCoordinate2D(latitude: 51.5583, longitude: 5.0829),
        "sacredskin@test.nl":   CLLocationCoordinate2D(latitude: 51.6978, longitude: 5.3037),
        "inkwell@test.nl":      CLLocationCoordinate2D(latitude: 51.4828, longitude: 5.6611),
        "meridian@test.nl":     CLLocationCoordinate2D(latitude: 51.4448, longitude: 5.4609),
    ]

    // MARK: - Artiesten

    static let artiesten: [ArtiestProfiel] = [
        ArtiestProfiel(
            id: "lars@test.nl", kunstnaam: "Lars van den Berg", specialisatie: "Traditional",
            woonplaats: "Eindhoven", email: "lars@test.nl",
            shopEmail: "dragontattoo@test.nl", shopEmails: ["dragontattoo@test.nl"],
            bio: "Al 12 jaar specialiseer ik me in klassieke Traditional tattoos — vette lijnen, felle kleuren, tijdloze designs.",
            stijlen: ["Traditional", "Neo-Traditional"],
            instagram: "@lars.tattoo", website: "larstattoostudio.nl"
        ),
        ArtiestProfiel(
            id: "mila@test.nl", kunstnaam: "Mila Hartmann", specialisatie: "Watercolour",
            woonplaats: "Tilburg", email: "mila@test.nl",
            shopEmail: "blackink@test.nl", shopEmails: ["blackink@test.nl"],
            bio: "Elk tattoo is een uniek schilderij op jouw huid. Gepassioneerd in vloeiende watercolour en fijne lijnen.",
            stijlen: ["Watercolour", "Fine Line"],
            instagram: "@mila.ink", website: ""
        ),
        ArtiestProfiel(
            id: "remy@test.nl", kunstnaam: "Remy Claessens", specialisatie: "Blackwork",
            woonplaats: "'s-Hertogenbosch", email: "remy@test.nl",
            shopEmail: "sacredskin@test.nl", shopEmails: ["sacredskin@test.nl"],
            bio: "Strakke blackwork en geometrische patronen. Ik geloof in tijdloze zwart-witte precisie.",
            stijlen: ["Blackwork", "Geometric", "Dotwork"],
            instagram: "@remy.blackwork", website: "remyclaessens.com"
        ),
        ArtiestProfiel(
            id: "sofie@test.nl", kunstnaam: "Sofie de Boer", specialisatie: "Realism",
            woonplaats: "Eindhoven", email: "sofie@test.nl",
            shopEmail: "meridian@test.nl", shopEmails: ["meridian@test.nl"],
            bio: "Fotorealistisch werk in zwart-wit en kleur. Portretten, dieren en natuur zijn mijn specialiteit.",
            stijlen: ["Realism", "Portrait", "Black & Grey"],
            instagram: "@sofie.realism", website: "sofiedeboer.nl"
        ),
    ]

    // MARK: - Afspraken

    static var afsprakenKlant: [Afspraak] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Afspraak(id: "test-a1", artiesEmail: "lars@test.nl",  shopEmail: "dragontattoo@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(14), notitie: "Sleeve Traditional motieven: roos en anker",
                     status: "wacht_klant"),
            Afspraak(id: "test-a2", artiesEmail: "mila@test.nl",  shopEmail: "blackink@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(30), notitie: "Watercolor vlinder op de pols",
                     status: "aangevraagd"),
            Afspraak(id: "test-a3", artiesEmail: "sofie@test.nl", shopEmail: "meridian@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(-7), notitie: "Portret van mijn hond — zwart-wit",
                     status: "bevestigd"),
            Afspraak(id: "test-a4", artiesEmail: "remy@test.nl",  shopEmail: "sacredskin@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(-30), notitie: "Geometrisch patroon schouder",
                     status: "geweigerd"),
        ]
    }

    static var afsprakenArties: [Afspraak] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Afspraak(id: "test-a1",  artiesEmail: "lars@test.nl", shopEmail: "dragontattoo@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(14), notitie: "Sleeve Traditional motieven: roos en anker",
                     status: "wacht_klant"),
            Afspraak(id: "test-aa2", artiesEmail: "lars@test.nl", shopEmail: "dragontattoo@test.nl",
                     klantEmail: "nina@voorbeeld.nl", klantNaam: "Nina Smit",
                     datum: dag(7),  notitie: "Klein Traditional sparrenboom achter oor",
                     status: "aangevraagd"),
            Afspraak(id: "test-aa3", artiesEmail: "lars@test.nl", shopEmail: "dragontattoo@test.nl",
                     klantEmail: "pieter@voorbeeld.nl", klantNaam: "Pieter de Vries",
                     datum: dag(21), notitie: "Traditionele schedel met bloemen",
                     status: "bevestigd"),
        ]
    }

    static var afsprakenShop: [Afspraak] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Afspraak(id: "test-a1",  artiesEmail: "lars@test.nl",  shopEmail: "dragontattoo@test.nl",
                     klantEmail: "test-klant@tattoe.nl", klantNaam: "Tom Jansen",
                     datum: dag(14), notitie: "Sleeve Traditional motieven: roos en anker",
                     status: "wacht_klant"),
            Afspraak(id: "test-aa2", artiesEmail: "lars@test.nl",  shopEmail: "dragontattoo@test.nl",
                     klantEmail: "nina@voorbeeld.nl", klantNaam: "Nina Smit",
                     datum: dag(7),  notitie: "Klein Traditional sparrenboom achter oor",
                     status: "aangevraagd"),
            Afspraak(id: "test-aa3", artiesEmail: "lars@test.nl",  shopEmail: "dragontattoo@test.nl",
                     klantEmail: "pieter@voorbeeld.nl", klantNaam: "Pieter de Vries",
                     datum: dag(21), notitie: "Traditionele schedel met bloemen",
                     status: "bevestigd"),
            Afspraak(id: "test-as1", artiesEmail: "sofie@test.nl", shopEmail: "dragontattoo@test.nl",
                     klantEmail: "anna@voorbeeld.nl", klantNaam: "Anna Bakker",
                     datum: dag(10), notitie: "Realistisch portret van kat",
                     status: "shop_akkoord"),
        ]
    }

    // MARK: - Berichten klant

    static var berichtenKlant: [Bericht] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Bericht(id: "test-bk1", ontvangerEmail: "test-klant@tattoe.nl", ontvangerRol: "klant",
                    type: "wacht_klant",
                    tekst: "Goed nieuws! Je afspraakverzoek bij Dragon Tattoo is door beiden goedgekeurd. Open de app om te bevestigen.",
                    afspraakId: "test-a1", datum: dag(-1)),
            Bericht(id: "test-bk2", ontvangerEmail: "test-klant@tattoe.nl", ontvangerRol: "klant",
                    type: "aangevraagd",
                    tekst: "Je afspraakverzoek bij Black Ink Collective is ontvangen en wordt beoordeeld.",
                    afspraakId: "test-a2", datum: dag(-3)),
            Bericht(id: "test-bk3", ontvangerEmail: "test-klant@tattoe.nl", ontvangerRol: "klant",
                    type: "bevestigd",
                    tekst: "Je afspraak bij Meridian Tattoo met Sofie de Boer is definitief bevestigd. Tot dan!",
                    afspraakId: "test-a3", datum: dag(-8)),
        ]
    }

    // MARK: - Berichten arties

    static var berichtenArties: [Bericht] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Bericht(id: "test-ba1", ontvangerEmail: "lars@test.nl", ontvangerRol: "arties",
                    type: "aangevraagd",
                    tekst: "Nieuw verzoek van Tom Jansen: Sleeve Traditional motieven op 14 dagen. Geef jij akkoord?",
                    afspraakId: "test-a1", datum: dag(-2)),
            Bericht(id: "test-ba2", ontvangerEmail: "lars@test.nl", ontvangerRol: "arties",
                    type: "aangevraagd",
                    tekst: "Nieuw verzoek van Nina Smit: sparrenboom achter oor, over 7 dagen. Geef jij akkoord?",
                    afspraakId: "test-aa2", datum: dag(-1)),
            Bericht(id: "test-ba3", ontvangerEmail: "lars@test.nl", ontvangerRol: "arties",
                    type: "bevestigd",
                    tekst: "Pieter de Vries heeft de afspraak over 21 dagen bevestigd. De afspraak is definitief.",
                    afspraakId: "test-aa3", datum: dag(-4)),
        ]
    }

    // MARK: - Voorraad shop (Dragon Tattoo)

    static var voorraadShop: [VoorraadItem] {
        let nu = Date()
        func vd(_ maanden: Int) -> Date { Calendar.current.date(byAdding: .month, value: maanden, to: nu) ?? nu }
        return [
            // Inkt — diverse batches
            VoorraadItem(id: "v-ink1", naam: "Intenze True Black",         type: .inkt,
                         merk: "Intenze", batchNummer: "ITZ-2024-TB-0091", kleur: "Carbon Black",
                         hoeveelheid: "120", eenheid: "ml", vervaldatum: vd(18), notitie: "Hoofdkleur voor blackwork",
                         aangemaakt: Calendar.current.date(byAdding: .day, value: -30, to: nu) ?? nu),
            VoorraadItem(id: "v-ink2", naam: "Dynamic Color Deep Red",     type: .inkt,
                         merk: "Dynamic", batchNummer: "DYN-2024-DR-0442", kleur: "Deep Red",
                         hoeveelheid: "60",  eenheid: "ml", vervaldatum: vd(24), notitie: "",
                         aangemaakt: Calendar.current.date(byAdding: .day, value: -14, to: nu) ?? nu),
            VoorraadItem(id: "v-ink3", naam: "World Famous Ocean Blue",    type: .inkt,
                         merk: "World Famous", batchNummer: "WF-2024-OB-1138", kleur: "Ocean Blue",
                         hoeveelheid: "30",  eenheid: "ml", vervaldatum: vd(1),  notitie: "Bijna op — nabestellen!",
                         aangemaakt: Calendar.current.date(byAdding: .month, value: -5, to: nu) ?? nu),
            VoorraadItem(id: "v-ink4", naam: "Fusion Ink Bright Yellow",   type: .inkt,
                         merk: "Fusion", batchNummer: "FUS-2025-BY-0077", kleur: "Bright Yellow",
                         hoeveelheid: "30",  eenheid: "ml", vervaldatum: vd(-2), notitie: "VERLOPEN — verwijderen",
                         aangemaakt: Calendar.current.date(byAdding: .month, value: -8, to: nu) ?? nu),

            // Naalden
            VoorraadItem(id: "v-nd1", naam: "Cartridges 7RL",              type: .naald,
                         merk: "Cheyenne", batchNummer: "", kleur: "7RL",
                         hoeveelheid: "40",  eenheid: "stuks", vervaldatum: nil, notitie: "Ronde liner voor fine line",
                         aangemaakt: Calendar.current.date(byAdding: .day, value: -7, to: nu) ?? nu),
            VoorraadItem(id: "v-nd2", naam: "Cartridges 9M1",              type: .naald,
                         merk: "Bishop", batchNummer: "", kleur: "9M1",
                         hoeveelheid: "25",  eenheid: "stuks", vervaldatum: nil, notitie: "Magnum voor shading",
                         aangemaakt: Calendar.current.date(byAdding: .day, value: -7, to: nu) ?? nu),

            // Verzorging
            VoorraadItem(id: "v-vz1", naam: "Vaseline Pure",               type: .verzorging,
                         merk: "Vaseline", batchNummer: "", kleur: "",
                         hoeveelheid: "5",   eenheid: "potten", vervaldatum: vd(36), notitie: "",
                         aangemaakt: Calendar.current.date(byAdding: .month, value: -1, to: nu) ?? nu),
            VoorraadItem(id: "v-vz2", naam: "Green Soap",                  type: .verzorging,
                         merk: "Sterilon", batchNummer: "", kleur: "",
                         hoeveelheid: "2",   eenheid: "liter", vervaldatum: vd(12), notitie: "Voor reiniging huid",
                         aangemaakt: Calendar.current.date(byAdding: .month, value: -2, to: nu) ?? nu),

            // Overig
            VoorraadItem(id: "v-ov1", naam: "Nitrile handschoenen (M)",    type: .overig,
                         merk: "Aurelia", batchNummer: "", kleur: "",
                         hoeveelheid: "3",   eenheid: "dozen", vervaldatum: vd(48), notitie: "",
                         aangemaakt: Calendar.current.date(byAdding: .month, value: -1, to: nu) ?? nu),
            VoorraadItem(id: "v-ov2", naam: "A4 thermisch transferpapier", type: .overig,
                         merk: "Spirit", batchNummer: "", kleur: "",
                         hoeveelheid: "150", eenheid: "vel",   vervaldatum: nil, notitie: "Voor stencil afdrukken",
                         aangemaakt: Calendar.current.date(byAdding: .day, value: -3, to: nu) ?? nu),
        ]
    }

    // MARK: - Berichten shop

    static var berichtenShop: [Bericht] {
        let nu = Date()
        func dag(_ d: Int) -> Date { Calendar.current.date(byAdding: .day, value: d, to: nu) ?? nu }
        return [
            Bericht(id: "test-bs1", ontvangerEmail: "dragontattoo@test.nl", ontvangerRol: "shop",
                    type: "aangevraagd",
                    tekst: "Nieuw verzoek via Lars van den Berg: Tom Jansen wil een sleeve over 14 dagen. Goedkeuren?",
                    afspraakId: "test-a1", datum: dag(-2)),
            Bericht(id: "test-bs2", ontvangerEmail: "dragontattoo@test.nl", ontvangerRol: "shop",
                    type: "shop_akkoord",
                    tekst: "Dragon Tattoo heeft akkoord gegeven voor Anna Bakker. Wachten op akkoord van Sofie de Boer.",
                    afspraakId: "test-as1", datum: dag(-1)),
            Bericht(id: "test-bs3", ontvangerEmail: "dragontattoo@test.nl", ontvangerRol: "shop",
                    type: "bevestigd",
                    tekst: "Pieter de Vries heeft de afspraak met Lars van den Berg bevestigd. Definitief ingepland.",
                    afspraakId: "test-aa3", datum: dag(-3)),
        ]
    }
}
#endif
