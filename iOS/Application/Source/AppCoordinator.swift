//
//  AppCoordinator.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import UIKit
import RxSwift
import DefaultsKit
import StoreKit

class AppCoordinator: BaseCoordinator<Void> {
    
    private let window: UIWindow
    private let rootViewController: UIViewController = {
        // Instantiate the LaunchScreen
        if let launchScreenController = UIStoryboard(name: "LaunchScreen", bundle: nil)
            .instantiateInitialViewController() {
            return launchScreenController
        }
        return UIViewController()
    }()
    
    init(window: UIWindow) {
        self.window = window
        
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
    }
    
    override func start() -> Observable<Void> {
        
        self.checkForReview()
        
        return coordinate(to: AppointmentListCoordinator(rootViewController: rootViewController))
        
    }
    
    func checkForReview() {
        
        // Check last set Date
        let lastReviewDateKey = Key<Date>("lastReviewDate")
        
        if let lastReviewDate = Defaults.shared.get(for: lastReviewDateKey) {
            
            if Date.days(since: lastReviewDate) > 30 {
                SKStoreReviewController.requestReview()
            } else {
                return
            }
            
        }
        
        // Set new Date
        Defaults.shared.set(Date(), for: lastReviewDateKey)
        
    }
    
}
