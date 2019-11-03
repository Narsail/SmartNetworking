//
//  AppDelegate.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

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
        
        let rootViewController = UIHostingController(rootView: DisplayContactsView())
        window.rootViewController = rootViewController
        
        return true
    }
    
}
