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

class AppointmentListViewModel {
    
    let disposeBag = DisposeBag()
    
    let adapterDataSource: AppointmentListAdapterDataSource
    
    let eventStore = EKEventStore()
    let contactStore = CNContactStore()
    
    // MARK: - Outputs
    
    var contentUpdated = PublishSubject<Void>()
    
    init() {
        
        self.adapterDataSource = AppointmentListAdapterDataSource(title: StringConstants.Visits.title)
        
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
        
        // prepare Data
        let (progressObservable, appointmentsPromise) = AppointmentHandler.prepareAppointments(
            with: self.eventStore, and: self.contactStore, from: now, to: until
        )
        
        // Update the Progress View
        progressObservable.observeOn(MainScheduler.instance).subscribe(onNext: { progress in
            guard let progressView = self.adapterDataSource.viewForEmptyCollectionView as? ProgressView else { return }
            progressView.progressView.setProgress(Float(progress), animated: true)
        }).disposed(by: disposeBag)
        
        // Handle the finished Appointments
        
        firstly {
            appointmentsPromise
        }
        
        .then { appointments -> Void in
            // Put it into the IG List
            self.adapterDataSource.appointments = appointments
            // Remove View
            if appointments.count < 1 {
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
    
    var appointments = [Appointment]()
    let title: String
    var viewForEmptyCollectionView: UIView?
    
    init(title: String) {
        self.title = title
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
        case is Appointment:
            return AppointmentSectionController()
        default:
            return TitleSectionController()
        }
        
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return self.viewForEmptyCollectionView
    }
    
}
