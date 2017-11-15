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
            let appointments = AppointmentHandler.prepareAppointments(with: self.eventStore, and: self.contactStore,
                                                                      from: now, to: until)
            // Put it into the IG List
            self.adapterDataSource.appointments = appointments
            // Reload IG List
            self.contentUpdated.onNext(())
        }
        
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
