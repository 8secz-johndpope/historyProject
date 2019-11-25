//
//  SyteProductListBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SyteProductListBuilder {
    static func buiderUserCellModel(_ brandList:[Brand]) ->  [MMCellModel] {
        var list = [MMCellModel]()
        let cellModel = SyteBrandCellModel()
        cellModel.brandList = brandList
        list.append(cellModel)
        
        return list
    }
    
    static func buiderStyleCellModel(_ syte:Syte, brandList:inout [Brand]) ->  [MMCellModel] {
        var syteList = [MMCellModel]()
        
        if let pageData = syte.pageData,pageData.count > 0 {
            let cellModel = CMSPageBottomCellModel()
            cellModel.isExclusiveLine = true
            cellModel.cellHeight = 10
            syteList.append(cellModel)
            
            for style in pageData {
                let cellModel = CMSPageNewsfeedCommodityCellModel()
                
                let dataModel = CMSPageDataModel()
                dataModel.vid = style.vid //埋点需要
                dataModel.dType = .SKU
                dataModel.style = style
                cellModel.supportMagicEdge = 15
                cellModel.data = dataModel
                syteList.append(cellModel)
                
                
                let brand = Brand()
                brand.brandId = style.brandId
                if !brandList.contains(brand) {//去重
                    brand.brandName = style.brandName
                    brand.smallLogoImage = style.brandSmallLogoImage
                    SingnRecommendService.genRelatedBrandVid(brand:brand,index:brandList.count)
                    brandList.append(brand)
                }
            }
        }
        return syteList
    }
}
