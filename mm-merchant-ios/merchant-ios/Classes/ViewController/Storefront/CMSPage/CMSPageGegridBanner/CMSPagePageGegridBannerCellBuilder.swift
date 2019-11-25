//
//  CMSPagePageGegridBannerCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPagePageGegridBannerCellBuilder {
    static func buiderCellModel(_ com:CMSPageComsModel) ->  [MMCellModel]{
        var list = [] as [MMCellModel]
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
                let cellModel = CMSPagePageGegridBannerCellModel()
                cellModel.title = com.comType.rawValue
                cellModel.isExclusiveLine = true
                cellModel.border = CGFloat(com.border)
                cellModel.modelGroup = com.comGroupId
                cellModel.supportMagicEdge = com.padding
                if com.h <= 0 || com.w <= 0 {
                    let indexStart = index * com.colCount
                    let dataModel = data[indexStart]
                    
                    if dataModel.w > 0 && dataModel.h > 0 {
                        let margin = CGFloat(dataModel.h) / CGFloat(dataModel.w)
                        cellModel.cellHeight =   CGFloat(ScreenWidth / CGFloat(com.colCount) * margin).densityRounded()
                        if com.comCMSPath == .subBanner || com.comCMSPath == .gridBanner{
                            
                            cellModel.cellHeight =   CGFloat((ScreenWidth - com.padding * 2) / CGFloat(com.colCount) * margin).densityRounded()
                        }
                    }else{
                        if com.comCMSPath == .shortcutBanner {
                            cellModel.cellHeight = CGFloat(ScreenWidth * 0.1386).densityRounded()
                        }else if com.comCMSPath == .subBanner || com.comCMSPath == .gridBanner{
                            cellModel.cellHeight = CGFloat(ScreenWidth * 0.2853).densityRounded()
                        }
                    }
                }else{
                    cellModel.cellHeight = CGFloat(ScreenWidth * (com.h/com.w)).densityRounded()
                }
                
                var start = 0
                var end = com.colCount
                if index != 0{
                    start = index * com.colCount
                    end = (index + 1) * com.colCount
                }
                if start < end && end <= com.data!.count{
                    cellModel.data =  Array(data[start..<end])
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
