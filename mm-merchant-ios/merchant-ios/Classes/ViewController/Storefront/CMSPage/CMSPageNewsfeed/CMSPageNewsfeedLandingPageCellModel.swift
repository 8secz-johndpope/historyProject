//
//  CMSPageNewsfeedLandingPageCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedLandingPageCellModel: CMSCellModel {
    
    override init() {
        super.init()
        cellHeight = 350
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageNewsfeedLandingPageCell.self
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
                var contentHeight:CGFloat = 0.0
                if let page = cellModel.page {
                    contentHeight = CGFloat(page.contentPageName.stringHeightWithMaxWidth((ScreenWidth/2 - 22.5 - 20), font: UIFont.systemFont(ofSize: 12)))
                    if contentHeight > 24 {
                        contentHeight = 24
                    }
                }
                cellHeight = MMMargin.CMS.defultMargin + 17 + MMMargin.CMS.imageToTitle + contentHeight + MMMargin.CMS.imageToTitle + imageHeight + MMMargin.CMS.defultMargin
                self.cellHeight = cellHeight.densityRounded()
            }
        }
    }
}
