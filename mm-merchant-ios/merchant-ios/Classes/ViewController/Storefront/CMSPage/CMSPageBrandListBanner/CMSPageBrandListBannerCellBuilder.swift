//
//  CMSPageBrandListBannerCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageBrandListBannerCellBuilder {
    static func buiderCellModel(_ com:CMSPageComsModel) ->  [MMCellModel]{
        var list = [MMCellModel]()
        
        if let data = com.data,data.count > 0 {
            if com.title.count > 0 {
                let cellModel = CMSPageTitleCellModel()
                cellModel.isExclusiveLine = true
                cellModel.title = com.title
                cellModel.modelGroup = com.comGroupId
                list.append(cellModel)
            }
            
            
            if com.colCount == 0{
                com.colCount = 1
            }
            let row = data.count / com.colCount
            
            for index in 0..<row {
                let cellModel = CMSPageBrandListBannerCellModel()
                cellModel.title = com.comType.rawValue
                cellModel.isExclusiveLine = true
                cellModel.border = CGFloat(com.border)
                cellModel.modelGroup = com.comGroupId
                if com.h <= 0 || com.w <= 0 {
                    cellModel.cellHeight = CGFloat(ScreenWidth / 3).densityRounded()
                }else{
                    cellModel.cellHeight = CGFloat(ScreenWidth * (com.h/com.w)).densityRounded()
                }
                if let data = com.data{
                    var start = 0
                    var end = com.colCount
                    if index != 0{
                        start = index * com.colCount
                        end = (index + 1) * com.colCount
                    }
                    if start < end && end <= com.data!.count{
                        cellModel.data =  Array(data[start..<end])
                    }
                }
                list.append(cellModel)
            }
            
            if com.bottom > 0 {
                let cellModel = CMSPageBottomCellModel()
                cellModel.isExclusiveLine = true
                cellModel.cellHeight = CGFloat(com.bottom - com.border)
                cellModel.modelGroup = com.comGroupId
                list.append(cellModel)
            }
        }
        
        return list
    }
}
