//
//  PermissionView.swift
//  SmartNetworking
//
//  Created by David Moeller on 16.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import UIKit
import Stevia

class PermissionView: UIView {
    
    enum PermissionViewState {
        case calendars
        case contacts
    }
    let title: UILabel = {
        let label = UILabel()
        
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: Constants.Labels.viewForEmptyCollectionViewLabelFontSize)
        
        return label
    }()
    let goToSettingsButton: UIButton = {
        
        let button = UIButton(type: UIButtonType.roundedRect)
        
        button.setTitle(StringConstants.Permission.goToSettingsButton, for: UIControlState.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Constants.Labels.viewForEmptyCollectionViewLabelFontSize)
        button.addTarget(self, action: #selector(goToSettings), for: UIControlEvents.touchUpInside)
        
        return button
        
    }()
    
    init(state: PermissionViewState) {
        super.init(frame: CGRect.zero)
        
        switch state {
        case .calendars:
            self.title.text = StringConstants.Permission.calendarPermission
        case .contacts:
            self.title.text = StringConstants.Permission.contactPermission
        }
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.sv([self.title, self.goToSettingsButton])
        
        self.layout(
            |-25-self.title.centerVertically().centerHorizontally()-25-|,
            50,
            |-25-self.goToSettingsButton.centerHorizontally().height(50)-25-|
        )
    }
    
    @objc func goToSettings() {
        guard let openSettingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
        UIApplication.shared.open(openSettingsUrl, options: [:], completionHandler: nil)
    }
    
}
