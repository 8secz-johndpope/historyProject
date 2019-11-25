//
//  MMCollectionView.swift
//  merchant-ios
//
//  Created by Alan YU on 16/3/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MMCollectionView: UICollectionView {
    
    private static var KVOContext = "MMCollectionViewContext"
    private let ContentOffset = "contentOffset"
    
    private var didAddObserver = false
    var scrollViewDidScroll: (() -> Void)? {
        didSet {
            if !didAddObserver {
                didAddObserver = true
                addObserver(
                    self,
                    forKeyPath: ContentOffset,
                    options: .initial,
                    context: &MMCollectionView.KVOContext
                )
            }
        }
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &MMCollectionView.KVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if (keyPath == ContentOffset && object as? MMCollectionView == self) {
            scrollViewDidScroll?()
        }
    }
    
    deinit {
        if didAddObserver {
            removeObserver(self, forKeyPath: ContentOffset)
        }
    }
    
}
