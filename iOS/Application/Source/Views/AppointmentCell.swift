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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var topCornerHiddingComponent: UIView!
    @IBOutlet weak var bottomCornerHiddingComponent: UIView!
    
    func setAppointment(appointment: Appointment) {
        self.titleLabel.text = appointment.title
        self.locationLabel.text = appointment.location
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
