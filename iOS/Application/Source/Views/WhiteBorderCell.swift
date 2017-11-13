//
//  WhiteBorderCell.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import UIKit

class WhiteBorderCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWhiteBoarder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupWhiteBoarder()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupWhiteBoarder()
        
    }
    
    func setupWhiteBoarder() {
        
        self.backgroundColor = .white
        self.alpha = 1.0
        self.isOpaque = true
        
        // categoryLabel.textColor = UIColor.vegaGray
        layer.cornerRadius = 6
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.masksToBounds = false
        
    }
}
