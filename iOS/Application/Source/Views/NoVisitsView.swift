//
//  NoVisitsView.swift
//  SmartNetworking
//
//  Created by David Moeller on 16.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import UIKit
import Stevia

class NoVisitsView: UIView {
    
    let title: UILabel = {
        let label = UILabel()
        
        label.text = StringConstants.Visits.noVisits
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: Constants.Labels.viewForEmptyCollectionViewLabelFontSize)
        
        return label
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.sv([self.title])
        
        self.layout(
            |-25-self.title.centerVertically()-25-|
        )
    }
    
}
