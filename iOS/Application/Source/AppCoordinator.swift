//
//  AppCoordinator.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import UIKit
import RxSwift

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
        
        return coordinate(to: AppointmentListCoordinator(rootViewController: rootViewController))
        
    }
    
}
