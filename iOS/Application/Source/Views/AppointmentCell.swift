//
//  AppointmentCell.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import Stevia
import IGListKit

class AppointmentCell: WhiteBorderCell {
    
    @IBOutlet weak var numberOfContactsLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var fromToRange: UILabel!
    
    @IBOutlet weak var topCornerHiddingComponent: UIView!
    @IBOutlet weak var bottomCornerHiddingComponent: UIView!
    
    func setAppointment(appointment: Appointment) {
        
        self.cityLabel.text = appointment.city
        self.numberOfContactsLabel.text = "\(appointment.contacts.count)"
        
        let dateFormatter = DateFormatter()
        let localFormatter = DateFormatter.dateFormat(fromTemplate: "yyyy/MM/dd", options: 0, locale: NSLocale.current)
        dateFormatter.dateFormat = localFormatter
        
        let fromDate = dateFormatter.string(from: appointment.from)
        let toDate = dateFormatter.string(from: appointment.toDate)
        
        self.fromToRange.text = fromDate + " - " + toDate
    }
    
    enum CellPosition {
        case first
        case inBetween
        case last
        case alone
    }
    
    func changeForPosition(_ position: CellPosition) {
        
        topCornerHiddingComponent.isHidden = false
        bottomCornerHiddingComponent.isHidden = false
        
        switch position {
        case .first:
            topCornerHiddingComponent.isHidden = true
        case .last:
            bottomCornerHiddingComponent.isHidden = true
        case .alone:
            topCornerHiddingComponent.isHidden = true
            bottomCornerHiddingComponent.isHidden = true
        default:
            return
        }
        
    }
}
