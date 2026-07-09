//
//  DateFormatter.swift
//
//
//  Created by Alsey Coleman Miller on 9/2/23.
//

import Foundation

internal extension DateFormatter {

    convenience init(
        dateFormat: String,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        timeZone: TimeZone,
        calendar calendarIdentifier: Calendar.Identifier = .gregorian
    ) {
        self.init()
        // calendar
        var calendar = Calendar(identifier: calendarIdentifier)
        calendar.timeZone = timeZone
        calendar.locale = locale
        // formatter
        self.locale = calendar.locale
        self.timeZone = calendar.timeZone
        self.calendar = calendar
        self.dateFormat = dateFormat
    }
}
