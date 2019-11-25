//
//  StyleDetailBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailBuilder {
    
    static func buiderPriceAndInfoCellModel(style:Style,delegate:StyleDetailInfoCellDelegage) ->  [MMCellModel] {
        var list = [MMCellModel]()
        
        let priceCellModel = StyleDetailPriceCellModel()
        priceCellModel.isExclusiveLine = true
        priceCellModel.slectSku = style.defaultSku()
        priceCellModel.style = style
        list.append(priceCellModel)
        
        let infoCellModel = StyleDetailInfoCellModel()
        infoCellModel.delegate = delegate
        infoCellModel.isExclusiveLine = true
        infoCellModel.style = style
        list.append(infoCellModel)
        
        let bottomCellModel = CMSPageBottomCellModel()
        bottomCellModel.cellHeight = 8
        bottomCellModel.backgroundColor = UIColor(hexString: "#F5F5F5")
        bottomCellModel.isExclusiveLine = true
        list.append(bottomCellModel)
        return list
    }
    
    static func buiderImagesCellModel(videoUrl:String?,imageData:[Img]) ->  [MMCellModel] {
        var list = [MMCellModel]()
        let cellModel = StyleDetailSwiperCellModel()
        cellModel.isExclusiveLine = true
        
        var dataModelList = [CMSPageDataModel]()
        if let url = videoUrl,url.length > 0 {
            let dataModel =  CMSPageDataModel()
            dataModel.videoUrl = url
            dataModelList.append(dataModel)
        }
        for image in imageData {
           let dataModel =  CMSPageDataModel()
            dataModel.imageUrl = image.imageKey
            dataModel.dType = .SKU
            dataModel.formPDP = true
            dataModelList.append(dataModel)
        }
        cellModel.data = dataModelList
        cellModel.cellHeight = ScreenWidth * CGFloat(7.0 / 6.0)
        list.append(cellModel)
        return list
    }

    static func buiderIntroduceCellModel(skuDesc:String,imageData:[Img]) ->  [MMCellModel] {
        var syteList = [MMCellModel]()
        
        if skuDesc.length > 0 {
            let descCellModel = StyleDetailIntroductLabelCellModel()
            descCellModel.isExclusiveLine = true
            descCellModel.skuDesc = skuDesc
            syteList.append(descCellModel)
            
            let bottomCellModel = CMSPageBottomCellModel()
            bottomCellModel.cellHeight = 2
            bottomCellModel.backgroundColor = UIColor(hexString: "#F5F5F5")
            bottomCellModel.isExclusiveLine = true
            syteList.append(bottomCellModel)
        }

        if imageData.count > 0 {
            for imageData in imageData {
                let cellModel = StyleDetailIntroductImageCellModel()
                cellModel.isExclusiveLine = true
                cellModel.imageData = imageData
                syteList.append(cellModel)
            }
        }
        return syteList
    }
    static func buiderStyleCellModel(_ styleData:[Style],isFirst:Bool) ->  [MMCellModel] {
        var syteList = [MMCellModel]()
        
        if isFirst {
            let titleCellModel = StyleDetailTitleCellModel()
            titleCellModel.title = String.localize("LB_CA_PDP_RECOMMEND_TAB_TITLE")
            titleCellModel.cellHeight = 60
            titleCellModel.isExclusiveLine = true
            syteList.append(titleCellModel)
        }
        
        if styleData.count > 0 {
            for style in styleData {
                let cellModel = CMSPageNewsfeedCommodityCellModel()
                
                let dataModel = CMSPageDataModel()
                dataModel.vid = style.vid //埋点需要
                dataModel.dType = .SKU
                dataModel.style = style
                cellModel.supportMagicEdge = 15
                cellModel.data = dataModel
                syteList.append(cellModel)
            }
        }
        return syteList
    }
   

}
