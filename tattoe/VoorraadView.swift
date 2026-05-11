import SwiftUI

// MARK: - Data modellen

enum VoorraadType: String, Codable, CaseIterable {
    case inkt       = "inkt"
    case naald      = "naald"
    case verzorging = "verzorging"
    case overig     = "overig"

    var label: String {
        switch self {
        case .inkt:       return "Inkt"
        case .naald:      return "Naalden"
        case .verzorging: return "Verzorging"
        case .overig:     return "Overig"
        }
    }
    var icon: String {
        switch self {
        case .inkt:       return "drop.fill"
        case .naald:      return "cross.case.fill"
        case .verzorging: return "bandage.fill"
        case .overig:     return "shippingbox.fill"
        }
    }
    var kleur: Color {
        switch self {
        case .inkt:       return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .naald:      return Color(red: 0.9, green: 0.5, blue: 0.3)
        case .verzorging: return Color(red: 0.4, green: 0.85, blue: 0.6)
        case .overig:     return Color(white: 0.5)
        }
    }
}

struct VoorraadItem: Identifiable, Codable {
    var id:           String       = UUID().uuidString
    var naam:         String       = ""
    var type:         VoorraadType = .overig
    var merk:         String       = ""
    var batchNummer:  String       = ""
    var kleur:        String       = ""
    var hoeveelheid:  String       = ""
    var eenheid:      String       = ""
    var vervaldatum:  Date?        = nil
    var notitie:      String       = ""
    var aangemaakt:   Date         = Date()
    var isVast:       Bool         = false   // vast item kan niet worden verwijderd
}

// MARK: - Hoofd voorraadscherm

struct VoorraadView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var toonToevoegen  = false
    @State private var bewerkItem: VoorraadItem?   = nil
    @State private var toonInktBatch  = false
    @State private var verwijderAlert: VoorraadItem? = nil

    var losse: [VoorraadItem] { store.voorraad.filter { !$0.isVast } }
    var inktBatches: Int { store.voorraad.filter { $0.type == .inkt }.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                        }
                        Spacer()
                        Button(action: { toonToevoegen = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    Text("VOORRAAD")
                        .font(.system(size: 14, weight: .black)).tracking(4)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24).padding(.top, 56).padding(.bottom, 24)

                if store.voorraad.isEmpty {
                    leegScherm
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            // Vaste inkt-batch kaart (altijd bovenaan)
                            inktBatchKaart
                                .padding(.horizontal, 20)

                            // Losse items per type
                            ForEach(VoorraadType.allCases, id: \.self) { type in
                                let items = losse.filter { $0.type == type }
                                if !items.isEmpty {
                                    sectie(type: type, items: items)
                                }
                            }

                            Spacer().frame(height: 40)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(isPresented: $toonToevoegen) {
            VoorraadItemFormView(bestaand: nil) { item in
                store.voegVoorraadToe(item)
            }
        }
        .sheet(item: $bewerkItem) { item in
            VoorraadItemFormView(bestaand: item) { gewijzigd in
                store.werkVoorraadBij(gewijzigd)
            }
        }
        .fullScreenCover(isPresented: $toonInktBatch) {
            InktBatchView().environmentObject(store)
        }
        .confirmationDialog(
            "'\(verwijderAlert?.naam ?? "")' verwijderen?",
            isPresented: .init(get: { verwijderAlert != nil }, set: { if !$0 { verwijderAlert = nil } }),
            titleVisibility: .visible
        ) {
            Button("Verwijderen", role: .destructive) {
                if let item = verwijderAlert { store.verwijderVoorraad(id: item.id) }
                verwijderAlert = nil
            }
            Button("Annuleer", role: .cancel) { verwijderAlert = nil }
        }
    }

    // MARK: - Vaste inkt-batch kaart

    private var inktBatchKaart: some View {
        Button(action: { toonInktBatch = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("INKT BATCH TRACKING")
                            .font(.system(size: 11, weight: .bold)).tracking(1.5)
                            .foregroundColor(.white)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.3))
                    }
                    Text(inktBatches == 0
                         ? "Nog geen batches geregistreerd"
                         : "\(inktBatches) batch\(inktBatches == 1 ? "" : "es") geregistreerd")
                        .font(.system(size: 12)).foregroundColor(Color(white: 0.45))
                    Text("EU REACH-regelgeving — lot-nummers bijhouden")
                        .font(.system(size: 10)).foregroundColor(Color(white: 0.28))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(16)
            .background(Color(white: 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Sectie per type

    @ViewBuilder
    private func sectie(type: VoorraadType, items: [VoorraadItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 10))
                    .foregroundColor(type.kleur)
                Text(type.label.uppercased())
                    .font(.system(size: 9, weight: .bold)).tracking(2)
                    .foregroundColor(Color(white: 0.35))
            }
            .padding(.horizontal, 20)

            ForEach(items) { item in
                itemRij(item)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Item rij

    @ViewBuilder
    private func itemRij(_ item: VoorraadItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.type.kleur.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: item.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(item.type.kleur)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.naam.isEmpty ? "Naamloos item" : item.naam)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 8) {
                    if !item.merk.isEmpty {
                        Text(item.merk).font(.system(size: 11)).foregroundColor(Color(white: 0.4))
                    }
                    if !item.hoeveelheid.isEmpty {
                        Text("\(item.hoeveelheid) \(item.eenheid)")
                            .font(.system(size: 11)).foregroundColor(Color(white: 0.4))
                    }
                    if let vd = item.vervaldatum, vd < Date().addingTimeInterval(30*86400) {
                        Label(korteDatum(vd), systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                    }
                }
                if !item.notitie.isEmpty {
                    Text(item.notitie).font(.system(size: 11)).foregroundColor(Color(white: 0.3)).lineLimit(1)
                }
            }
            Spacer()
            Menu {
                Button(action: { bewerkItem = item }) {
                    Label("Bewerken", systemImage: "pencil")
                }
                Button(role: .destructive, action: { verwijderAlert = item }) {
                    Label("Verwijderen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(white: 0.3))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(14)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.1), lineWidth: 1))
    }

    // MARK: - Leeg scherm

    private var leegScherm: some View {
        VStack(spacing: 0) {
            // Inkt batch kaart altijd zichtbaar
            inktBatchKaart.padding(.horizontal, 20)
            Spacer()
            Image(systemName: "shippingbox")
                .font(.system(size: 40)).foregroundColor(Color(white: 0.15))
            Spacer().frame(height: 16)
            Text("Nog geen voorraad").font(.system(size: 14, weight: .semibold)).foregroundColor(Color(white: 0.3))
            Text("Tik op + om een artikel toe te voegen")
                .font(.system(size: 12)).foregroundColor(Color(white: 0.2)).padding(.top, 6)
            Spacer()
        }
    }

    private func korteDatum(_ d: Date) -> String {
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM"
        return df.string(from: d)
    }
}

// MARK: - Formulier: item toevoegen / bewerken

struct VoorraadItemFormView: View {
    let bestaand: VoorraadItem?
    let onOpslaan: (VoorraadItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var item: VoorraadItem

    init(bestaand: VoorraadItem?, onOpslaan: @escaping (VoorraadItem) -> Void) {
        self.bestaand  = bestaand
        self.onOpslaan = onOpslaan
        _item = State(initialValue: bestaand ?? VoorraadItem())
    }

    private var isNieuw: Bool { bestaand == nil }
    private var kanOpslaan: Bool { !item.naam.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Type kiezer
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("TYPE")
                            HStack(spacing: 8) {
                                ForEach(VoorraadType.allCases, id: \.self) { type in
                                    typeChip(type)
                                }
                            }
                        }

                        // Naam
                        veld("NAAM", tekst: $item.naam, placeholder: "Bijv. Black Rose Liner")

                        // Merk
                        veld("MERK", tekst: $item.merk, placeholder: "Bijv. Dynamic, Intenze")

                        // Type-specifieke velden
                        if item.type == .inkt {
                            veld("KLEUR", tekst: $item.kleur, placeholder: "Bijv. Carbon Black, Deep Red")
                            veld("BATCH / LOT NUMMER", tekst: $item.batchNummer, placeholder: "Bijv. 2024-BL-0042")
                        }
                        if item.type == .naald {
                            veld("MAAT / TYPE", tekst: $item.kleur, placeholder: "Bijv. 7RL, 9M1, 14RS")
                        }

                        // Hoeveelheid + eenheid
                        HStack(spacing: 10) {
                            veld("HOEVEELHEID", tekst: $item.hoeveelheid, placeholder: "0", keyboard: .decimalPad)
                                .frame(maxWidth: .infinity)
                            veld("EENHEID", tekst: $item.eenheid, placeholder: eenheidPlaceholder)
                                .frame(maxWidth: .infinity)
                        }

                        // Vervaldatum
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("VERVALDATUM (OPTIONEEL)")
                            HStack {
                                if item.vervaldatum != nil {
                                    DatePicker("", selection: Binding(
                                        get: { item.vervaldatum ?? Date() },
                                        set: { item.vervaldatum = $0 }
                                    ), displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    Spacer()
                                    Button(action: { item.vervaldatum = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(white: 0.35))
                                    }
                                } else {
                                    Button(action: { item.vervaldatum = Calendar.current.date(byAdding: .year, value: 1, to: Date()) }) {
                                        Label("Datum instellen", systemImage: "calendar.badge.plus")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.4))
                                    }
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .background(Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
                        }

                        // Notitie
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("NOTITIE")
                            TextEditor(text: $item.notitie)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 72)
                                .padding(12)
                                .background(Color(white: 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
                        }

                        // Opslaan knop
                        Button(action: opslaan) {
                            Text(isNieuw ? "TOEVOEGEN" : "OPSLAAN")
                                .font(.system(size: 13, weight: .bold)).tracking(3)
                                .foregroundColor(kanOpslaan ? .black : Color(white: 0.3))
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(kanOpslaan ? Color.white : Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(!kanOpslaan)
                        .padding(.top, 8).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 12)
                }
            }
            .navigationTitle(isNieuw ? "Artikel toevoegen" : "Bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                        .foregroundColor(Color(white: 0.5))
                }
            }
        }
    }

    // MARK: - Type chip

    @ViewBuilder
    private func typeChip(_ type: VoorraadType) -> some View {
        let geselecteerd = item.type == type
        Button(action: { item.type = type }) {
            HStack(spacing: 5) {
                Image(systemName: type.icon).font(.system(size: 10))
                Text(type.label).font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(geselecteerd ? .black : type.kleur)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(geselecteerd ? type.kleur : type.kleur.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(geselecteerd ? Color.clear : type.kleur.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Veld helper

    @ViewBuilder
    private func veld(_ label: String, tekst: Binding<String>, placeholder: String,
                      keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(label)
            TextField(placeholder, text: tekst)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Color(white: 0.35))
    }

    private var eenheidPlaceholder: String {
        switch item.type {
        case .inkt:       return "ml / oz"
        case .naald:      return "stuks"
        case .verzorging: return "ml / gr"
        case .overig:     return "stuks"
        }
    }

    private func opslaan() {
        var opTeSlaan = item
        opTeSlaan.naam = opTeSlaan.naam.trimmingCharacters(in: .whitespaces)
        onOpslaan(opTeSlaan)
        dismiss()
    }
}

// MARK: - Inkt batch tracker

struct InktBatchView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var toonToevoegen   = false
    @State private var bewerkBatch: VoorraadItem? = nil
    @State private var verwijderAlert: VoorraadItem? = nil

    var batches: [VoorraadItem] { store.voorraad.filter { $0.type == .inkt }.sorted { $0.aangemaakt > $1.aangemaakt } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.5))
                        }
                        Spacer()
                        Button(action: { toonToevoegen = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    Text("INKT BATCHES")
                        .font(.system(size: 14, weight: .black)).tracking(4)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24).padding(.top, 56).padding(.bottom, 8)

                // EU info banner
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    Text("EU REACH-regelgeving vereist traceerbaarheid van tattoo-inkt per lot-nummer")
                        .font(.system(size: 11)).foregroundColor(Color(white: 0.4))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.08))
                .overlay(Rectangle().stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 20).padding(.vertical, 12)

                if batches.isEmpty {
                    Spacer()
                    Image(systemName: "drop").font(.system(size: 40)).foregroundColor(Color(white: 0.15))
                    Spacer().frame(height: 16)
                    Text("Geen batches geregistreerd").font(.system(size: 14)).foregroundColor(Color(white: 0.3))
                    Text("Tik op + om een inkt batch toe te voegen")
                        .font(.system(size: 12)).foregroundColor(Color(white: 0.2)).padding(.top, 6)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(batches) { batch in
                                batchKaart(batch)
                                    .padding(.horizontal, 20)
                            }
                            Spacer().frame(height: 40)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .sheet(isPresented: $toonToevoegen) {
            InktBatchFormView(bestaand: nil) { item in
                var nieuw = item
                nieuw.type = .inkt
                store.voegVoorraadToe(nieuw)
            }
        }
        .sheet(item: $bewerkBatch) { batch in
            InktBatchFormView(bestaand: batch) { gewijzigd in
                store.werkVoorraadBij(gewijzigd)
            }
        }
        .confirmationDialog(
            "Batch '\(verwijderAlert?.naam ?? "")' verwijderen?",
            isPresented: .init(get: { verwijderAlert != nil }, set: { if !$0 { verwijderAlert = nil } }),
            titleVisibility: .visible
        ) {
            Button("Verwijderen", role: .destructive) {
                if let b = verwijderAlert { store.verwijderVoorraad(id: b.id) }
                verwijderAlert = nil
            }
            Button("Annuleer", role: .cancel) { verwijderAlert = nil }
        }
    }

    private let batchDf: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "nl_NL"); f.dateFormat = "d MMM yyyy"; return f
    }()

    // MARK: - Batch kaart

    @ViewBuilder
    private func batchKaart(_ batch: VoorraadItem) -> some View {
        let verlopen = batch.vervaldatum.map { $0 < Date() } ?? false
        let bijna    = batch.vervaldatum.map { $0 < Date().addingTimeInterval(30*86400) && $0 >= Date() } ?? false

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(batch.naam.isEmpty ? "Onbekende inkt" : batch.naam)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    if !batch.merk.isEmpty {
                        Text(batch.merk).font(.system(size: 12)).foregroundColor(Color(white: 0.45))
                    }
                }
                Spacer()
                Menu {
                    Button(action: { bewerkBatch = batch }) { Label("Bewerken", systemImage: "pencil") }
                    Button(role: .destructive, action: { verwijderAlert = batch }) { Label("Verwijderen", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16)).foregroundColor(Color(white: 0.3))
                        .frame(width: 32, height: 32)
                }
            }

            HStack(spacing: 16) {
                if !batch.kleur.isEmpty {
                    infoBadge(icon: "paintpalette.fill", tekst: batch.kleur, kleur: Color(red: 0.4, green: 0.6, blue: 1.0))
                }
                if !batch.batchNummer.isEmpty {
                    infoBadge(icon: "barcode", tekst: batch.batchNummer, kleur: Color(white: 0.5))
                }
                if !batch.hoeveelheid.isEmpty {
                    infoBadge(icon: "drop.fill", tekst: "\(batch.hoeveelheid) \(batch.eenheid)", kleur: Color(red: 0.4, green: 0.6, blue: 1.0))
                }
            }

            if let vd = batch.vervaldatum {
                HStack(spacing: 6) {
                    Image(systemName: verlopen ? "xmark.circle.fill" : bijna ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(verlopen ? Color(red: 0.9, green: 0.3, blue: 0.3) : bijna ? Color(red: 1, green: 0.6, blue: 0.2) : Color(red: 0.4, green: 0.85, blue: 0.6))
                    Text(verlopen ? "Verlopen op \(batchDf.string(from: vd))" : "Houdbaar tot \(batchDf.string(from: vd))")
                        .font(.system(size: 11))
                        .foregroundColor(verlopen ? Color(red: 0.9, green: 0.3, blue: 0.3) : bijna ? Color(red: 1, green: 0.6, blue: 0.2) : Color(white: 0.4))
                }
            }

            if !batch.notitie.isEmpty {
                Text(batch.notitie).font(.system(size: 11)).foregroundColor(Color(white: 0.35)).lineLimit(2)
            }

            Text("Toegevoegd op \(batchDf.string(from: batch.aangemaakt))")
                .font(.system(size: 10)).foregroundColor(Color(white: 0.22))
        }
        .padding(14)
        .background(Color(white: 0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(verlopen ? Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.4) : Color(white: 0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func infoBadge(icon: String, tekst: String, kleur: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(kleur)
            Text(tekst).font(.system(size: 11)).foregroundColor(Color(white: 0.55))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(kleur.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(kleur.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Inkt batch formulier

struct InktBatchFormView: View {
    let bestaand: VoorraadItem?
    let onOpslaan: (VoorraadItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var naam:        String = ""
    @State private var merk:        String = ""
    @State private var kleur:       String = ""
    @State private var batch:       String = ""
    @State private var hoeveelheid: String = ""
    @State private var eenheid:     String = "ml"
    @State private var vervaldatum: Date?  = nil
    @State private var notitie:     String = ""

    init(bestaand: VoorraadItem?, onOpslaan: @escaping (VoorraadItem) -> Void) {
        self.bestaand  = bestaand
        self.onOpslaan = onOpslaan
        if let b = bestaand {
            _naam        = State(initialValue: b.naam)
            _merk        = State(initialValue: b.merk)
            _kleur       = State(initialValue: b.kleur)
            _batch       = State(initialValue: b.batchNummer)
            _hoeveelheid = State(initialValue: b.hoeveelheid)
            _eenheid     = State(initialValue: b.eenheid.isEmpty ? "ml" : b.eenheid)
            _vervaldatum = State(initialValue: b.vervaldatum)
            _notitie     = State(initialValue: b.notitie)
        }
    }

    private var kanOpslaan: Bool { !naam.trimmingCharacters(in: .whitespaces).isEmpty && !batch.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Inleiding
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14)).foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                            Text("Registreer het lot-nummer van elke inkt voor EU REACH-traceerbaarheid.")
                                .font(.system(size: 12)).foregroundColor(Color(white: 0.4))
                        }
                        .padding(12)
                        .background(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        inkVeld("NAAM INKT", tekst: $naam, placeholder: "Bijv. Carbon Black Ink")
                        inkVeld("MERK", tekst: $merk, placeholder: "Bijv. Dynamic, Intenze, World Famous")
                        inkVeld("KLEUR", tekst: $kleur, placeholder: "Bijv. Black, Deep Red, Ocean Blue")

                        inkVeld("BATCH / LOT NUMMER *", tekst: $batch, placeholder: "Bijv. 2024-BL-0042")

                        HStack(spacing: 10) {
                            inkVeld("VOLUME", tekst: $hoeveelheid, placeholder: "30", keyboard: .decimalPad).frame(maxWidth: .infinity)
                            inkVeld("EENHEID", tekst: $eenheid, placeholder: "ml").frame(maxWidth: .infinity)
                        }

                        // Vervaldatum
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HOUDBAARHEIDSDATUM").font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Color(white: 0.35))
                            HStack {
                                if vervaldatum != nil {
                                    DatePicker("", selection: Binding(
                                        get: { vervaldatum ?? Date() },
                                        set: { vervaldatum = $0 }
                                    ), displayedComponents: .date)
                                    .datePickerStyle(.compact).labelsHidden().colorScheme(.dark)
                                    Spacer()
                                    Button(action: { vervaldatum = nil }) {
                                        Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundColor(Color(white: 0.35))
                                    }
                                } else {
                                    Button(action: { vervaldatum = Calendar.current.date(byAdding: .year, value: 2, to: Date()) }) {
                                        Label("Datum instellen", systemImage: "calendar.badge.plus")
                                            .font(.system(size: 13)).foregroundColor(Color(white: 0.4))
                                    }
                                    Spacer()
                                }
                            }
                            .padding(12)
                            .background(Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
                        }

                        inkVeld("NOTITIE", tekst: $notitie, placeholder: "Bijv. gebruikt voor sleeve klant X")

                        Button(action: opslaan) {
                            Text(bestaand == nil ? "BATCH REGISTREREN" : "OPSLAAN")
                                .font(.system(size: 13, weight: .bold)).tracking(3)
                                .foregroundColor(kanOpslaan ? .black : Color(white: 0.3))
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(kanOpslaan ? Color.white : Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(!kanOpslaan)
                        .padding(.top, 8).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 12)
                }
            }
            .navigationTitle(bestaand == nil ? "Batch registreren" : "Batch bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }.foregroundColor(Color(white: 0.5))
                }
            }
        }
    }

    @ViewBuilder
    private func inkVeld(_ label: String, tekst: Binding<String>, placeholder: String,
                         keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Color(white: 0.35))
            TextField(placeholder, text: tekst)
                .font(.system(size: 14)).foregroundColor(.white).keyboardType(keyboard)
                .padding(12)
                .background(Color(white: 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
        }
    }

    private func opslaan() {
        var item         = bestaand ?? VoorraadItem()
        item.naam        = naam.trimmingCharacters(in: .whitespaces)
        item.merk        = merk
        item.kleur       = kleur
        item.batchNummer = batch.trimmingCharacters(in: .whitespaces)
        item.hoeveelheid = hoeveelheid
        item.eenheid     = eenheid
        item.vervaldatum = vervaldatum
        item.notitie     = notitie
        item.type        = .inkt
        onOpslaan(item)
        dismiss()
    }
}
