//
//  CatCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 17/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class CatCell : UICollectionViewCell {
    var collectionView : UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layout: DoubleSnapFlowLayout = DoubleSnapFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 50, height: bounds.height)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView!.backgroundColor = UIColor.white
        collectionView!.frame = bounds
        collectionView.showsHorizontalScrollIndicator = false
        addSubview(collectionView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
