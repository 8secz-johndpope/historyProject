//
//  BrandProfileHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/21/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class BrandProfileHeaderView : MerchantProfileHeaderView{
    static let BrandProfileHeaderIdentifier = "BrandProfileHeaderIdentifier"
    override init(frame: CGRect) {
        super.init(frame: frame)
        removeBottomView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
