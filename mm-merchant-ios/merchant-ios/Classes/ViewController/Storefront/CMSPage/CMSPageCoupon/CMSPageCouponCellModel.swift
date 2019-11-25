//
//  CMSPageCouponCellModel.swift
//  storefront-ios
//
//  Created by Kam on 12/6/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageCouponCellModel: CMSCellModel {
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageCouponCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
    public var delegate: MerchantCouponDelegate?
    public var comId = ""
    public var comIdx:Int = 0 //索引
}
