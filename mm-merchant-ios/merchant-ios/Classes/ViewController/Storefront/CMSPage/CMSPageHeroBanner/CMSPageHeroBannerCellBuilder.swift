//
//  CMSPageHeroBannerCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageHeroBannerCellBuilder{
    static func buiderCellModel(_ com:CMSPageComsModel) ->  [MMCellModel]{
        var list = [MMCellModel]()
        if let data = com.data,data.count > 0 {
            if com.title.count > 0 {
                let cellModel = CMSPageTitleCellModel()
                cellModel.isExclusiveLine = true
                cellModel.title = com.title
                cellModel.modelGroup = com.comGroupId
                if let count = com.data?.count,count > 0 {
                    cellModel.tipSelect = "1"
                    cellModel.tipCount = "/" + "\(count)"
                }
                list.append(cellModel)
            }
            
            
            if data.count > 0 {
                
                let cellModel = CMSPageHeroBannerCellModel()
                cellModel.data = com.data
                cellModel.title = com.title
                cellModel.modelGroup = com.comGroupId
                if com.h <= 0 || com.w <= 0 {
                    cellModel.cellHeight = CGFloat((ScreenWidth - 120) * (920.0 / 610.0)).densityRounded()
                }else{
                    cellModel.cellHeight = CGFloat((com.h/com.w) * (ScreenWidth - 120) * (920.0 / 610.0)).densityRounded()
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

