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
import EventKit
@testable import SmartNetworking

class AppointmentHandlerSpec: QuickSpec {
    
    override func spec() {
        
        describe("testing basic functions") {
            
            let contactAdress = "98660"
            
            let eventLocation = "Lengfelderstraße 15, 98660, Themar, Germany"
            
            it("match the Contact Adress with the Location") {
                
                expect(AppointmentHandler.isMatchBetween(eventLocation, contactAdress)).to(beTrue())
                
            }
            
        }
        
    }
    
}
