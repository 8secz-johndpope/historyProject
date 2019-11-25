//
//  CMSPageDailyRecommendBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageDailyRecommendBuilder: NSObject {
    static func buiderCellModel(_ com:CMSPageComsModel,is first:Bool) ->  [MMCellModel] {
        var list = [MMCellModel]()
        
        if com.data == nil || com.data!.isEmpty {
            return list
        }
        
        if let recommends = com.recommends,recommends.count > 0 {
            let cellModel = CMSPageDailyRecommendCellModel()
            cellModel.recommends = recommends
            cellModel.recommendLinks = com.recommendLinks
            cellModel.isExclusiveLine = true
            cellModel.modelGroup = com.comGroupId
            cellModel.cellHeight = 48 + ScreenWidth * 1.08 + 60
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
