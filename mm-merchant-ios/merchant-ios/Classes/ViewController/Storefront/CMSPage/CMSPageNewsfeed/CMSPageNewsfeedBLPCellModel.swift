//
//  CMSPageNewsfeedBLPCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedBLPCellModel: CMSCellModel {
    
    override init() {
        super.init()
        cellHeight = 200
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageNewsfeedBLPCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:CMSPageDataModel?{
        didSet{
            if let cellModel = data{
                
                var imageHeight = ScreenWidth/2 - 22.5 + MMMargin.CMS.defultMargin
                if cellModel.h > 0 && cellModel.w > 0 {
                    imageHeight = imageHeight * CGFloat(cellModel.h/cellModel.w)
                }
                var cellHeight = imageHeight
                var tageHeight:CGFloat = 12.0
                var titleHeight:CGFloat = 4.0
                var contentHeight:CGFloat = 0.0
                
                if let brand = cellModel.brand{
                    if  brand.couponCount == 0 {
                        tageHeight = 0.0 - MMMargin.CMS.priceToTag
                    }
                    if brand.newStyleCount > 0 || brand.newSaleCount > 0{
                        contentHeight = 12.0
                    }
                }
                
                if cellModel.content.length > 0{
                    titleHeight = CGFloat(cellModel.content.stringHeightWithMaxWidth((ScreenWidth/2 - 22.5 - 20), font: UIFont.systemFont(ofSize: 14)))
                }
                
                cellHeight = MMMargin.CMS.defultMargin + tageHeight + MMMargin.CMS.priceToTag + contentHeight + MMMargin.CMS.titleToContent + titleHeight + MMMargin.CMS.imageToTitle + imageHeight
                self.cellHeight = cellHeight.densityRounded()
            }
        }
    }
}
