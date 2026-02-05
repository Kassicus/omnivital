//
//  Date+Extensions.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    var startOfSleepQuery: Date {
        // Sleep query starts from previous day at noon (12 hours before midnight)
        Calendar.current.date(byAdding: .hour, value: -12, to: startOfDay) ?? self
    }
}
