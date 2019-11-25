//
//  MMSegmentCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/29/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//
import Foundation

class MMSegmentCell: UICollectionViewCell{
    var segmentView: MMSegmentView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        segmentView = MMSegmentView(frame: CGRect(x: 0, y: 0, width: width , height: height), tabs: [])
        addSubview(segmentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
