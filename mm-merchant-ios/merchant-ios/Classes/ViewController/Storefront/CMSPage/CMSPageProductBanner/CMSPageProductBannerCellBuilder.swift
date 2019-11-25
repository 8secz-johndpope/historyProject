//
//  CMSPageProductBannerCellBuilder.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageProductBannerCellBuilder {
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
                    if com.orientation == .horizontal && index > 1 {
                        cellModel.tipSelect = "1"
                        cellModel.tipCount = "/" + "\(index)"
                    }
                }
                list.append(cellModel)
            }
            
            var dataList = [CMSPageDataModel]()
            for dateModel:CMSPageDataModel in data {
                if dateModel.dType == DataType.BANNER{
                    dataList.append(dateModel)
                }
            }
            
                com.border = 1
            if com.orientation == .vertical || dataList.count == 1{
                    
                    var _datas = [[CMSPageDataModel]]()
                    var index = 0
                    for dateModel:CMSPageDataModel in data {
                        if dateModel.dType == DataType.BANNER{
                            var list = [CMSPageDataModel]()
                            list.append(dateModel)
                            _datas.append(list)
                            index = index + 1
                        }else if dateModel.dType == DataType.SKU{
                            if index <= _datas.count && index >= 1{
                                _datas[index - 1].append(dateModel)
                            }
                        }
                    }
                    
                    for i in 0..<index {
                        let cellModel = CMSPageProductBannerVerticalCellModel()
                        cellModel.data = _datas[i]
                        cellModel.isExclusiveLine = true
                        cellModel.title = com.title
                        cellModel.padding = com.padding
                        if com.h <= 0 || com.w <= 0 {
                            cellModel.cellHeight = ((ScreenWidth - com.padding * 2) / 16 * 9 + ScreenWidth * 0.48).densityRounded()
                        }else{
                            cellModel.cellHeight = CGFloat((com.h/com.w) * ScreenWidth).densityRounded()
                        }
                        cellModel.modelGroup = com.comGroupId
                        list.append(cellModel)
                        
                        let bottomModel = CMSPageBottomCellModel()
                        bottomModel.isExclusiveLine = true
                        bottomModel.cellHeight = 8.0
                        bottomModel.modelGroup = com.comGroupId
                        list.append(bottomModel)
                    }
                }else if com.orientation == .horizontal && dataList.count > 1{
                    
                    let cellModel = CMSPageProductBannerCellModel()
                    cellModel.data = data
                    cellModel.isExclusiveLine = true
                    cellModel.title = com.title
                    if com.h <= 0 || com.w <= 0 {
                        cellModel.cellHeight =  ScreenWidth
                    }else{
                        cellModel.cellHeight = CGFloat((com.h/com.w) * ScreenWidth).densityRounded()
                    }
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                }
            
            
            if com.orientation == .horizontal{
                if com.bottom > 0 {
                    let cellModel = CMSPageBottomCellModel()
                    cellModel.isExclusiveLine = true
                    cellModel.cellHeight = CGFloat(com.bottom)
                    cellModel.modelGroup = com.comGroupId
                    list.append(cellModel)
                }
            }
        }
      
        return list
    }
}

