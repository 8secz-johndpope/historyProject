//
//  CMSPageNewsfeedCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit


class CMSPageNewsfeedCellBuilder {
    
    static func buiderCellModel(_ com:CMSPageComsModel,is first:Bool) ->  [MMCellModel]{
        var list = [MMCellModel]()
        if com.data == nil || com.data!.isEmpty {
            return list
        }
        
        if let data = com.data,data.count > 0,com.title.count > 0 && first{
            let cellModel = CMSPageTitleCellModel()
            cellModel.isExclusiveLine = true
            cellModel.title = com.title
            cellModel.comId = com.comId
            cellModel.comIdx = com.comIdx
            cellModel.modelGroup = com.comGroupId
            list.append(cellModel)
        }
        
        if let data = com.data,data.count > 0 {
            for dataModel in data{
                switch dataModel.dType{
                case .SKU:
                    let cellModel = CMSPageNewsfeedCommodityCellModel()
                    cellModel.title = "SKU/\(dataModel.dId)"
                    cellModel.data = dataModel
                    cellModel.supportMagicEdge = 15
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                case .BRAND:
                    let cellModel = CMSPageNewsfeedBLPCellModel()
                    cellModel.title = "BRAND/\(dataModel.dId)"
                    cellModel.data = dataModel
                    cellModel.supportMagicEdge = 15
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                case .MERCHANT:
                    let cellModel = CMSPageNewsfeedMLPCellModel()
                    cellModel.title = "MERCHANT/\(dataModel.dId)"
                    cellModel.data = dataModel
                    cellModel.supportMagicEdge = 15
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                case .PAGE:
                    let cellModel = CMSPageNewsfeedLandingPageCellModel()
                    cellModel.title = "PAGE/\(dataModel.dId)"
                    cellModel.data = dataModel
                    cellModel.supportMagicEdge = 15
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                case .POST:
                    let cellModel = CMSPageNewsfeedPostCellModel()
                    cellModel.title = "POST/\(dataModel.dId)"
                    cellModel.data = dataModel
                    cellModel.supportMagicEdge = 15
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                case .BANNER, .COUPON:
                    break
                case .DEFAULT:
                    break
                }
            }
        }
        
        if  com.bottom > 0 && first {
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
