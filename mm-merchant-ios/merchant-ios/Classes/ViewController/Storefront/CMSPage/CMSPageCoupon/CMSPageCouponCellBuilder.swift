//
//  CMSPageCouponCellBuilder.swift
//  storefront-ios
//
//  Created by Kam on 12/6/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageCouponCellBuilder {
    static func buiderCellModel(_ com: CMSPageComsModel, delegate: MerchantCouponDelegate?,is first:Bool) ->  [MMCellModel] {
        var list = [MMCellModel]()
        
        if com.data == nil || com.data!.isEmpty {
            return list
        }
        
        if let data = com.data,data.count > 0,com.title.count > 0,first {
            let cellModel = CMSPageTitleCellModel()
            cellModel.isExclusiveLine = true
            cellModel.title = com.title
            cellModel.modelGroup = com.comGroupId
            cellModel.comId = com.comId
            cellModel.comIdx = com.comIdx
            list.append(cellModel)
        }
        
        if let data = com.data,data.count > 0 {
            let cellModel = CMSPageCouponCellModel()
            cellModel.isExclusiveLine = true
            cellModel.delegate = delegate
            cellModel.data = com.data
            cellModel.modelGroup = com.comGroupId
            if com.h <= 0 || com.w <= 0 {
                cellModel.cellHeight = MerchantCouponCell.CmsViewHeight
            } else{
                cellModel.cellHeight = CGFloat((com.h/com.w) * ScreenWidth).densityRounded()
            }
            list.append(cellModel)
        }
        
        if com.bottom > 0 && first {
            let cellModel = CMSPageBottomCellModel()
            cellModel.isExclusiveLine = true
            cellModel.cellHeight = CGFloat(com.bottom)
            cellModel.modelGroup = com.comGroupId
            cellModel.comId = com.comId
            cellModel.comIdx = com.comIdx
            list.append(cellModel)
        }
        return list
    }
}

