//
//  MMRefresh.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/4/17.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class MMRefreshHeader: MJRefreshHeader {
    lazy var view:MMRefreshAnimator = {
        let view = MMRefreshAnimator()
        return view
    }()
    override func prepare() {
        super.prepare()
        self.mj_h = 75
        self.addSubview(view)
    }
    override func placeSubviews() {
        super.placeSubviews()
        
        view.frame = self.bounds
        
        switch state {
        case MJRefreshState.idle:
            view.stopAnimateImageView()
            break
        case MJRefreshState.pulling:
            view.animateImageView()
            break
        case MJRefreshState.refreshing:
             view.animateImageView()
            break
        case MJRefreshState.willRefresh:
            view.animateImageView()
            break
        default:
            break
        }
    }
    
    override func scrollViewContentOffsetDidChange(_ change: [AnyHashable : Any]!) {
        super.scrollViewContentOffsetDidChange(change)
        
        let offsetY = self.scrollView.mj_offsetY

        let happenOffsetY = -self.scrollViewOriginalInset.top
        
        let pullingPercent = (happenOffsetY - offsetY) / self.mj_h
        
        changeImageView(progress: pullingPercent)
    }
    
    func changeImageView(progress: CGFloat)  {
        var index = 0
        if progress > 0.75 {
            let progress = ((progress > 1 ? 1 : progress) - 0.75)
            let springFrame = CGFloat(view.maxSpringFrame - view.startSpringFrame)
            index = Int(progress * 4 * springFrame)
        }
        
        index = index < 1 ? 0 : index
        view.imageView.image = view.images[index]
    }
    
    override func scrollViewContentSizeDidChange(_ change: [AnyHashable : Any]!) {
        super.scrollViewContentSizeDidChange(change)
    }
    
    override func scrollViewPanStateDidChange(_ change: [AnyHashable : Any]!) {
        super.scrollViewPanStateDidChange(change)
    }
    
    func setState(state:MJRefreshState) {

        
        switch state {
        case MJRefreshState.idle:
            view.stopAnimateImageView()
            break
        case MJRefreshState.pulling:
            view.animateImageView()
            break
        case MJRefreshState.refreshing:
            view.animateImageView()
            break
        default:
            break
        }
    }
}
