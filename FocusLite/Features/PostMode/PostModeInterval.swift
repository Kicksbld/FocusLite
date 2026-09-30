import Foundation

/// Time math of Post Mode (spec F5). Free of Screen Time types, so it can be checked on its own.
enum PostModeInterval {
    /// `DeviceActivitySchedule`'s minimum interval, so the shortest possible Post Mode.
    static let duration: TimeInterval = 15 * 60

    /// Starts at `now` rounded down to the second, since `components(of:)` stops at seconds,
    /// and ends exactly `duration` later. The end is both the schedule's end and `postMode.endsAt`.
    static func starting(at now: Date) -> DateInterval {
        let start = Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate.rounded(.down))
        return DateInterval(start: start, duration: duration)
    }

    /// The full date, not only the time of day: with bare hours and minutes,
    /// 23:55 → 00:10 would end before it starts.
    static func components(of date: Date, in calendar: Calendar = .current) -> DateComponents {
        calendar.dateComponents([.calendar, .year, .month, .day, .hour, .minute, .second], from: date)
    }
}
