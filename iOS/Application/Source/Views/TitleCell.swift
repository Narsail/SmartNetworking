//
//  TitleCell.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import Stevia
import IGListKit

class TitleCell: UICollectionViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        
        label.text = "Title"
        label.font = UIFont.boldSystemFont(ofSize: 35.0)
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupLayout()
    }
    
    func setupLayout() {
        self.sv(
            titleLabel
        )
        self.layout(
            |-20-self.titleLabel
        )
    }
}
