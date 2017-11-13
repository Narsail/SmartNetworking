//
//  ContactCell.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import Stevia
import IGListKit

class ContactCell: UICollectionViewCell {
    
    @IBOutlet weak var contactImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var jobTitleLabel: UILabel!
    
    func setContact(contact: Contact) {
        
        self.nameLabel.text = contact.name
        self.jobTitleLabel.text = contact.jobTitle
        
        if let imageData = contact.profilePicture, let image = UIImage(data: imageData) {
            
            self.contactImageView.image = image
            
        }
        
    }
    
}
