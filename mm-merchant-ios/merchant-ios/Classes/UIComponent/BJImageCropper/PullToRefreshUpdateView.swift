//
//  PullToRefreshView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

protocol PullToRefreshViewUpdateDelegate: NSObjectProtocol { //Prevent memory leak
    func didEndPullToRefresh()
}

class PullToRefreshUpdateView : UIView{
    
    var pullToRefreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    weak var scrollView: MMCollectionView?
    
    var isPullingToRefresh = false
    
    weak var delegate: PullToRefreshViewUpdateDelegate? //Prevent memory leak
    
    init(frame: CGRect, scrollView: MMCollectionView) {
        super.init(frame: frame)
        self.isHidden = true
        self.clipsToBounds = true
        
        scrollView.scrollViewDidScroll = { [weak self] in
            if let strongSelf = self {
                strongSelf.scrollViewDidScroll()
            }
        }
        self.scrollView = scrollView
        
        
        var frame = pullToRefreshIndicator.frame
        frame.origin.y = -frame.height
        pullToRefreshIndicator.frame = frame
        pullToRefreshIndicator.startAnimating()
        addSubview(pullToRefreshIndicator)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll() {
        
        guard let scrollView = self.scrollView else {
            return
        }
        
        if !isPullingToRefresh {
            if scrollView.contentOffset.y < 0 {
                self.isHidden = false
                var frame = self.pullToRefreshIndicator.frame
                frame.origin.y = -(self.pullToRefreshIndicator.frame.height + scrollView.contentOffset.y)
                if frame.origin.y > 0 {
                    frame.origin.y = 0
                }
                self.pullToRefreshIndicator.frame = frame
            } else {
                self.hidePullToRefreshView()
            }
        }
    }
    
    func scrollViewDidEndDragging() {
        if self.pullToRefreshIndicator.frame.origin.y >= 0 {
            isPullingToRefresh = true
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.pullToRefresh), userInfo: nil, repeats: false)
        } else {
            self.hidePullToRefreshView()
        }
    }
    
    func hidePullToRefreshView() {
        if isPullingToRefresh {
            return
        }
        if self.pullToRefreshIndicator.frame.origin.y > -self.pullToRefreshIndicator.frame.height {
            var frame = pullToRefreshIndicator.frame
            frame.origin.y = -frame.height
            UIView.animate(
                withDuration: 0.2,
                animations: { () -> Void in
                    self.pullToRefreshIndicator.frame = frame
                },
                completion: { (success) in
                    self.isHidden = true
                }
            )
        }
    }
    
    @objc func pullToRefresh(){
        self.delegate?.didEndPullToRefresh()
        
        isPullingToRefresh = false
        self.hidePullToRefreshView()
    }
    
    deinit {
        scrollView?.scrollViewDidScroll = nil
    }
}
