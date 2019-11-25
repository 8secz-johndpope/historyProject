//
//  NoResultView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 11/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
class NoResultCell : UICollectionViewCell{
    var imageView : UIImageView!
    var label : UILabel!
    var lowerLabel : UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.primary2()
        imageView = UIImageView(frame: CGRect(x: bounds.minX + 10, y: bounds.midY - 15 , width: 30, height: 30))
        imageView.image = UIImage(named: "search_grey")
        addSubview(imageView)
        label = UILabel(frame: CGRect(x: bounds.minX + 60, y: bounds.midY - 32, width: bounds.width - 60, height: 30))
        label.formatSize(15)
        addSubview(label)
        lowerLabel = UILabel(frame: CGRect(x: bounds.minX + 60, y: bounds.midY - 20 , width: bounds.width - 60, height: 60))
        lowerLabel.formatSize(15)
        addSubview(lowerLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}