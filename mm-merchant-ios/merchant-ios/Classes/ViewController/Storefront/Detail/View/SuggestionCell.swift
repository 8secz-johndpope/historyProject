//
//  SuggestionCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 3/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class SuggestionCell : UICollectionViewCell {
    var borderView = UIView()
    var suggestCollectionView : UICollectionView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        let layout: DoubleSnapFlowLayout = DoubleSnapFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        suggestCollectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        suggestCollectionView!.backgroundColor = UIColor.white
        suggestCollectionView.showsHorizontalScrollIndicator = false
        addSubview(suggestCollectionView!)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
         borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
