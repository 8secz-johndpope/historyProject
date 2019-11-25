//
//  MMRefreshFooter.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/15.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class MMRefreshFooter: MJRefreshAutoNormalFooter {
    override func prepare() {
        super.prepare()
        
        //无样式refresh
        setTitle("", for: MJRefreshState.refreshing)
        setTitle("", for: MJRefreshState.noMoreData)
        setTitle("", for: MJRefreshState.pulling)
        setTitle("", for: MJRefreshState.idle)
        setTitle("", for: MJRefreshState.willRefresh)
        
        isRefreshingTitleHidden = true
    }
}
