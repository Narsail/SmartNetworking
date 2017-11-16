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
        
        let topInset: CGFloat = 20
        let bottomInset: CGFloat = 80
        
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
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
        
        self.viewModel.checkStatus()
    }
    
    func setupLayout() {
        
        // TODO: Use the Safe Area when available
        
        self.view.layout(
            20,
            |-self.collectionView-|,
            0
        )
        
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
        adapter.dataSource = viewModel.adapterDataSource
        
        self.viewModel.contentUpdated.observeOn(MainScheduler.instance).subscribe(onNext: { _ in
            self.refreshControl.endRefreshing()
            self.adapter.reloadData(completion: nil)
        }).disposed(by: self.disposeBag)
        
    }
    
}
