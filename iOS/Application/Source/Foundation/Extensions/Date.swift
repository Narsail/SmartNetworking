//
//  Date.swift
//  SmartNetworking
//
//  Created by David Moeller on 07.12.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation

extension Date {
    
    func timeSinceToday() -> String {
        
        let components = Calendar.current.dateComponents([.day, .month, .year], from: self, to: Date())
        
        var labelText = ""
        
        if let days = components.day, let months = components.month, let years = components.year, days > 7
            || months > 1 || years > 1 {
            
            if years > 0 {
                let localizedString = NSLocalizedString("%d years ago", comment: "X Years ago")
                labelText = String(format: localizedString, locale: Locale.current, arguments: [years])
            } else if months > 0 {
                let localizedString = NSLocalizedString("%d months ago", comment: "X Months ago")
                labelText = String(format: localizedString, locale: Locale.current, arguments: [months])
            } else if days > 0 {
                let localizedString = NSLocalizedString("%d days ago", comment: "X Days ago")
                labelText = String(format: localizedString, locale: Locale.current, arguments: [days])
            }
            
        } else {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            
            // let dayOfWeek = (Calendar.current.component(.weekday, from: self) + 7 - Calendar.current.firstWeekday) % 7 + 1
            
            // let weekDay = DateFormatter().weekdaySymbols[dayOfWeek]
            labelText = dateFormatter.string(from: self)
        }
        return labelText
    }
    
    static func days(since date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }
    
    static func days(since dateString: String) -> Int? {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_US_POSIX")
        dateformatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        guard let releaseDate = dateformatter.date(from: dateString) else {
            return nil
        }
        
        return days(since: releaseDate)
    }
    
}
