//
//  iOS_Snapshot.swift
//  iOS Snapshot
//
//  Created by David Moeller on 23.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import XCTest

class SmartNetworkingSnapshot: XCTestCase {
    
    let app = XCUIApplication()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        setupSnapshot(app)
        app.launchArguments.append("resetApp")
        app.launch()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        sleep(3)
        
        addUIInterruptionMonitor(withDescription: "Calendar Access") { (alert) -> Bool in
            alert.buttons["OK"].tap()
            return true
        }
        app.tap()
        
        sleep(3)
        
        addUIInterruptionMonitor(withDescription: "Contacts Access") { (alert) -> Bool in
            alert.buttons["OK"].tap()
            return true
        }
        app.tap()
        
        snapshot("Overview", timeWaitingForIdle: 5)
        
        let collectionViewsQuery = app.collectionViews
        
        if collectionViewsQuery.staticTexts["Atlanta, United States"].exists {
            collectionViewsQuery.staticTexts["Atlanta, United States"].tap()
        }
        if collectionViewsQuery.staticTexts["Atlanta, Vereinigte Staaten"].exists {
            collectionViewsQuery.staticTexts["Atlanta, Vereinigte Staaten"].tap()
        }
        
        sleep(1)
        
        snapshot("One opened")
        
        if collectionViewsQuery.staticTexts["Munich, Germany"].exists {
            collectionViewsQuery.staticTexts["Munich, Germany"].tap()
        }
        
        if collectionViewsQuery.staticTexts["München, Deutschland"].exists {
            collectionViewsQuery.staticTexts["München, Deutschland"].tap()
        }
        
        sleep(1)
        
        snapshot("Two opened")
        
    }
    
}
