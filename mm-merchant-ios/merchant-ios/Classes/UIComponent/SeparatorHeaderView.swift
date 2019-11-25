//
//  SeparatorHeaderView.swift
//  merchant-ios
//
//  Created by hungvo on 1/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SeparatorHeaderView: UICollectionReusableView {
    
    static let ViewIdentifier = "SeparatorHeaderViewID"
    static let padding = CGFloat(18)
    
    let separatorView = UIView()
    var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let separatorHeight = CGFloat(1)
        let padding = SeparatorHeaderView.padding
        
        separatorView.frame = CGRect(x: padding, y: frame.height - separatorHeight, width: frame.width - (2 * padding), height: separatorHeight)
        separatorView.backgroundColor = UIColor.secondary1()
        addSubview(separatorView)
        
        titleLabel.formatSize(13)
        titleLabel.textAlignment = .left
        titleLabel.isHidden = true
        addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let paddingLeft: CGFloat = 17
        titleLabel.frame = CGRect(x: paddingLeft, y: 0, width: self.bounds.sizeWidth - 2 * paddingLeft, height: self.bounds.sizeHeight * 0.7)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
