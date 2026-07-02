struct CalendarEventCacheUpdate: Equatable {
    let events: [CalendarEvent]
    let statusMessage: String?

    static func clear(statusMessage: String? = nil) -> CalendarEventCacheUpdate {
        CalendarEventCacheUpdate(events: [], statusMessage: statusMessage)
    }

    static func loaded(
        _ events: [CalendarEvent],
        emptyStatusMessage: String,
        loadedStatusMessage: String
    ) -> CalendarEventCacheUpdate {
        CalendarEventCacheUpdate(
            events: events,
            statusMessage: events.isEmpty ? emptyStatusMessage : loadedStatusMessage
        )
    }
}
