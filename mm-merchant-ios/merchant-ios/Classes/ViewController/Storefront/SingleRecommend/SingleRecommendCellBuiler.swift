//
//  SingleRecommendCellBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SingleRecommendCellBuilder: NSObject {
    static func buiderCellModel(showCancel:Bool,cancelTap:@escaping () -> Void) ->  [MMCellModel] {
        var list = [MMCellModel]()
        
        let cellModel = SingleRecommendCellModel()
        cellModel.showCancel = showCancel
        cellModel.isExclusiveLine = true
        cellModel.cellHeight = ScreenWidth * 0.43 + ScreenTop
        cellModel.cancelTap = {
            cancelTap()
        }
        list.append(cellModel)
        
        return list
    }
}
