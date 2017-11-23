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
import PromiseKit
import ContactsUI

class AppointmentListViewModel {
    
    let disposeBag = DisposeBag()
    
    let adapterDataSource: AppointmentListAdapterDataSource
    
    let eventStore = EKEventStore()
    let contactStore = CNContactStore()
    
    // MARK: - Outputs
    
    let contentUpdated = PublishSubject<Void>()
    var displayContact: Observable<CNContactViewController>? = nil
    
    init() {
        
        let displayContactID = PublishSubject<String>()
        
        self.adapterDataSource = AppointmentListAdapterDataSource(title: StringConstants.Visits.title,
                                                                  displayContact: displayContactID)
        
        displayContact = displayContactID.map { contactID in
            return try VisitHandler.getContactViewController(for: contactID, with: self.contactStore)
        }
        
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
        case (.restricted, _), (.denied, _):
            needCalendarPermission()
        case (_, .restricted), (_, .denied):
            needContactPermission()
        default:
            return
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
        
        // Set View for Empty CollectionView
        self.adapterDataSource.viewForEmptyCollectionView = ProgressView()
        self.adapterDataSource.appointments = []
        self.contentUpdated.onNext(())
        
        firstly {
            VisitHandler.fetchIphoneUser(in: self.contactStore)
        }
        
        .then { meContact -> Promise<[EKEvent]> in
            let (_, promise) = VisitHandler.fetchEvents(in: self.eventStore, excludeLocationOf: meContact,
                                                        from: now, to: until)
            return promise
        }
        
        .then { events -> Promise<[Visit]> in
            let (progressObservable, promise) = VisitHandler.packEventsToVisits(with: events)
            
            progressObservable.observeOn(MainScheduler.instance).subscribe(onNext: { progress in
                guard let progressView = self.adapterDataSource.viewForEmptyCollectionView as? ProgressView else {
                    return
                }
                progressView.title.text = StringConstants.Progress.processAppointments
                progressView.progressView.setProgress(Float(progress), animated: true)
            }).disposed(by: self.disposeBag)
            
            return promise
        }
        
        .then { visits -> Promise<[Visit]> in
            let (_, promise) = VisitHandler.mergeVisits(visits)
            return promise
        }
        
        .then { visits -> Promise<[Visit]> in
            let (progressObservable, promise) = VisitHandler.assignContactsToVisits(visits, with: self.contactStore)
            
            progressObservable.observeOn(MainScheduler.instance).subscribe(onNext: { progress in
                guard let progressView = self.adapterDataSource.viewForEmptyCollectionView as? ProgressView else {
                    return
                }
                progressView.title.text = StringConstants.Progress.processContacts
                progressView.progressView.setProgress(Float(progress), animated: true)
            }).disposed(by: self.disposeBag)
            
            return promise
        }

        .then { visits -> Void in
            // Put it into the IG List
            self.adapterDataSource.appointments = visits
            // Remove View
            if visits.count < 1 {
                self.adapterDataSource.viewForEmptyCollectionView = NoVisitsView()
            } else {
                self.adapterDataSource.viewForEmptyCollectionView = nil
            }
            // Reload IG List
            self.contentUpdated.onNext(())
        }

        .catch { error in
            print("Loading Appointments failed with \(error)")
        }
        
    }
    
    func needCalendarPermission() {
        
        self.adapterDataSource.viewForEmptyCollectionView = PermissionView(state: .calendars)
        self.contentUpdated.onNext(())
        
    }
    
    func needContactPermission() {
        
        self.adapterDataSource.viewForEmptyCollectionView = PermissionView(state: .contacts)
        self.contentUpdated.onNext(())
        
    }
}

class AppointmentListAdapterDataSource: NSObject {
    
    var appointments = [Visit]()
    let title: String
    var viewForEmptyCollectionView: UIView?
    
    let displayContact: PublishSubject<String>
    
    init(title: String, displayContact: PublishSubject<String>) {
        self.title = title
        self.displayContact = displayContact
        super.init()
    }
    
}

extension AppointmentListAdapterDataSource: ListAdapterDataSource {
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        
        if appointments.count > 0 {
            return [self.title as NSString] + appointments
        }
        return []
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        switch object {
        case is Visit:
            return AppointmentSectionController(displayContact: self.displayContact)
        default:
            return TitleSectionController()
        }
        
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return self.viewForEmptyCollectionView
    }
    
}
