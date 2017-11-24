//
//  Appointments.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import IGListKit

class Visit {
    
    let firstEventID: String
    let location: Location
    let from: Date
    let toDate: Date
    
    let contacts: [Contact]
    
    init(firstEventID: String, location: Location, from: Date, toDate: Date, contacts: [Contact]) {
        self.firstEventID = firstEventID
        self.location = location
        self.from = from
        self.toDate = toDate
        self.contacts = contacts
    }
    
    func addContacts(_ contacts: [Contact]) -> Visit {
        return Visit(firstEventID: self.firstEventID, location: self.location, from: self.from,
                     toDate: self.toDate, contacts: self.contacts + contacts)
    }
}

extension Visit: ListDiffable {
    
    func diffIdentifier() -> NSObjectProtocol {
        return firstEventID as NSString
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        if let object = object as? Visit {
            return self === object
        }
        return false
    }
    
}

struct Contact {
    
    let profilePicture: Data?
    let name: String
    let jobTitle: String
    let contactID: String
    
}

enum LocationError: Error {
    case locationNotFoundByGeoCoder
}

func == (lhs: Location, rhs: Location) -> Bool {
    return lhs.city.lowercased() == rhs.city.lowercased() &&
        (lhs.country.lowercased() == rhs.country.lowercased() || lhs.isoCountryCode.lowercased() ==
            rhs.isoCountryCode.lowercased() )
}

struct Location: Codable {
    
    let city: String
    let country: String
    let isoCountryCode: String
    
}
