import EventKit
import Foundation

final class EventKitManager {
    static let shared = EventKitManager()
    private let store = EKEventStore()
    private let calKey = "tattoe_cal_events" // UserDefaults dict: [afspraakId: eventIdentifier]

    private var opgeslagen: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: calKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: calKey) }
    }

    func voegToe(afspraakId: String, datum: Date, titel: String, notitie: String) async -> Bool {
        let toegang: Bool
        if #available(iOS 17, *) {
            toegang = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            toegang = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
            }
        }
        guard toegang else { return false }

        let event = EKEvent(eventStore: store)
        event.title     = titel
        event.notes     = notitie.isEmpty ? nil : notitie
        event.startDate = datum
        event.endDate   = datum.addingTimeInterval(7200) // standaard 2 uur
        event.calendar  = store.defaultCalendarForNewEvents
        event.addAlarm(EKAlarm(relativeOffset: -2 * 24 * 3600)) // 2 dagen van tevoren
        event.addAlarm(EKAlarm(relativeOffset: -24 * 3600))     // 1 dag van tevoren

        do {
            try store.save(event, span: .thisEvent, commit: true)
            var dict = opgeslagen
            dict[afspraakId] = event.eventIdentifier
            opgeslagen = dict
            return true
        } catch {
            return false
        }
    }

    func verwijder(afspraakId: String) {
        var dict = opgeslagen
        guard let ident = dict[afspraakId],
              let event = store.event(withIdentifier: ident) else { return }
        try? store.remove(event, span: .thisEvent, commit: true)
        dict.removeValue(forKey: afspraakId)
        opgeslagen = dict
    }

    func heeftAgendaItem(afspraakId: String) -> Bool {
        guard let ident = opgeslagen[afspraakId] else { return false }
        return store.event(withIdentifier: ident) != nil
    }
}
