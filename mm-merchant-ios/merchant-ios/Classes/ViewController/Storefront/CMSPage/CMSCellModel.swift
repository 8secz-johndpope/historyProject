//
//  CMSCellModel.swift
//  storefront-ios
//
//  Created by MJ Ling on 2018/4/8.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

class CMSCellModel: NSObject,MMCellModel {
    
    func ssn_groupID() -> String? {
        return modelGroup
    }
    
    
    // visit id = pageId.compId.compIdx.dataType.dataId.dataIndex
    /*
    var vid:String {
        get { return self.track_visitId }
        set { self.track_visitId = newValue }
    }
     */
    
    // 相对值 visit id = compId.compIdx.dataType.dataId.dataIndex
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
    
    public static func == (lhs: CMSCellModel, rhs: CMSCellModel) -> Bool {
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
