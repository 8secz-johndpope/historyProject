//
//  ImageCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 17/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class ImageCell : UICollectionViewCell{
    var collectionView : UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView!.backgroundColor = UIColor.white
        collectionView!.frame = bounds
        collectionView.showsVerticalScrollIndicator = false
        addSubview(collectionView!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
