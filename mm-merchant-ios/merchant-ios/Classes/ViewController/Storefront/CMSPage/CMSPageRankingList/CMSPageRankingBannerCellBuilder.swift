//
//  CMSPageRankingBannerCellBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/28.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageRankingBannerCellBuilder {
    static func buiderCellModel(_ com:CMSPageComsModel) ->  [MMCellModel]{
        var list = [MMCellModel]()
        if let data = com.data,data.count > 0 {
            if com.title.count > 0 {
                let cellModel = CMSPageTitleCellModel()
                cellModel.isExclusiveLine = true
                cellModel.title = com.title
                cellModel.modelGroup = com.comGroupId
                
                if let data = com.data {
                    var index = 0
                    for dateModel:CMSPageDataModel in data {
                        if dateModel.dType == DataType.BANNER{
                            index = index + 1
                        }
                    }
                    if  index > 1 {
                        cellModel.tipSelect = "1"
                        cellModel.tipCount = "/" + "\(index)"
                    }
                }
                list.append(cellModel)
            }
            
            
            if data.count > 0 {
                let cellModel = CMSPageRankingBannerCellModel()
                //tracking 需要
                cellModel.compId = com.comId
                cellModel.compType = "\(com.comType)"
                cellModel.compName = "\(com.comType)"
                
                cellModel.data = com.data
                cellModel.title = com.title
                cellModel.modelGroup = com.comGroupId
                if com.h <= 0 || com.w <= 0 {
                    cellModel.cellHeight = CGFloat((ScreenWidth - 70) * 1.4 + 38).densityRounded()
                }else{
                    cellModel.cellHeight = CGFloat((com.h/com.w) * (ScreenWidth - 70) * 1.4 + 38).densityRounded()
                }
                list.append(cellModel)
            }
            
            if com.bottom > 0 {
                let cellModel = CMSPageBottomCellModel()
                cellModel.isExclusiveLine = true
                cellModel.cellHeight = CGFloat(com.bottom)
                cellModel.modelGroup = com.comGroupId
                list.append(cellModel)
            }
        }
        return list
    }
}
