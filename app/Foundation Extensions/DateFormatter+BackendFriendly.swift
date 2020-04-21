//
//  DateFormatter+BackendFriendly.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/21/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

extension DateFormatter {
    // http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
    
    // "Mon, 13 Apr 2020 22:46:09 GMT"
    static var fromServerFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }
    
    // "2020-04-06T18:07:22-00:00"
    static var toServerFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZZZZZ"
        return formatter
    }
    
    func dateForClient(from backendResponseString: String) -> Date? {
        return DateFormatter.fromServerFormatter.date(from: backendResponseString)
    }
    
    func stringForServer(from date: Date) -> String {
        return DateFormatter.toServerFormatter.string(from: date)
    }
}
