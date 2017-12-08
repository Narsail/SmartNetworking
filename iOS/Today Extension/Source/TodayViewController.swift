//
//  TodayViewController.swift
//  SmartNetworking - iOS Today Extension
//
//  Created by David Moeller on 07.12.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import UIKit
import NotificationCenter
import Stevia
import Timepiece
import PromiseKit

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var openAppButton: UIButton! {
        didSet {
            openAppButton.setTitle(StringConstants.TodayWidget.openApp, for: .normal)
            openAppButton.layer.borderWidth = 1.0
            openAppButton.layer.borderColor = UIColor.blue.cgColor
            openAppButton.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var infoView: UIView! {
        didSet {
            infoView.backgroundColor = .clear
        }
    }
    
    @IBAction func openAppAction(_ sender: Any) {
        if let url = URL(string: "Smarten://") {
            self.extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        updateContent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        updateContent(initial: false)
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func updateContent(initial: Bool = true) {
        let status = VisitHandler.status()
        
        switch status {
        case .authorized:
            // Update with Loading View but only if no data was shown before
            if initial {
                updateView(generateLoadingView())
            }
            
            let now = Date()
            guard let until = now + 1.month else { updateView(generateNoVisitsView()); return }
            
            firstly {
                VisitHandler.fetchVisits(
                    from: now,
                    to: until,
                    processEventsObservable: nil,
                    processContactsObservable: nil
                )
            }
            
            .then { visits -> Void in
                
                if let visit = visits.first {
                    self.updateView(self.generateVisitView(visit: visit))
                } else {
                    self.updateView(self.generateNoVisitsView())
                }

            }
            
            .catch { error in
                print("Loading Appointments failed with \(error)")
                self.updateView(self.generateNoVisitsView())
            }
            
        default:
            updateView(generateOpenAppView())
        }
        
    }
    
    func updateView(_ view: UIView) {
        
        // Remove all from Info View
        infoView.subviews.forEach { subView in
            subView.removeConstraints(subView.constraints)
            subView.removeFromSuperview()
        }
        
        // Display View
        view.backgroundColor = .clear
        
        infoView.sv(view)
        infoView.layout(
            0,
            |view|,
            0
        )
        
    }
    
    func generateOpenAppView() -> UIView {
        
        let view = UIView()
        
        let label = UILabel()
        label.text = StringConstants.TodayWidget.openAppDescription
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textAlignment = .center
        
        view.sv(label)
        view.layout(
            |-label.centerVertically()-|
        )
        
        return view
    }
    
    func generateLoadingView() -> UIView {
        let view = UIView()
        
        let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        
        view.sv(loadingIndicator)
        view.layout(
            loadingIndicator.centerVertically().centerHorizontally()
        )
        
        loadingIndicator.startAnimating()
        
        return view
    }
    
    func generateNoVisitsView() -> UIView {
        let noVisitView = NoVisitsView()
        
        noVisitView.title.font = UIFont.systemFont(ofSize: 17)
        
        return noVisitView
    }
    
    func generateVisitView(visit: Visit) -> UIView {
        let view = UIView()
        
        let middleView = UIView()
        
        let visitLabel = UILabel()
        visitLabel.text = StringConstants.TodayWidget.nextVisit + visit.location.city
        visitLabel.numberOfLines = 0
        visitLabel.backgroundColor = .clear
        visitLabel.textAlignment = .center
        
        let contactsLabel = UILabel()
        contactsLabel.text = "\(visit.contacts.count) " + StringConstants.TodayWidget.contacts
        contactsLabel.numberOfLines = 0
        contactsLabel.backgroundColor = .clear
        contactsLabel.textAlignment = .center
        
        view.sv(visitLabel, middleView, contactsLabel)
        
        view.layout(
            |-visitLabel-|,
            |-middleView.height(5).centerVertically()-|,
            |-contactsLabel-|
        )
        
        return view
    }
    
}
