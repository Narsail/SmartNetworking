//
//  VisitHandler.swift
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
import ContactsUI
import CoreLocation
import DefaultsKit

struct VisitHandler {
    
    /// Get Information about the iPhone User
    
    static func fetchIphoneUser(in store: CNContactStore) -> Promise<CNContact?> {
        
        return Promise(value: nil)
        
    }
    
    /// Get all Events of the Calendar excluding the one in the area of the excluding contact
    ///
    /// - important: The exclude argument is not working yet
    
    static func fetchEvents(in store: EKEventStore,
                            excludeLocationOf contact: CNContact?,
                            from startDate: Date,
                            to endDate: Date) -> (Observable<Double>, Promise<[EKEvent]>) {
        
        let progressSubject = PublishSubject<Double>()
        
        return (progressSubject, Promise { success, _ in
            
            let calendars = store.calendars(for: EKEntityType.event)
            
            // Use an event store instance to create and properly configure an NSPredicate
            let eventsPredicate = store.predicateForEvents(
                withStart: startDate, end: endDate, calendars: calendars)
            
            // Use the configured NSPredicate to find and return events in the store that match
            let events = store.events(
                matching: eventsPredicate
                ).sorted { (ev1: EKEvent, ev2: EKEvent) -> Bool in
                    return ev1.startDate.compare(ev2.startDate) == ComparisonResult.orderedAscending
            }
            
            progressSubject.onNext(1)
            
            success(events)
        })
        
    }
    
    /// Pack the Events and extract visits
    
    static func packEventsToVisits(with events: [EKEvent]) -> (Observable<Double>, Promise<[Visit]>) {
        
        let progressSubject = PublishSubject<Double>()
        let totalAmountOfEvents = events.count
        var eventsProcessed = 0
        
        return (progressSubject, Promise { success, failure in
            // Return Immediately if not events given
            if events.isEmpty { success([]); return }
            
            var promise: Promise<[Visit]> = Promise(value: [])
            let geocoder = CLGeocoder()
            
            events.forEach { event in
                
                if let geoLocation = event.structuredLocation?.geoLocation {
                    
                    promise = promise.then { visits -> Promise<([Visit], Location)> in
                        let key = Key<Location>(event.eventIdentifier)
                        
                        if let location = Defaults().get(for: key) {
                            return Promise(value: (visits, location))
                        } else {
                            return geocoder.reverseGeocode(location: geoLocation).then { placemark -> Promise<([Visit], Location)> in
                                guard let city = placemark.locality, let country = placemark.country else {
                                    throw LocationError.locationNotFoundByGeoCoder
                                }
                                
                                return Promise(value: (visits, Location(city: city, country: country)))
                            }
                        }
                    }.then { (visits, location) in
                        // Progress
                        eventsProcessed += 1
                        progressSubject.onNext(Double(eventsProcessed) / Double(totalAmountOfEvents))
                        // Return
                        return Promise(value: visits + [Visit(location: location, from: event.startDate, toDate: event.endDate, contacts: [])])
                    }
                    
                }
                
            }
            
            promise.then { visits -> Void in
                
                success(visits)
                
            }.catch { error in
                failure(error)
            }
            
        })
        
    }
    
    /// Merge Visits
    
    static func mergeVisits(_ visits: [Visit]) -> (Observable<Double>, Promise<[Visit]>) {
        
        let progressSubject = PublishSubject<Double>()
        
        return (progressSubject, Promise { success, _ in
           
            let mergedVisits: [Visit] = VisitHandler.mergeVisits(visits, with: progressSubject)
            
            success(mergedVisits)
            
        })
        
    }
    
    /// Merge Visits
    
    static func mergeVisits(_ visits: [Visit], with progressSubject: PublishSubject<Double>?) -> [Visit] {
        
        // Measure Progress
        let totalAmountOfVisits = visits.count
        var visitsProcessed = 0
        
        // Go through the Visits and merge them together
        var lastVisit: Visit?
        var mergedVisits = [Visit]()
        
        visits.forEach { visit in
            
            if let last = lastVisit {
                
                if last.location == visit.location {
                    lastVisit = Visit(location: visit.location, from: last.from, toDate: visit.toDate, contacts: [])
                } else {
                    mergedVisits.append(last)
                    lastVisit = visit
                }
                
            } else {
                lastVisit = visit
            }
            
            visitsProcessed += 1
            progressSubject?.onNext(Double(visitsProcessed) / Double(totalAmountOfVisits))
            
        }
        
        if let last = lastVisit {
            mergedVisits.append(last)
        }
        
        return mergedVisits
    }
    
    /// Assign Contacts to the Visits
    
    static func assignContactsToVisits(_ visits: [Visit], with contactStore: CNContactStore) -> Promise<[Visit]> {
        
        return Promise { success, _ in
            
            var visitsWithContacts = [Visit]()
            
            // Fetch all Contacts (to only fetch them once)
            let contacts = self.fetchAllContacts(with: contactStore)
            
            visits.forEach { visit in
                
                var locationFilteredContacts = [Contact]()
                
                contacts.forEach { contact in
                    
                    let adresses = contact.postalAddresses
                    
                    for address in adresses {
                        
                        let location = Location(city: address.value.city, country: address.value.country)
                        
                        if location == visit.location {
                            
                            let imageData = try? contactStore.unifiedContact(
                                withIdentifier: contact.identifier,
                                keysToFetch: [CNContactImageDataKey] as [CNKeyDescriptor]
                                ).imageData
                            
                            locationFilteredContacts.append(
                                Contact(
                                    profilePicture: imageData ?? nil,
                                    name: "\(contact.givenName) \(contact.familyName)",
                                    jobTitle: contact.jobTitle,
                                    contactID: contact.identifier
                                )
                            )
                            break
                            
                        }
                        
                    }
                    
                }
                
                if locationFilteredContacts.count > 0 {
                    
                    visitsWithContacts.append(
                        visit.addContacts(locationFilteredContacts)
                    )
                    
                }
                
            }
            
            success(visitsWithContacts)
            
        }
        
    }
    
    
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
    
    static func getContactViewController(for contactID: String,
                                         with contactStore: CNContactStore) throws -> CNContactViewController {
        
        let contact = try contactStore.unifiedContact(
            withIdentifier: contactID,
            keysToFetch: [CNContactViewController.descriptorForRequiredKeys()]
        )
        
        return CNContactViewController(for: contact)
        
    }
    
}
