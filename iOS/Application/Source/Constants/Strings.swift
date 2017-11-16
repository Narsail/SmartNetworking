//
//  Strings.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation

enum StringConstants {
    
    enum Visits {
        
        static let title = NSLocalizedString("visits.title", value:"Visits", comment: "A Visit to a City.")
        static let noVisits = NSLocalizedString("visits.noVisits",
            value:"You have no visits planned within the next 30 days.",
            comment: "A Visit to a City."
        )
        
    }
    
    enum Progress {
        
        static let processAppointments = NSLocalizedString("progress.processAppointments",
            value: "Processing the Calendar Events...",
            comment: "Progress of processing the Appointments."
        )
        
    }
    
    enum Permission {
        
        static let calendarPermission = NSLocalizedString(
            "permission.calendarPermission",
            value: "Please go to the Settings and give access to your Calendars.",
            comment: "Give access to the Calendar."
        )
        static let contactPermission = NSLocalizedString(
            "permission.contactPermission",
            value: "Please go to the Settings and give access to your Contacts.",
            comment: "Give access to your Contacts."
        )
        static let goToSettingsButton = NSLocalizedString(
            "permission.goToSettingsButton",
            value: "Go to Settings.",
            comment: "A Button to go to the Settings."
        )
        
    }
    
}
