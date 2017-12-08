//
//  AppointmentListViewController.swift
//  SmartNetworkung
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import IGListKit
import Stevia

class AppointmentListViewController: UIViewController {

    let disposeBag = DisposeBag()
    let viewModel: AppointmentListViewModel
    
    let collectionView: UICollectionView = {
        
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        
        let topInset: CGFloat = 0
        let bottomInset: CGFloat = 0
        
        view.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        view.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        view.alwaysBounceVertical = true
        
        view.backgroundColor = .white
        
        return view
    }()
    
    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        
        control.tintColor = .gray
        control.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        
        return control
    }()
    
    init(viewModel: AppointmentListViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.displayDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        print("Did Load Visit ViewController")
        
        // Background
        self.view.backgroundColor = .white
        
        self.view.sv(
            self.collectionView
        )
        
        setupLayout()
        
        setupCollectionView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Did Appear Visit ViewController")
        
        if viewModel.appointments.isEmpty {
            self.viewModel.checkStatus()
        }

    }
    
    func setupLayout() {
        
        self.view.layout(
            |-self.collectionView-|
        )
        
        self.collectionView.Top == topLayoutGuide.Bottom
        self.collectionView.Bottom == bottomLayoutGuide.Top
    }
    
    @objc func refresh() {
        self.viewModel.checkStatus()
    }
    
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    func setupCollectionView() {
        
        collectionView.refreshControl = self.refreshControl
        
        adapter.collectionView = collectionView
        adapter.dataSource = viewModel
        
        self.viewModel.contentUpdated.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            self.refreshControl.endRefreshing()
            print("Adapter update Content.")
            self.adapter.reloadData(completion: nil)
        }).disposed(by: self.disposeBag)
        
    }
    
}

extension AppointmentListViewController: ListDisplayDelegate {
    
    func listAdapter(_ listAdapter: ListAdapter, willDisplay sectionController: ListSectionController,
                     cell: UICollectionViewCell, at index: Int) {
        return
    }
    
    func listAdapter(_ listAdapter: ListAdapter, didEndDisplaying sectionController: ListSectionController,
                     cell: UICollectionViewCell, at index: Int) {
        return
    }
    
    func listAdapter(_ listAdapter: ListAdapter, willDisplay sectionController: ListSectionController) {
        if sectionController is TitleSectionController {
            self.navigationItem.title = nil
        }
        return
    }
    
    func listAdapter(_ listAdapter: ListAdapter, didEndDisplaying sectionController: ListSectionController) {
        if let sectionController = sectionController as? TitleSectionController {
            self.navigationItem.title = sectionController.title
        }
        return
    }
    
}
