import SwiftUI
import PDFKit
import UIKit

// MARK: - Sheet wrapper

struct ConsentDocumentSheet: View {
    let index: Int
    @Environment(\.dismiss) private var dismiss

    private var pdfURL: URL { ConsentPDFGenerator.tempURL(index: index) }

    var body: some View {
        NavigationStack {
            PDFKitView(url: pdfURL)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(ConsentPDFGenerator.titels[index])
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: pdfURL,
                                  preview: SharePreview(ConsentPDFGenerator.titels[index],
                                                        image: Image(systemName: "doc.fill"))) {
                            Image(systemName: "square.and.arrow.up")
                                .tint(.white)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sluiten") { dismiss() }
                            .tint(.white)
                    }
                }
        }
    }
}

// MARK: - PDFKit wrapper

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.document = PDFDocument(url: url)
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.backgroundColor = UIColor(white: 0.93, alpha: 1)
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil { uiView.document = PDFDocument(url: url) }
    }
}

// MARK: - PDF generator

enum ConsentPDFGenerator {

    static let titels = [
        "Consentformulier Tattoo",
        "Digitale Handtekening",
        "Risico-informatie & Nazorg",
        "Bevestiging & Vrijwaring"
    ]

    static func tempURL(index: Int) -> URL {
        let naam = titels[index].replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "en")
            .replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(naam).pdf")
        try? maak(index: index).write(to: url)
        return url
    }

    static func maak(index: Int) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let pr = PageRenderer(ctx: ctx, pageRect: pageRect)
            pr.drawHeader(titel: titels[index])
            for sectie in secties[index] {
                pr.drawSectie(sectie)
            }
            pr.drawFooter()
        }
    }

    // MARK: - Document content

    private static let secties: [[(String, String)]] = [
        // 0 – Consentformulier
        [
            ("Inleiding",
             "Dit consentformulier is opgesteld om zowel de klant als de tattoostudio te beschermen en te informeren. Door dit formulier digitaal te accepteren, bevestigt u dat u volledig geïnformeerd bent over de procedure, de risico's en uw eigen verantwoordelijkheden vóór, tijdens en na de behandeling."),

            ("Persoonlijke verklaring",
             "Ik verklaar hierbij:\n• Dat ik minimaal 18 jaar oud ben en volledig handelingsbekwaam ben.\n• Dat ik uit vrije wil, zonder enige druk of dwang, toestemming geef voor de overeengekomen tattoo behandeling.\n• Dat ik de artiest volledig en naar waarheid heb geïnformeerd over mijn gezondheidstoestand.\n• Dat ik de keuze voor het ontwerp, de kleur en de plaatsing van de tattoo geheel zelf heb gemaakt."),

            ("Medische contra-indicaties",
             "Ik verklaar geen van de volgende aandoeningen te hebben, tenzij ik de tattoostudio hier vooraf uitdrukkelijk van op de hoogte heb gesteld:\n• Bloedverdunnende medicijnen (aspirine, warfarine, clopidogrel e.d.)\n• Bloedstollingsstoornissen of hemofilie\n• Diabetes mellitus (suikerziekte)\n• Hart- en vaatziekten of een pacemaker\n• Epilepsie of convulsiestoornissen\n• HIV/AIDS of andere aandoeningen die het immuunsysteem beïnvloeden\n• Actieve huidaandoeningen in het te tatoeëren gebied (eczeem, psoriasis, acne)\n• Aanleg voor keloid- of littekenweefselvorming\n• Zwangerschap of borstvoeding\n• Recente chemotherapie of radiotherapie\n• Bekende allergie voor tattooinkt of kleurstoffen"),

            ("Toestemming behandeling",
             "Ik geef hierbij uitdrukkelijk toestemming voor:\n• Het uitvoeren van de overeengekomen tattoo behandeling door de tattoostudio.\n• Het gebruik van professionele naalden en tattooinkt op de overeengekomen locatie op mijn lichaam.\n• Het fotografisch vastleggen van het eindresultaat uitsluitend voor portefeuilledoeleinden van de artiest, tenzij ik hier schriftelijk bezwaar tegen heb gemaakt."),

            ("Permanentie & verwachtingen",
             "Ik begrijp en accepteer uitdrukkelijk dat:\n• Een tattoo een permanente en onomkeerbare verandering van de huid is.\n• Het eindresultaat mede afhankelijk is van mijn individuele huidtype, het genezingsproces en de kwaliteit van mijn nazorg.\n• Kleine variaties in kleur of lijn binnen de artistieke tolerantie vallen en geen reden tot garantieclaim zijn.\n• Bij ontevredenheid geen financiële terugbetaling mogelijk is, maar dat herstelwerk altijd bespreekbaar is in goed overleg met de artiest."),
        ],

        // 1 – Digitale handtekening
        [
            ("Wettelijke grondslag",
             "Deze digitale handtekening is rechtsgeldig op grond van de Europese eIDAS-verordening (EU) nr. 910/2014 en de Nederlandse Wet elektronisch berichtenverkeer (Web). Een elektronische handtekening heeft dezelfde rechtskracht als een fysieke handtekening, mits er sprake is van een ondubbelzinnige en aantoonbare wilsuiting."),

            ("Wat vormt uw handtekening",
             "Uw digitale handtekening bestaat uit de volgende gecombineerde elementen:\n• Uw expliciete akkoordverklaring via de Tattoe-applicatie.\n• De exacte datum en het tijdstip van ondertekening (UTC-tijdstempel).\n• Uw unieke gebruikersidentificatie (Apple ID of geregistreerd e-mailadres).\n• Het apparaat-ID van het gebruikte apparaat.\nAl deze gegevens worden veilig vastgelegd in ons systeem als onweerlegbaar bewijs van uw instemming."),

            ("Integriteit van het document",
             "Het document dat u ondertekent is het exacte document dat u volledig heeft kunnen inzien in de Tattoe-app. Na ondertekening wordt er een onveranderlijk tijdstempel aan het document toegevoegd. Het document kan hierna op geen enkele wijze meer worden aangepast. Een gewaarmerkte kopie van het ondertekende document is te allen tijde op te vragen via de Tattoe-applicatie."),

            ("Herroeping van toestemming",
             "U kunt uw toestemming herroepen tot het moment van aanvang van de tattoosessie. Herroeping dient mondeling of schriftelijk te worden medegedeeld aan de tattoostudio. Na aanvang van de behandeling is herroeping niet langer mogelijk, omdat de procedure dan al is gestart."),

            ("Bewaring van persoonsgegevens",
             "Uw ondertekende consentdocumenten worden gedurende 7 jaar bewaard conform de Nederlandse wettelijke bewaarplicht voor gegevens betreffende medische en cosmetische behandelingen. U heeft op grond van de Algemene Verordening Gegevensbescherming (AVG) te allen tijde het recht om uw gegevens in te zien, te corrigeren of – binnen wettelijke grenzen – te laten verwijderen. Verzoeken hiertoe kunt u indienen via de tattoostudio."),
        ],

        // 2 – Risico-informatie & Nazorg
        [
            ("Risico's bij tatoeëren",
             "Tatoeëren is een relatief veilige cosmetische procedure wanneer uitgevoerd door een gecertificeerd professional in een gecertificeerde, hygiënische omgeving. Desondanks zijn er inherente risico's waarvan u volledig op de hoogte moet zijn:\n\n• Infectie: Hoewel al ons materiaal steriel en eenmalig gebruikt is, kan bij onvoldoende nazorg een bacteriële of virale infectie optreden. Symptomen zijn aanhoudende roodheid, zwelling, warmte, pusafscheiding of koorts.\n\n• Allergische reactie: Sommige personen reageren allergisch op tattooinkt, met name op rode, gele of oranje pigmenten die organische kleurstoffen bevatten. Symptomen zijn aanhoudende jeuk, bultjes of zwelling rondom de tattoo.\n\n• Keloidvorming: Personen met een genetische aanleg voor keloids kunnen een verheven, uitgebreid littekenweefsel ontwikkelen. Dit is niet vooraf te voorspellen.\n\n• MRI-interferentie: In zeldzame gevallen kan tattooinkt die ijzeroxide-pigmenten bevat lichte tintelingen of warmtegevoelens geven tijdens een MRI-scan. Informeer uw radioloog altijd over de aanwezigheid en locatie van uw tattoos.\n\n• Stressreactie: In zeldzame gevallen kan het lichaam een vasovagale reactie vertonen (duizeligheid, misselijkheid). Informeer de artiest onmiddellijk als u zich niet goed voelt."),

            ("Voorbereiding op de behandeling",
             "Voor een optimaal resultaat en een veilig verloop adviseren wij u:\n• Eet ten minste 2 uur voor de sessie een volwaardige maaltijd — een lage bloedsuikerspiegel vergroot het risico op een vasovagale reactie.\n• Vermijd alcohol minimaal 24 uur voor de behandeling.\n• Draag comfortabele kleding die ruim toegang biedt tot het te tatoeëren lichaamsdeel.\n• Kom uitgerust en zo ontspannen mogelijk naar de afspraak.\n• Informeer de artiest direct als u twijfels heeft of zich niet goed voelt."),

            ("De eerste 24 uur na de behandeling",
             "Uw tattoo is direct na de behandeling vergelijkbaar met een oppervlakkige wond en vereist zorgvuldige behandeling:\n• Laat de folie of het verbandmateriaal dat de artiest heeft aangebracht minimaal 2 tot 4 uur ongestoord op de behandelde plek zitten.\n• Verwijder het verband voorzichtig onder lauw stromend water.\n• Reinig de tattoo zachtjes met een milde zeep zonder parfum of alcohol.\n• Dep de tattoo voorzichtig droog met schoon absorberend papier — wrijven is absoluut uit den boze.\n• Breng een dun, gelijkmatig laagje aan van een geurvrije tattoo-aftercare crème of vaseline.\n• Vermijd zwemmen, warmtebaden en sauna gedurende de eerste 2 tot 4 weken."),

            ("Genezingsperiode: 2 tot 4 weken",
             "Fase 1 — Dag 1 t/m 6: De tattoo is rood, gezwollen en gevoelig. Een lichte heldere vloeistofafscheiding is volledig normaal en hoeft geen zorg te baren.\n\nFase 2 — Dag 7 t/m 14: De bovenste huidlaag begint te schilferen en de tattoo zal intens jeuken. Het is van cruciaal belang dat u NIET krabt of aan de schilfers trekt — dit verwijdert inkt en kan littekenvorming veroorzaken.\n\nFase 3 — Dag 15 t/m 28: De buitenste huidlaag is hersteld maar de diepere dermislagen genezen nog steeds. Bescherm de tattoo in deze fase nog altijd afdoende tegen direct zonlicht en chloorhoudend water.\n\nRaadpleeg bij twijfel over uw herstel altijd uw huisarts of de tattoostudio."),

            ("Langdurige verzorging en behoud",
             "Voor een duurzaam, levendig resultaat op de lange termijn adviseren wij:\n• Breng dagelijks een zonnebrandcrème met minimaal SPF 50 aan op de tattoo bij blootstelling aan zonlicht — UV-straling is de grootste vijand van tattoopigment.\n• Houd uw huid optimaal gehydrateerd met een goede bodylotion — droge huid versnelt de vervaging van inkt.\n• Beperk langdurig verblijf in zwembaden, zeewater of warmtebaden ook na het genezingsproces.\n• Een tattoo vervaagt over de jaren door het normale verouderingsproces van de huid. Opfrissings- en herstelbehandelingen zijn mogelijk zodra de tattoo volledig is genezen."),
        ],

        // 3 – Bevestiging & Vrijwaring
        [
            ("Algehele bevestiging",
             "Door dit document te accepteren, bevestigt u uitdrukkelijk dat u alle voorgaande consentdocumenten volledig en zonder enige tijdsdruk heeft gelezen en naar eigen tevredenheid heeft begrepen. Dit betreft:\n• Consentformulier Tattoo Behandeling\n• Digitale Handtekening Verklaring\n• Risico-informatie & Nazorginstructies\n\nU verklaart dat u de inhoud van deze documenten vrijwillig en volledig begrijpt en accepteert."),

            ("Vrijwaring van de tattoostudio",
             "De tattoostudio, haar medewerkers en artiesten zijn uitdrukkelijk niet aansprakelijk voor:\n• Onverwachte allergische reacties op tattooinkt of kleurstoffen waarvoor de klant geen voorkennis had en deze niet heeft gemeld.\n• Infecties of complicaties die direct voortvloeien uit onvoldoende, onjuiste of nalatige nazorg door de klant.\n• Kleurvervaging, vervorming of kwaliteitsvermindering als gevolg van blootstelling aan zonlicht, chloor, mechanische beschadiging of andere externe factoren.\n• Medische complicaties die voortvloeien uit niet-opgegeven medische aandoeningen, medicijngebruik of andere relevante gezondheidsinformatie die de klant heeft verzwegen.\n• Resultaten die niet overeenkomen met de verwachtingen als gevolg van het niet opvolgen van de gegeven nazorginstructies."),

            ("Verantwoordelijkheid van de klant",
             "De klant aanvaardt volledige en persoonlijke verantwoordelijkheid voor:\n• Het eerlijk, volledig en uit eigen beweging informeren van de tattoostudio over alle relevante medische aandoeningen, allergieën en medicatiegebruik.\n• Het nauwgezet en consequent uitvoeren van de verstrekte nazorginstructies gedurende de gehele genezingsperiode.\n• Het tijdig en proactief raadplegen van een arts bij het optreden van symptomen die kunnen duiden op een infectie of allergische reactie.\n• De volledig eigen, autonome keuze voor het definitieve ontwerp, de kleurstelling en de anatomische plaatsing van de tattoo."),

            ("Klachten en geschillenbeslechting",
             "Bij klachten over de uitgevoerde behandeling geldt de volgende procedure:\n1. De klant dient de klacht binnen 14 kalenderdagen na de behandeling schriftelijk in bij de tattoostudio.\n2. De tattoostudio heeft vervolgens 30 kalenderdagen de tijd om de klacht in behandeling te nemen en een passende oplossing voor te stellen.\n3. De tattoostudio behoudt uitdrukkelijk het recht om herstelwerk aan te bieden als primaire en redelijke oplossing voor gegronde klachten.\n4. Indien partijen geen minnelijke oplossing bereiken, kan de klant zich wenden tot de bevoegde kantonrechter of een erkende geschillencommissie."),

            ("Toepasselijk recht",
             "Op deze overeenkomst en alle daaruit voortvloeiende verbintenissen is uitsluitend Nederlands recht van toepassing. Eventuele geschillen die niet in der minne kunnen worden opgelost, worden ter beslechting voorgelegd aan de bevoegde rechter van de rechtbank in het arrondissement waar de betrokken tattoostudio is gevestigd.\n\nDoor uw akkoord te geven via de Tattoe-applicatie, verklaart u dit document volledig te hebben gelezen, begrepen en vrijwillig te aanvaarden."),
        ],
    ]
}

// MARK: - Page renderer helper

private class PageRenderer {
    let ctx: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat = 52
    let bottomMargin: CGFloat = 72
    var y: CGFloat = 0
    var pageCount = 1

    var contentX: CGFloat { margin }
    var contentWidth: CGFloat { pageRect.width - margin * 2 }
    var maxContentY: CGFloat { pageRect.height - bottomMargin }

    init(ctx: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        self.ctx = ctx
        self.pageRect = pageRect
    }

    // MARK: Header (eerste pagina)

    func drawHeader(titel: String) {
        // Zwarte header balk
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 88)
        UIColor.black.setFill()
        UIBezierPath(rect: headerRect).fill()

        // TATTOE
        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .black),
            .foregroundColor: UIColor.white,
            .kern: 6.0
        ]
        NSAttributedString(string: "TATTOE", attributes: brandAttrs)
            .draw(at: CGPoint(x: margin, y: 22))

        // Rechtsboven: datum
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor(white: 0.55, alpha: 1)
        ]
        let dateAS = NSAttributedString(string: dateStr, attributes: dateAttrs)
        let dateW = dateAS.size().width
        dateAS.draw(at: CGPoint(x: pageRect.width - margin - dateW, y: 26))

        // Document titel
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor(white: 0.65, alpha: 1),
            .kern: 2.0
        ]
        NSAttributedString(string: titel.uppercased(), attributes: titleAttrs)
            .draw(at: CGPoint(x: margin, y: 52))

        // Dunne lijn onder header
        UIColor(white: 0.2, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 88, width: pageRect.width, height: 0.5)).fill()

        y = 88 + 24
    }

    // MARK: Sectie

    func drawSectie(_ sectie: (String, String)) {
        let (header, body) = sectie

        space(12)

        // Sectie header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.black,
            .kern: 0.5
        ]
        let headerAS = NSAttributedString(string: header, attributes: headerAttrs)
        draw(headerAS)
        space(4)

        // Body tekst
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 3.5
        paraStyle.paragraphSpacing = 6

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor(white: 0.2, alpha: 1),
            .paragraphStyle: paraStyle
        ]
        let bodyAS = NSAttributedString(string: body, attributes: bodyAttrs)
        draw(bodyAS)
        space(10)

        // Dunne scheiding lijn
        UIColor(white: 0.87, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: contentX, y: y, width: contentWidth, height: 0.5)).fill()
        space(1)
    }

    // MARK: Footer

    func drawFooter() {
        drawPageFooter()
    }

    // MARK: Private helpers

    private func draw(_ str: NSAttributedString) {
        let height = measuredHeight(str)
        if y + height > maxContentY { newPage() }
        str.draw(in: CGRect(x: contentX, y: y, width: contentWidth, height: height + 4))
        y += height
    }

    private func space(_ h: CGFloat) {
        if y + h <= maxContentY { y += h }
        else { newPage() }
    }

    private func measuredHeight(_ str: NSAttributedString) -> CGFloat {
        str.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height.rounded(.up) + 2
    }

    private func newPage() {
        drawPageFooter()
        ctx.beginPage()
        pageCount += 1
        y = margin
        drawContinuationHeader()
    }

    private func drawPageFooter() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(white: 0.55, alpha: 1)
        ]
        let str = NSAttributedString(string: "Tattoe — Pagina \(pageCount)", attributes: attrs)
        let footerY = pageRect.height - 36
        str.draw(at: CGPoint(x: margin, y: footerY))

        let right = NSAttributedString(string: "EST. 2026", attributes: attrs)
        let rw = right.size().width
        right.draw(at: CGPoint(x: pageRect.width - margin - rw, y: footerY))

        UIColor(white: 0.85, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: footerY - 6, width: contentWidth, height: 0.5)).fill()
    }

    private func drawContinuationHeader() {
        UIColor(white: 0.97, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageRect.width, height: 32)).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .semibold),
            .foregroundColor: UIColor(white: 0.45, alpha: 1),
            .kern: 1.5
        ]
        NSAttributedString(string: "TATTOE — VERVOLG", attributes: attrs)
            .draw(at: CGPoint(x: margin, y: 11))
        UIColor(white: 0.85, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 32, width: pageRect.width, height: 0.5)).fill()
        y = 44
    }
}
