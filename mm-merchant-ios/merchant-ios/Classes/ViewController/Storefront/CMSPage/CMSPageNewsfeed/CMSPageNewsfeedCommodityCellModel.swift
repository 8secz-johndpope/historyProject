//
//  CMSPageNewsfeedCommodityCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedCommodityCellModel: CMSCellModel {
    
    override init() {
        super.init()
        cellHeight = 250
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageNewsfeedCommodityCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    weak var delegate:SearchProductViewDelegage?
    public var data:CMSPageDataModel? {
        didSet {
            if let cellModel = data {
                //计算图高宽,可能来自imageKey
                var whratio: Float = 1.0
                let cellWidth = ScreenWidth/2.0 - 19.0
                var imageHeight = cellWidth
                if let imageUrl = cellModel.imageUrl,let r = imageUrl.whratio() {
                    whratio = r
                } else if let style = cellModel.style, let r = style.imageDefault.whratio() {
                    whratio = r
                }
                if cellModel.h > 0 && cellModel.w > 0 {
                    whratio = Float(cellModel.h/cellModel.w)
                }
                if whratio > 2.0 {
                    whratio = 2.0
                }
                imageHeight = imageHeight * CGFloat(whratio)
                
                var cellHeight = imageHeight
                var titleHeight:CGFloat = 0.0
                var contentHeight:CGFloat = 0.0
                var tageHeight:CGFloat = 12.0
                if let style = cellModel.style {
                    if !style.isCrossBorder && style.couponCount == 0 && style.shippingFee != 0 {
                        tageHeight = 0
                    }
                    
                    titleHeight = 20

                    var contentTagWidth: CGFloat = 0
                    if style.badgeId == 1 || style.badgeId == 2 || style.badgeId == 4 {
                        contentTagWidth = 22
                    } else if style.badgeId == 3 {
                        contentTagWidth = 40 // 明显同款图片的富文本宽度
                    }
                    contentHeight = style.skuName.getTextWidth(height: 15, font: UIFont.systemFont(ofSize: 12)) + contentTagWidth + 5 > (cellWidth - 20.0) ? 30 : 15

                    if style.brandId != 0 {
                        contentHeight += MMMargin.CMS.imageToTitle
                    }
                }
                
                cellHeight = imageHeight + MMMargin.CMS.defultMargin + titleHeight + MMMargin.CMS.contentToPrice + contentHeight + 15 + MMMargin.CMS.contentToPrice + tageHeight + MMMargin.CMS.defultMargin
                
                self.cellHeight = cellHeight
            }
        }
    }
}
