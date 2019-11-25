//
//  CMSPageSubBannerCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageSubBannerCellBuilder {
    static func buiderCellModel(_ com:CMSPageComsModel) ->  [MMCellModel]{
        var list = [] as [MMCellModel]
        
        if com.title.count > 0 {
            let cellModel = CMSPageTitleCellModel()
            cellModel.isExclusiveLine = true
            cellModel.title = com.title
            cellModel.cellHeight = 38
            cellModel.modelGroup = com.comType.rawValue
            list.append(cellModel)
        }
        
        let row = com.data!.count / com.colCount
        
        for index in 0..<row {
            let cellModel = CMSPageSubBannerCellModel()
            cellModel.title = com.comType.rawValue
            cellModel.isExclusiveLine = true
            cellModel.modelGroup = com.comType.rawValue
            if com.h <= 0 {
                cellModel.cellHeight = 220
            }else{
                 cellModel.cellHeight = ScreenWidth/2
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
            cellModel.cellHeight = CGFloat(com.bottom)
            cellModel.modelGroup = com.comType.rawValue
            list.append(cellModel)
        }
        return list
    }
}
