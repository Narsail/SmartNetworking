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
    
    let city: String
    let from: Date
    let to: Date
    
    let contacts: [Contact]
    
    init(city: String, from: Date, to: Date, contacts: [Contact]) {
        self.city = city
        self.from = from
        self.to = to
        self.contacts = contacts
    }
}

extension Appointment: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return (from.timeString(in: .full) + to.timeString(in: .full)) as NSString
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
