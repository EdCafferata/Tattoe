import UIKit

// MARK: - Afspraak PDF genereren + delen

func deelAfspraak(_ a: Afspraak, afdrukVoor: String = "") {
    let url = maakAfspraakPDF(a, afdrukVoor: afdrukVoor)
    let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    presenteerVC(av)
}

private func maakAfspraakPDF(_ a: Afspraak, afdrukVoor: String) -> URL {
    let A4 = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: A4)
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("tattoe_afspraak_\(a.id).pdf")

    let dfDatum = DateFormatter()
    dfDatum.locale = Locale(identifier: "nl_NL")
    dfDatum.dateFormat = "EEEE d MMMM yyyy 'om' HH:mm"

    let dfGen = DateFormatter()
    dfGen.locale = Locale(identifier: "nl_NL")
    dfGen.dateStyle = .long
    dfGen.timeStyle = .short

    let statusTekst: String = {
        switch a.status {
        case "bevestigd":                      return "Bevestigd ✓"
        case "aangevraagd":                    return "Aangevraagd – in behandeling"
        case "arties_akkoord","shop_akkoord":  return "Deels goedgekeurd – wacht op alle partijen"
        case "wacht_klant":                    return "Wacht op bevestiging klant"
        case "geannuleerd":                    return "Afgezegd"
        case "geweigerd":                      return "Geweigerd"
        default:                               return a.status.capitalized
        }
    }()

    try? renderer.writePDF(to: url) { ctx in
        ctx.beginPage()
        let margin: CGFloat = 56
        var y: CGFloat = margin

        func attrs(_ size: CGFloat, _ weight: UIFont.Weight, _ color: UIColor = .black,
                   kern: CGFloat = 0) -> [NSAttributedString.Key: Any] {
            var d: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: color
            ]
            if kern != 0 { d[.kern] = kern }
            return d
        }

        // ── Koptekst ──────────────────────────────────────────────────
        "TATTOE".draw(at: CGPoint(x: margin, y: y),
                      withAttributes: attrs(26, .black, kern: 6))
        y += 36
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y, width: A4.width - margin * 2, height: 1.5)).fill()
        y += 14
        "AFSPRAAKBEVESTIGING".draw(at: CGPoint(x: margin, y: y),
                                   withAttributes: attrs(9, .semibold, .darkGray, kern: 3))
        y += 32

        // ── Helper: label + waarde op één rij ─────────────────────────
        func rij(_ label: String, _ waarde: String) {
            guard !waarde.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            label.draw(at: CGPoint(x: margin, y: y),
                       withAttributes: attrs(9, .semibold, .gray, kern: 2))
            waarde.draw(at: CGPoint(x: margin + 130, y: y),
                        withAttributes: attrs(13, .regular))
            y += 22
        }

        func sectieKop(_ tekst: String) {
            y += 16
            UIColor(white: 0.85, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y + 12, width: A4.width - margin * 2, height: 0.5)).fill()
            tekst.draw(at: CGPoint(x: margin, y: y),
                       withAttributes: attrs(8, .bold, .lightGray, kern: 3))
            y += 22
        }

        // ── Inhoud ────────────────────────────────────────────────────
        sectieKop("DATUM & STATUS")
        rij("Datum", dfDatum.string(from: a.datum).capitalized)
        rij("Status", statusTekst)

        sectieKop("KLANT")
        if !a.klantNaam.isEmpty { rij("Naam", a.klantNaam) }
        rij("E-mail", a.klantEmail)

        if !a.artiesEmail.isEmpty {
            sectieKop("ARTIEST")
            rij("E-mail", a.artiesEmail)
        }

        if !a.shopEmail.isEmpty {
            sectieKop("SHOP")
            rij("E-mail", a.shopEmail)
        }

        if !a.notitie.isEmpty {
            sectieKop("NOTITIE / OPDRACHT")
            let notitieRect = CGRect(x: margin, y: y, width: A4.width - margin * 2, height: 160)
            a.notitie.draw(in: notitieRect, withAttributes: attrs(12, .regular))
            y += min(160, CGFloat(a.notitie.count / 5) + 30)
        }

        if !afdrukVoor.isEmpty {
            sectieKop("AFDRUK VOOR")
            rij("", afdrukVoor)
        }

        // ── Voettekst ─────────────────────────────────────────────────
        let footerY = A4.height - margin - 20
        UIColor(white: 0.8, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: footerY - 6, width: A4.width - margin * 2, height: 0.5)).fill()
        "Gegenereerd op \(dfGen.string(from: Date())) via Tattoe App".draw(
            at: CGPoint(x: margin, y: footerY),
            withAttributes: attrs(8, .regular, .lightGray))
    }
    return url
}

// MARK: - CSV export (voor ShopBeheerView)

func exportAfsprakenCSV(_ afspraken: [Afspraak], jaar: Int) -> URL {
    let df = DateFormatter()
    df.locale = Locale(identifier: "nl_NL")
    df.dateFormat = "dd-MM-yyyy"

    let tf = DateFormatter()
    tf.locale = Locale(identifier: "nl_NL")
    tf.dateFormat = "HH:mm"

    let statusNL: (String) -> String = { s in
        switch s {
        case "bevestigd":     return "Bevestigd"
        case "aangevraagd":   return "Aangevraagd"
        case "arties_akkoord": return "Artiest akkoord"
        case "shop_akkoord":  return "Shop akkoord"
        case "wacht_klant":   return "Wacht op klant"
        case "geannuleerd":   return "Afgezegd"
        case "geweigerd":     return "Geweigerd"
        default:              return s
        }
    }

    var csv = "Datum;Tijd;Klant naam;Klant e-mail;Artiest e-mail;Shop e-mail;Status;Notitie\n"
    let gesorteerd = afspraken.sorted { $0.datum < $1.datum }
    for a in gesorteerd {
        func esc(_ s: String) -> String { "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" }
        csv += "\(df.string(from: a.datum));\(tf.string(from: a.datum));"
            + "\(esc(a.klantNaam));\(esc(a.klantEmail));"
            + "\(esc(a.artiesEmail));\(esc(a.shopEmail));"
            + "\(esc(statusNL(a.status)));\(esc(a.notitie))\n"
    }

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("tattoe_afspraken_\(jaar).csv")
    var bom = Data([0xEF, 0xBB, 0xBF])
    bom.append(contentsOf: csv.data(using: .utf8) ?? Data())
    try? bom.write(to: url)
    return url
}

// MARK: - UIKit helper

func presenteerVC(_ vc: UIViewController) {
    guard let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let root = scene.keyWindow?.rootViewController else { return }
    var top = root
    while let p = top.presentedViewController { top = p }
    top.present(vc, animated: true)
}
