//
//  AddressFooterView.swift
//  merchant-ios
//
//  Created by hungvo on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class AddressFooterView : UICollectionReusableView{

    var titleLabel = UILabel()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        titleLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        titleLabel.textAlignment = .center
        titleLabel.formatSize(13)
        titleLabel.textColor = UIColor.secondary3()
        addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
