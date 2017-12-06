//
//  AppDelegate.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import UIKit
import RxSwift
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let window = UIWindow()
        self.window = window
        
        if Environment.isDebug {
            Fabric.with([Crashlytics.self])
        } else {
            Fabric.with([Crashlytics.self, Answers.self])
        }
        
        // Start the AppCoordinator
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start().subscribe().disposed(by: disposeBag)
        return true
    }

}
