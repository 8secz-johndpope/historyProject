//
//  ProductListSearchConditionsCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListSearchConditionsCellModel: NSObject,MMCellModel {


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
        return canFloating
    }
    
    func ssn_isExclusiveLine() -> Bool {
        return isExclusiveLine
    }
    
    func ssn_cellGridSpanSize() -> Int {
        return 1
    }
    
    public static func == (lhs: ProductListSearchConditionsCellModel, rhs: ProductListSearchConditionsCellModel) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return ProductListSearchConditionsCell.self
    }
    
    public var modelGroup: String?
    public var isExclusiveLine: Bool = false
    public var cellHeight:CGFloat = 90.0
    public var supportMagicEdge: Bool = false
    public var canFloating: Bool = false
    public var categories: [Cat]?
    public var filter: StyleFilter?
    public var stylesTotal:Int = 0
    weak var filterStyleDelegate: FilterStyleDelegate!
    public var aggregations: Aggregations?
    var searchTap: (() -> Void)?
    var sortTap: ((CGFloat) -> Void)?
    var categoryShort: ((_ filter: StyleFilter?) -> Void)?
    var sortMenu:String = ""
    var selctCategoryShort:Bool = false
    var belongsToContainer:Bool = false
}
