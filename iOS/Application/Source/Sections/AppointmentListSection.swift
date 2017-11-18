//
//  AppointmentListSection.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import IGListKit
import RxSwift
import ContactsUI

class AppointmentSectionController: ListSectionController {
    
    var appointment: Appointment!
    
    var expanded = false
    let displayContact: PublishSubject<String>
    
    var cellWidth: CGFloat {
        return collectionContext!.containerSize.width - 20
    }
    
    init(displayContact: PublishSubject<String>) {
        self.displayContact = displayContact
        super.init()
        // inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
        minimumLineSpacing = 3
    }
    
    override func numberOfItems() -> Int {
        return expanded ? ((self.appointment?.contacts.count ?? 0) + 1): 1
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        if index == 0 {
            return CGSize(width: cellWidth, height: 80)
        } else {
            return CGSize(width: cellWidth, height: 55)
        }
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        
        if index == 0 {
            guard let cell = collectionContext?.dequeueReusableCell(
                withNibName: "AppointmentCell", bundle: nil, for: self, at: index
                ) as? AppointmentCell else { return UICollectionViewCell() }
            
            cell.setAppointment(appointment: self.appointment)
            
            if expanded {
                cell.changeForPosition(.first)
            } else {
                cell.changeForPosition(.alone)
            }
            
            return cell
        } else {
            guard let cell = collectionContext?.dequeueReusableCell(
                withNibName: "ContactCell", bundle: nil, for: self, at: index
                ) as? ContactCell else { return UICollectionViewCell() }
            
            let contact = self.appointment.contacts[index - 1]
            
            cell.setContact(contact: contact)
            
            return cell
        }
        
    }
    
    override func didUpdate(to object: Any) {
        
        if let appointment = object as? Appointment {
            self.appointment = appointment
        }
        
    }
    
    override func didSelectItem(at index: Int) {
        
        if index == 0 {
            expanded = !expanded
            collectionContext?.performBatch(animated: true, updates: { batchContext in
                batchContext.reload(self)
            }, completion: nil)
        } else {
            
            let contactID = self.appointment.contacts[index - 1].contactID
            
            self.displayContact.onNext(contactID)
        }
        
    }
    
}
