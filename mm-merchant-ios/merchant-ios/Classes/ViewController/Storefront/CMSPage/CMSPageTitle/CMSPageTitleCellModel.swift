//
//  CMSPageTitleCellModel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/27.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageTitleCellModel: CMSCellModel {
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return CMSPageTitleCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var data:[CMSPageDataModel]?
    public var comId:String = ""
    public var comIdx:Int = 0 //索引
    public var tipSelect:String = ""
    public var tipCount:String = ""
    public var backgroundColor:UIColor?
    
    override func ssn_cellHeight() -> CGFloat {
        return 38
    }
}
