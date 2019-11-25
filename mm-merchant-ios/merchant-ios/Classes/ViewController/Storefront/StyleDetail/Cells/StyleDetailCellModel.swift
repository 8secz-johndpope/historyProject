//
//  StyleDetailCellModel.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class StyleDetailCellModel: NSObject,MMCellModel {
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
    
    public static func == (lhs: StyleDetailCellModel, rhs: StyleDetailCellModel) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    public var modelGroup: String?
    
    public var isExclusiveLine: Bool = false
    public var cellHeight:CGFloat = 44.0
    
    public var supportMagicEdge: CGFloat = 0.0
    public var canFloating: Bool = false
    
    // tracking 需要
    public var compId:String = ""
    public var compType:String = ""
    public var compName:String = ""
}
