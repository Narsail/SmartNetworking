//
//  AppointmentHandler.swift
//  SmartNetworking
//
//  Created by David Moeller on 15.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import PromiseKit
import RxSwift

struct AppointmentHandler {
    
    /// Find a Match between the Event Location and the Postal Adress
    
    static func isMatchBetween(_ event: EKEvent, _ adress: CNPostalAddress) -> Bool {
        
        // Check that PostalCode is included in Event Location
        return isMatchBetween(event.location, adress.postalCode)
        
    }
    
    static func isMatchBetween(_ eventLocation: String?, _ adressStrings: String...) -> Bool {
        
        guard let locationString = eventLocation else { return false }
        
        var match = true
        
        adressStrings.forEach { adressString in
            if !locationString.contains(find: adressString) {
                match = false
            }
        }
        
        return match
        
    }
    
    static func prepareAppointments(with eventStore: EKEventStore,
                                    and contactStore: CNContactStore,
                                    from startDate: Date,
                                    to endDate: Date) -> (Observable<Double>, Promise<[Appointment]>) {
        
        let progressSubject = PublishSubject<Double>()
        
        return (progressSubject, Promise<[Appointment]> { success, _ in
            
            // Run in the Background
            
            DispatchQueue.global(qos: .background).async {
                
                let calendars = eventStore.calendars(for: EKEntityType.event)
                
                // Use an event store instance to create and properly configure an NSPredicate
                let eventsPredicate = eventStore.predicateForEvents(
                    withStart: startDate, end: endDate, calendars: calendars)
                
                // Use the configured NSPredicate to find and return events in the store that match
                let events = eventStore.events(
                        matching: eventsPredicate
                    ).sorted { (ev1: EKEvent, ev2: EKEvent) -> Bool in
                        return ev1.startDate.compare(ev2.startDate) == ComparisonResult.orderedAscending
                    }
                
                // Remove all appointments with the geolocation of the user (go through his addresses)
                
                // Fetch all Contacts (to only fetch them once
                let contacts = self.fetchAllContacts(with: contactStore)
                
                var appointments = [Appointment]()
                
                let amountOfEvents = events.count
                var eventsProcessed = 0
                
                if amountOfEvents > 0 {
                    progressSubject.onNext(Double(eventsProcessed) / Double(amountOfEvents))
                }
                
                events.forEach { event in
                    
                    var locationFilteredContacts = [Contact]()
                    
                    contacts.forEach { contact in
                        
                        let adresses = contact.postalAddresses
                        
                        for address in adresses {
                            
                            if self.isMatchBetween(event, address.value) {
                                
                                let imageData = try? contactStore.unifiedContact(
                                    withIdentifier: contact.identifier,
                                    keysToFetch: [CNContactImageDataKey] as [CNKeyDescriptor]
                                    ).imageData
                                
                                locationFilteredContacts.append(
                                    Contact(
                                        profilePicture: imageData ?? nil,
                                        name: "\(contact.givenName) \(contact.familyName)",
                                        jobTitle: contact.jobTitle
                                    )
                                )
                                break
                                
                            }
                            
                        }
                        
                    }
                    
                    if locationFilteredContacts.count > 0 {
                        
                        appointments.append(
                            Appointment(
                                city: event.location ?? "Unknown",
                                from: event.startDate,
                                to: event.endDate,
                                contacts: locationFilteredContacts
                            )
                        )
                        
                    }
                    
                    eventsProcessed += 1
                    progressSubject.onNext(Double(eventsProcessed) / Double(amountOfEvents))
                    
                }
                
                success(appointments)
                
            }
            
        })
        
    }
    
    static func fetchAllContacts(with contactStore: CNContactStore) -> [CNContact] {
        
        let keysToFetch = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactJobTitleKey,
            CNContactPostalAddressesKey
        ]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(
                    matching: fetchPredicate,
                    keysToFetch: keysToFetch as [CNKeyDescriptor]
                )
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }
    
}
