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
    
    @IBOutlet weak var borderView: UIView!
    @IBOutlet weak var contactImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var jobTitleLabel: UILabel!
    
    func setContact(contact: Contact) {
        
        setupWhiteBoarder()
        
        self.nameLabel.text = contact.name
        self.jobTitleLabel.text = contact.jobTitle
        
        if let imageData = contact.profilePicture, let image = UIImage(data: imageData) {
            
            self.contactImageView.image = image
            
        } else {
            self.contactImageView.image = #imageLiteral(resourceName: "contact")
        }
        
    }
    
    func setupWhiteBoarder() {
        
        self.backgroundColor = .clear
        
        borderView.backgroundColor = .white
        borderView.alpha = 1.0
        borderView.isOpaque = true
        
        // categoryLabel.textColor = UIColor.vegaGray
        borderView.layer.cornerRadius = 6
        borderView.layer.shadowColor = UIColor.black.cgColor
        borderView.layer.shadowOpacity = 0.2
        borderView.layer.shadowOffset = CGSize(width: 0, height: 0)
        borderView.layer.masksToBounds = false
        
    }
    
}
