//
//  AppointmentHandlerSpec.swift
//  iOS Unit Tests
//
//  Created by David Moeller on 15.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import Nimble
import Quick
import Contacts
import Timepiece
import EventKit
@testable import SmartNetworking

class VisitHandlerSpec: QuickSpec {
    
    override func spec() {
        
        describe("testing basic functions") {
            
            it("merge two visits") {
                
                let from = Date().changed(day: -1)!
                let to = Date().changed(hour: -16)!
                
                let visits: [Visit] = [
                    Visit(
                        location: Location(city: "Munich", country: "Germany"),
                        from: from,
                        toDate: Date().changed(hour: -22)!,
                        contacts: []
                    ),
                    Visit(
                        location: Location(city: "Munich", country: "Germany"),
                        from: Date().changed(hour: -20)!,
                        toDate: to,
                        contacts: []
                    )
                ]
                
                expect(VisitHandler.mergeVisits(visits, with: nil)).to(allPass { $0?.from == from && $0?.toDate == to })
                expect(VisitHandler.mergeVisits(visits, with: nil)).to(haveCount(1))
                
            }
            
            it("don't merge two visits with a different in between") {
                
                let from = Date().changed(day: -1)!
                let to = Date().changed(hour: -16)!
                
                let visits: [Visit] = [
                    Visit(
                        location: Location(city: "Munich", country: "Germany"),
                        from: from,
                        toDate: Date().changed(hour: -22)!,
                        contacts: []
                    ),
                    Visit(
                        location: Location(city: "Munich", country: "USA"),
                        from: Date().changed(hour: -22)!,
                        toDate: Date().changed(hour: -20)!,
                        contacts: []
                    ),
                    Visit(
                        location: Location(city: "Munich", country: "Germany"),
                        from: Date().changed(hour: -20)!,
                        toDate: to,
                        contacts: []
                    )
                ]
                
                expect(VisitHandler.mergeVisits(visits, with: nil)).to(haveCount(3))
                
            }
            
        }
        
    }
    
}
