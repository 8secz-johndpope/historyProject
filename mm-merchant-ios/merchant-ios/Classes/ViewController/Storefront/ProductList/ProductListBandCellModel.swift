//
//  ProductListBandCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/23.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListBandCellModel: NSObject,MMCellModel {
  
    func ssn_groupID() -> String? {
        return modelGroup
    }
    
    var rid:String {
        get { return self.track_visitPathId }
        set { self.track_visitPathId = newValue }
    }
    
    func ssn_cellID() -> String {
        return String(describing: type(of: self))
    }
    
    func ssn_canEdit() -> Bool {
        return false
    }
    
    func ssn_canMove() -> Bool {
        return false
    }
    
    func ssn_cellHeight() -> CGFloat {
        return cellHeight
    }
    
    func ssn_cellInsets() -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func ssn_canFloating() -> Bool {
        return false
    }
    
    func ssn_isExclusiveLine() -> Bool {
        return isExclusiveLine
    }
    
    func ssn_cellGridSpanSize() -> Int {
        return 1
    }
    
    public static func == (lhs: ProductListBandCellModel, rhs: ProductListBandCellModel) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return ProductListBandCell.self
    }
    
    public var modelGroup: String?
    
    public var isExclusiveLine: Bool = true
    public var cellHeight:CGFloat = 90.0
    public var contentView, superView: UIView?
    public var isVideo: Bool = false
}
