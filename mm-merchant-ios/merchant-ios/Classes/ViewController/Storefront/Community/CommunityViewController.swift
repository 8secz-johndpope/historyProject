//
//  CommunityViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/27.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class CommunityViewController: MMUICollectionController<MMCellModel> {
    private var pageNo = 1
    private let GET_COMP_DATAS_SIZE = 10
    
    //MARK: - life
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
    }
    override func onViewWillDisappear(_ animated: Bool) {
        super.onViewWillDisappear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
    }
    override func onViewDidLoad() {
        super.onViewDidLoad()
        table.backgroundColor = .white
        
        if #available(iOS 11.0, *) {
            table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        let head = MMRefreshHeader(refreshingTarget: self, refreshingAction: #selector(headerRefresh))
        
        let footer = MJRefreshAutoFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))
        
        table.mj_header = head
        table.mj_footer = footer
        
        singnRecommendData()
    }
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    //MARK: - header & footer refresh
    @objc private func headerRefresh() {
        self.fetchs.fetch.clear()
        pageNo = 1
        singnRecommendData()
    }
    
    @objc private func footerRefursh()  {
        singnRecommendData()
    }
    
    //MARK: - service
    private func singnRecommendData() {
        let myUserKey = LoginManager.getLoginState() == .validUser ? Context.getUserKey() : "0"
        var followingUserKeys = Array(FollowService.instance.followingNormalUserKeys.prefix(Constants.NewsFeed.UserKeyLimit))
        if myUserKey != "0" { followingUserKeys.append(myUserKey) }
        CommunityService.getCommunityData(myUserKey, pageno: pageNo,followingUserKeys:followingUserKeys, success: { (response) in
            
            if self.pageNo == 1 {
                self.fetchs.fetch.append(CommunityBuilder.buiderUserCellModel())
                self.fetchs.fetch.append(CommunityBuilder.buiderTagCellModel())

                self.table.mj_header.endRefreshing()
            }
            if let pageData = response.pageData,pageData.count > 0 {
                self.pageNo = self.pageNo + 1
                self.table.mj_footer.endRefreshing()
            }
            
            self.fetch(response: response)
        
            
        }) { (erro) -> Bool in
            return true
        }
        
    }
    
    func fetch(response:NewsFeedListResponse)  {

        self.fetchs.fetch.append(CommunityBuilder.buiderFeedCellModel(response))
    }
    
    //MARK: - MMCollectionViewDelegate
    @objc func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat {
        guard let m = fetchs.object(at: indexPath) as? CMSCellModel else {
            return 0.0
        }
        return m.supportMagicEdge
    }
    
    //MARK: - loadLayoutConfig
    override func loadLayoutConfig() -> MMLayoutConfig {
        var _config:MMLayoutConfig = MMLayoutConfig()
        _config.rowHeight = 0
        _config.columnCount = 2
        _config.rowDefaultSpace = 0
        _config.columnSpace = 8
        _config.supportMagicHorizontalEdge = true
        return _config
    }
}
