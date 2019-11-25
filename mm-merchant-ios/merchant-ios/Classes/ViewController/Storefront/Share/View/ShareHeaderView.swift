//
//  ShareHeaderView.swift
//  merchant-ios
//
//  Created by hungvo on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class ShareHeaderView : UICollectionReusableView{

    let separatorView = UIView()
    
    var titleLabel = UILabel()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        let separatorHeight = CGFloat(1)
        
        separatorView.frame = CGRect(x: 0, y: 0, width: frame.width, height: separatorHeight)
        separatorView.backgroundColor = UIColor.secondary1()
        addSubview(separatorView)
        
        titleLabel.frame = CGRect(x: 0, y: separatorHeight, width: frame.width, height: frame.height - separatorHeight)
        titleLabel.textAlignment = .center
        titleLabel.formatSizeBold(15)
        addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
