//
//  TitleSectionController.swift
//  SmartNetworking
//
//  Created by David Moeller on 13.11.17.
//  Copyright © 2017 David Moeller. All rights reserved.
//

import Foundation
import IGListKit

class TitleSectionController: ListSectionController {
    
    var title: String = ""
    
    override init() {
        super.init()
        inset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
    }
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 55)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        
        guard let cell = collectionContext?.dequeueReusableCell(
            of: TitleCell.self, for: self, at: index
            ) as? TitleCell else { return UICollectionViewCell() }
        
        cell.titleLabel.text = title
        
        return cell
    }
    
    override func didUpdate(to object: Any) {
        
        if let label = object as? String {
            title = label
        }
        
    }
    
    override func didSelectItem(at index: Int) {}
    
}
