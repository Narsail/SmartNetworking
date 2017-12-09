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
import Timepiece

struct VisitHandler {
    
    static let eventStore = EKEventStore()
    static let contactStore = CNContactStore()
    
    enum VisitHandlerStatus {
        case initial
        case authorized
        case calendarRestricted
        case contactsRestricted
        case doNothing
    }
    
    /// Check the Status of the EventKit and the Contacts
    
    static func status() -> VisitHandlerStatus {
        
        let eventStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)
        let contactStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch (eventStatus, contactStatus) {
        case (.notDetermined, .notDetermined):
            return .initial
        case (.authorized, .authorized):
            return .authorized
        case (.restricted, _), (.denied, _):
            return .calendarRestricted
        case (_, .restricted), (_, .denied):
            return .contactsRestricted
        default:
            return .doNothing
        }
    }
    
    /// Complete fetching Routine
    
    static func fetchVisits(
        from now: Date,
        to until: Date,
        processEventsObservable: PublishSubject<Double>?,
        processContactsObservable: PublishSubject<Double>?
        ) -> Promise<[Visit]> {
        
        return VisitHandler.fetchIphoneUser(in: contactStore)
            
        .then(on: .global()) { meContact -> Promise<[EKEvent]> in
            let (_, promise) = VisitHandler.fetchEvents(in: eventStore, excludeLocationOf: meContact,
                                                        from: now, to: until)
            return promise
        }
        
        .then(on: .global()) { events -> Promise<[Visit]> in
            VisitHandler.packEventsToVisits(with: events, progressSubject: processEventsObservable)
        }
        
        .then(on: .global()) { visits -> Promise<[Visit]> in
            let (_, promise) = VisitHandler.mergeVisits(visits)
            return promise
        }
        
        .then(on: .global()) { visits -> Promise<[Visit]> in
            VisitHandler.assignContactsToVisits(visits, with: contactStore, progressSubject: processContactsObservable)
        }
    }
    
    /// Get Information about the iPhone User
    
    private static func fetchIphoneUser(in store: CNContactStore) -> Promise<CNContact?> {
        
        return Promise(value: nil)
        
    }
    
    /// Get all Events of the Calendar excluding the one in the area of the excluding contact
    ///
    /// - important: The exclude argument is not working yet
    
    private static func fetchEvents(in store: EKEventStore,
                            excludeLocationOf contact: CNContact?,
                            from startDate: Date,
                            to endDate: Date) -> (Observable<Double>, Promise<[EKEvent]>) {
        
        let progressSubject = PublishSubject<Double>()
        
        // If it is a Simulator, create Events (prior delete all)
        if Environment.isSimulator {
            
            // Create two Events
            
            let event = EKEvent(eventStore: store)
            
            event.title = "Business Meeting in Atlanta"
            
            event.startDate = (Date() + 2.days)!
            event.endDate = (Date() + (2.days + 2.hours))!
            event.calendar = store.defaultCalendarForNewEvents
            
            var structuredLocation = EKStructuredLocation(title: "Atlanta")
            structuredLocation.geoLocation = CLLocation(latitude: 33.7489954, longitude: -84.3879824)
            event.structuredLocation = structuredLocation
            
            let secondEvent = EKEvent(eventStore: store)
            
            secondEvent.title = "Businsess Meeting in Munich"
            
            secondEvent.startDate = (Date() + 3.days)!
            secondEvent.endDate = (Date() + (3.days + 2.hours))!
            secondEvent.calendar = store.defaultCalendarForNewEvents
            
            structuredLocation = EKStructuredLocation(title: "Munich")
            structuredLocation.geoLocation = CLLocation(latitude: 48.1351253, longitude: 11.5819805)
            secondEvent.structuredLocation = structuredLocation

            do {
                try store.save(event, span: .thisEvent)
                try store.save(secondEvent, span: .thisEvent)
            } catch {
                print(error)
            }
            
        }
        
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
    
    private static func packEventsToVisits(with events: [EKEvent],
                                           progressSubject: PublishSubject<Double>?) -> Promise<[Visit]> {
        
        let totalAmountOfEvents = events.count
        var eventsProcessed = 0
        
        return Promise { success, failure in
            // Return Immediately if not events given
            if events.isEmpty { success([]); return }
            
            var promise: Promise<[Visit]> = Promise(value: [])
            let geocoder = CLGeocoder()
            
            events.forEach { event in
                
                if let geoLocation = event.structuredLocation?.geoLocation {
                    
                    promise = promise.then { visits -> Promise<([Visit], Location?)> in
                        let key = Key<Location>(event.eventIdentifier)
                        if let location = Defaults().get(for: key) {
                            return Promise(value: (visits, location))
                        } else {
                            return geocoder.reverseGeocode(location: geoLocation).then { placemark -> Promise<([Visit], Location?)> in
                                
                                guard let city = placemark.locality, let country = placemark.country,
                                    let countryCode = placemark.isoCountryCode else {
                                    return Promise(value: (visits, nil))
                                }
                                
                                let location = Location(city: city, country: country, isoCountryCode: countryCode)
                                
                                Defaults().set(location, for: key)
                                
                                return Promise(value: (visits, location))
                            }
                        }
                    }.then { (visits, location) in
                        // Progress
                        eventsProcessed += 1
                        progressSubject?.onNext(Double(eventsProcessed) / Double(totalAmountOfEvents))
                        // Return
                        if let location = location {
                            return Promise(value: visits + [Visit(firstEventID: event.eventIdentifier,
                                                                  location: location,
                                                                  from: event.startDate,
                                                                  toDate: event.endDate,
                                                                  contacts: [])])
                        } else {
                            return Promise(value: visits)
                        }
                        
                    }
                    
                }
                
            }
            
            promise.then { visits -> Void in
                
                print("")
                success(visits)
                
            }.catch { error in
                failure(error)
            }
            
        }
        
    }
    
    /// Merge Visits
    
    internal static func mergeVisits(_ visits: [Visit]) -> (Observable<Double>, Promise<[Visit]>) {
        
        let progressSubject = PublishSubject<Double>()
        
        return (progressSubject, Promise { success, _ in
           
            let mergedVisits: [Visit] = VisitHandler.mergeVisits(visits, with: progressSubject)
            
            success(mergedVisits)
            
        })
        
    }
    
    /// Merge Visits
    
    internal static func mergeVisits(_ visits: [Visit], with progressSubject: PublishSubject<Double>?) -> [Visit] {
        
        // Measure Progress
        let totalAmountOfVisits = visits.count
        var visitsProcessed = 0
        
        // Go through the Visits and merge them together
        var lastVisit: Visit?
        var mergedVisits = [Visit]()
        
        visits.forEach { visit in
            
            if let last = lastVisit {
                
                if last.location == visit.location {
                    lastVisit = Visit(firstEventID: visit.firstEventID, location: visit.location,
                                      from: last.from, toDate: visit.toDate, contacts: [])
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
    
    private static func assignContactsToVisits(
        _ visits: [Visit],
        with contactStore: CNContactStore,
        progressSubject: PublishSubject<Double>?) -> Promise<[Visit]> {
        
        let totalAmountOfVisits = visits.count
        var visitsProcessed = 0
        
        // If in Simulator, create two extra Contacts
        
        if Environment.isSimulator {
            
            // Check whether those contacts are already existing
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactNamePrefixKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let predicate = CNContact.predicateForContacts(matchingName: "Joseph")
            let fetchedContacts = try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            
            if fetchedContacts?.count == 0 {
            
                // Create two Contacts
                let contact = CNMutableContact()
                let adress = CNMutablePostalAddress()
                adress.city = "Munich"
                adress.country = "Germany"
                let secondAdress = CNMutablePostalAddress()
                secondAdress.city = "München"
                secondAdress.country = "Deutschland"
                contact.postalAddresses.append(CNLabeledValue(label: "Work", value: adress))
                contact.postalAddresses.append(CNLabeledValue(label: "Work", value: secondAdress))
                contact.givenName = "Joseph"
                contact.familyName = "Strauß"
                
                let saveRequest = CNSaveRequest()
                saveRequest.add(contact, toContainerWithIdentifier: nil)
                
                let secondContact = CNMutableContact()
                let thirdAdress = CNMutablePostalAddress()
                thirdAdress.city = "Munich"
                thirdAdress.country = "Germany"
                let forthAdress = CNMutablePostalAddress()
                forthAdress.city = "München"
                forthAdress.country = "Deutschland"
                secondContact.postalAddresses.append(CNLabeledValue(label: "Work", value: thirdAdress))
                secondContact.postalAddresses.append(CNLabeledValue(label: "Work", value: forthAdress))
                secondContact.givenName = "Hans"
                secondContact.familyName = "Klepper"
                
                let secondSaveRequest = CNSaveRequest()
                secondSaveRequest.add(secondContact, toContainerWithIdentifier: nil)
                
                do {
                    try contactStore.execute(saveRequest)
                    try contactStore.execute(secondSaveRequest)
                } catch {
                    print(error)
                }
            }
        }
        
        return Promise { success, _ in
            
            var visitsWithContacts = [Visit]()
            
            // Fetch all Contacts (to only fetch them once)
            let contacts = self.fetchAllContacts(with: contactStore)
            
            visits.forEach { visit in
                
                var locationFilteredContacts = [Contact]()
                
                contacts.forEach { contact in
                    
                    let adresses = contact.postalAddresses
                    
                    for address in adresses {
                        
                        let location = Location(city: address.value.city, country: address.value.country,
                                                isoCountryCode: address.value.isoCountryCode)
                        
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
                
                visitsProcessed += 1
                progressSubject?.onNext(Double(visitsProcessed) / Double(totalAmountOfVisits))
                
            }
            
            success(visitsWithContacts)
            
        }
        
    }
    
    private static func fetchAllContacts(with contactStore: CNContactStore) -> [CNContact] {
        
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
