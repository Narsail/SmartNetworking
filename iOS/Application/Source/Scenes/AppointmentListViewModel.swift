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

class AppointmentListViewModel: NSObject {
    
    let disposeBag = DisposeBag()
    
    weak var displayDelegate: ListDisplayDelegate?
    
    let eventStore = EKEventStore()
    let contactStore = CNContactStore()
    
    // MARK: - Variables
    
    var appointments = [Visit]()
    let title: String
    let displayContactID = PublishSubject<String>()
    var viewForEmptyCollectionView: UIView?
    
    // MARK: - Outputs
    
    let contentUpdated = PublishSubject<Void>()
    var displayContact: Observable<CNContactViewController>?
    
    override init() {
        
        self.title = StringConstants.Visits.title
        
        super.init()
        
        displayContact = displayContactID.map { contactID in
            return try VisitHandler.getContactViewController(for: contactID, with: self.contactStore)
        }
        
    }
    
    func checkStatus() {
        
        let status = VisitHandler.status()
        
        switch status {
        case .initial:
            requestAccessToCalendar()
            requestAccessToContacts()
        case .authorized:
            reloadData()
        case .calendarRestricted:
            needCalendarPermission()
        case .contactsRestricted:
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
        DispatchQueue.main.async {
            self.viewForEmptyCollectionView = ProgressView()
            self.appointments = []
            self.contentUpdated.onNext(())
        }
        
        let eventProcessingObservable = PublishSubject<Double>()
        let contactsProcessingObservable = PublishSubject<Double>()
        
        firstly {
            VisitHandler.fetchVisits(
                from: now,
                to: until,
                processEventsObservable: eventProcessingObservable,
                processContactsObservable: contactsProcessingObservable
            )
        }

        .then { visits -> Void in
            // Put it into the IG List
            self.appointments = visits
            // Remove View
            if visits.count < 1 {
                self.viewForEmptyCollectionView = NoVisitsView()
            } else {
                self.viewForEmptyCollectionView = nil
            }
            // Reload IG List
            self.contentUpdated.onNext(())
        }

        .catch { error in
            print("Loading Appointments failed with \(error)")
        }
        
        eventProcessingObservable.observeOn(MainScheduler.instance).subscribe(onNext: { progress in
            guard let progressView = self.viewForEmptyCollectionView as? ProgressView else {
                return
            }
            progressView.title.text = StringConstants.Progress.processAppointments
            progressView.progressView.setProgress(Float(progress), animated: true)
        }).disposed(by: disposeBag)
        
        contactsProcessingObservable.observeOn(MainScheduler.instance).subscribe(onNext: { progress in
            guard let progressView = self.viewForEmptyCollectionView as? ProgressView else {
                return
            }
            progressView.title.text = StringConstants.Progress.processContacts
            progressView.progressView.setProgress(Float(progress), animated: true)
        }).disposed(by: self.disposeBag)
        
    }
    
    func needCalendarPermission() {
        print("Needs Calendar Permissions.")
        DispatchQueue.main.async {
            self.viewForEmptyCollectionView = PermissionView(state: .calendars)
            self.contentUpdated.onNext(())
        }

    }
    
    func needContactPermission() {
        print("Needs Contact Permissions.")
        DispatchQueue.main.async {
            self.viewForEmptyCollectionView = PermissionView(state: .contacts)
            self.contentUpdated.onNext(())
        }

    }
}

extension AppointmentListViewModel: ListAdapterDataSource {
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        if appointments.count > 0 {
            return [self.title as NSString] + appointments
        }
        return []
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        
        switch object {
        case is Visit:
            return AppointmentSectionController(displayContact: self.displayContactID)
        case is NSString:
            let sectionController = TitleSectionController()
            sectionController.displayDelegate = self.displayDelegate
            return sectionController
        default:
            fatalError("Unknown Object wants Section Contoller")
        }
        
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return self.viewForEmptyCollectionView
    }
    
}
