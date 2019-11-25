//
//  CMSPageNewsfeedPostCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageNewsfeedPostCellModel: CMSCellModel {
    
    override init() {
        super.init()
        cellHeight = 300
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageNewsfeedPostCell.self
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
                var height = CGFloat(cellModel.content.stringHeightWithMaxWidth((ScreenWidth/2 - 22.5 - 20), font: UIFont.systemFont(ofSize: 12)))
                
                if height >= 52{
                    height = 52
                }else {
                    height = height + 4
                }
                if cellModel.content.containsEmoji(){
                    height = height + 4
                }
                if cellModel.content.length == 0 {
                    height = 0
                }
                cellHeight = MMMargin.CMS.defultMargin + 20 + MMMargin.CMS.priceToTag + height + MMMargin.CMS.imageToTitle + imageHeight
                self.cellHeight = cellHeight.densityRounded()
            }
        }
    }
}
