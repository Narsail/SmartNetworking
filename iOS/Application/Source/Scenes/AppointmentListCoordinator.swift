//
//  AppointmentListCoordinator.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class AppointmentListCoordinator: BaseCoordinator<Void> {
    
    private let rootViewController: UIViewController
    
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    override func start() -> Observable<Void> {
        
        let viewModel = AppointmentListViewModel()
        let viewController = AppointmentListViewController(viewModel: viewModel)
        
        self.rootViewController.present(viewController, animated: true, completion: nil)
        
        viewModel.displayContact?.subscribe(onNext: { contactViewController in
            
            let navigationController = UINavigationController(rootViewController: contactViewController)
            let backButton = UIBarButtonItem(title: StringConstants.Navigation.closeButton,
                                             style: UIBarButtonItemStyle.plain, target: self, action: nil)
            
            contactViewController.navigationItem.leftBarButtonItem = backButton
            
            viewController.present(navigationController, animated: true, completion: nil)
            
            backButton.rx.tap.subscribe(onNext: {
                viewController.dismiss(animated: true, completion: nil)
            }).disposed(by: self.disposeBag)
            
        }, onError: { error in print(error) }).disposed(by: self.disposeBag)
        
        return Observable.never()
        
    }
    
}
