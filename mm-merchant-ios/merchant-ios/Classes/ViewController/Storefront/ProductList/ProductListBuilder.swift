//
//  ProductListBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListBuilder {
    
    static func buiderSearchtCellModel(categories: [Cat],filter: StyleFilter,stylesTotal:Int,belongsToContainer:Bool,searchTap:@escaping () -> Void,sortTap:@escaping (CGFloat) -> Void,categoryShort: @escaping (_ filter: StyleFilter?) -> Void) ->  MMCellModel{
        
        let cellModel = ProductListSearchConditionsCellModel()
        cellModel.isExclusiveLine = true
        cellModel.categories = categories
        cellModel.filter = filter
        cellModel.stylesTotal = stylesTotal
        cellModel.modelGroup = "search"
        cellModel.canFloating = true
        cellModel.belongsToContainer = belongsToContainer
        cellModel.cellHeight = 50
        cellModel.searchTap = {
           searchTap()
        }
        cellModel.sortTap = { maxY in
           sortTap(maxY)
        }
        cellModel.categoryShort = { filter in
          categoryShort(filter)
        }
        return cellModel
    }

    static func buiderStyleListCellModel(_ feedList:[Any],delegate:SearchProductViewDelegage) ->  [MMCellModel]{
        var list = [MMCellModel]()
        
        for feed in feedList{
            if let cellModel = feed as? CMSPageNewsfeedBLPCellModel{
                list.append(cellModel)
            }else if let style = feed as? Style {
                let cellModel = CMSPageNewsfeedCommodityCellModel()
                cellModel.delegate = delegate
                let dataModel = CMSPageDataModel()
                dataModel.dType = .SKU
                dataModel.style = style
                cellModel.supportMagicEdge = 15
                cellModel.data = dataModel
                list.append(cellModel)
            }
            
    
        }
        
        return list
    }
    
    static func buiderHeadCellModel(_ contentView:UIView?,isVideo:Bool) ->  MMCellModel{
        let cellModel = ProductListBandCellModel()
        cellModel.isVideo = isVideo
        if let view = contentView {
            cellModel.contentView = view
            cellModel.cellHeight = view.frame.size.height
        }

        return cellModel
    }
    
    static func builderBottomMarginCell(_ height: CGFloat) -> MMCellModel {
        let cellModel = CMSPageBottomCellModel()
        cellModel.isExclusiveLine = true
        cellModel.cellHeight = height
        return cellModel
    }
}
