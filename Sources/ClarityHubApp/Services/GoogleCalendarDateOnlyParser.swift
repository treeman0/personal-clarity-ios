import Foundation

enum GoogleCalendarDateOnlyParser {
    static func date(from value: String, timeZone: TimeZone = .current) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
