//
//  AppointmentListViewModel.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import EventKit
import Contacts
import Timepiece
import CoreLocation
import IGListKit
import RxSwift

class AppointmentListViewModel {
    
    let adapterDataSource: AppointmentListAdapterDataSource
    
    let eventStore = EKEventStore()
    let contactStore = CNContactStore()
    
    // MARK: - Outputs
    
    var contentUpdated = PublishSubject<Void>()
    
    init() {
        
        self.adapterDataSource = AppointmentListAdapterDataSource(title: StringConstants.Appointment.appointment)
        
        checkStatus()
        
    }
    
    func checkStatus() {
        let eventStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)
        let contactStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch (eventStatus, contactStatus) {
        case (.notDetermined, .notDetermined):
            requestAccessToCalendar()
            requestAccessToContacts()
        case (.authorized, .authorized):
            reloadData()
        default:
            needPermission()
        }
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: { _, _ in
            self.checkStatus()
        })
    }
    
    func requestAccessToContacts() {
        contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { _, _ in
            self.checkStatus()
        })
    }
    
    func reloadData() {
        let now = Date()
        guard let until = now + 1.month else { return }
        // prepare Data
        DispatchQueue.global(qos: .background).async {
            let appointments = self.prepareAppointments(from: now, to: until)
            // Put it into the IG List
            self.adapterDataSource.appointments = appointments
            // Reload IG List
            self.contentUpdated.onNext(())
        }
        
    }
    
    func prepareAppointments(from startDate: Date, to endDate: Date) -> [Appointment] {
        
        let calendars = eventStore.calendars(for: EKEntityType.event)
        
        // Use an event store instance to create and properly configure an NSPredicate
        let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        // Use the configured NSPredicate to find and return events in the store that match
        let events = eventStore.events(matching: eventsPredicate).sorted { (ev1: EKEvent, ev2: EKEvent) -> Bool in
            return ev1.startDate.compare(ev2.startDate) == ComparisonResult.orderedAscending
        }
        
        // Remove all appointments with the geolocation of the user (go through his addresses)
        
        // Fetch all Contacts (to only fetch them once
        let contacts = self.fetchAllContacts()
        
        var appointments = [Appointment]()
        
        events.forEach { event in
            
            var locationFilteredContacts = [Contact]()
            
            contacts.forEach { contact in
                
                let adresses = contact.postalAddresses
                
                for address in adresses {
                    
                    let postalCode = address.value.postalCode
                    
                    if event.location?.contains(find: postalCode) ?? false {
                        
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
                        title: event.title,
                        location: event.location ?? "Unknown",
                        date: event.occurrenceDate,
                        calenderLink: "",
                        contacts: locationFilteredContacts
                    )
                )
                
            }
            
        }
        
        print()
        print("All Appointments:")
        print(appointments)
        
        return appointments
        
    }
    
    func fetchAllContacts() -> [CNContact] {
        
        
        
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
    
    func needPermission() {
        
    }
    
    func goToSettings() {
        let openSettingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(openSettingsUrl!)
    }
    
}

class AppointmentListAdapterDataSource: NSObject {
    
    var appointments = [Appointment]()
    let title: String
    
    init(title: String) {
        self.title = title
        super.init()
    }
    
}

extension AppointmentListAdapterDataSource: ListAdapterDataSource {
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return [self.title as NSString] + appointments
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        switch object {
        case is Appointment:
            return AppointmentSectionController()
        default:
            return TitleSectionController()
        }
        
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}
