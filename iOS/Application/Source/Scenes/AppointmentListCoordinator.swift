//
//  AppointmentListCoordinator.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import RxSwift

class AppointmentListCoordinator: BaseCoordinator<Void> {
    
    private let rootViewController: UIViewController
    
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    override func start() -> Observable<Void> {
        
        let viewModel = AppointmentListViewModel()
        let viewController = AppointmentListViewController(viewModel: viewModel)
        
        self.rootViewController.present(viewController, animated: true, completion: nil)
        
        return Observable.never()
        
    }
    
}
