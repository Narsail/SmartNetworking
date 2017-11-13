//
//  Appointments.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import IGListKit

class Appointment {
    
    let title: String
    let location: String
    let date: Date
    let calenderLink: String
    
    let contacts: [Contact]
    
    init(title: String, location: String, date: Date, calenderLink: String, contacts: [Contact]) {
        self.title = title
        self.location = location
        self.date = date
        self.calenderLink = calenderLink
        self.contacts = contacts
    }
}

extension Appointment: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return date.timeString(in: .full) as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if let object = object as? Appointment {
            return self === object
        }
        return false
    }
    
}

struct Contact {
    
    let profilePicture: Data?
    let name: String
    let jobTitle: String
    
}
