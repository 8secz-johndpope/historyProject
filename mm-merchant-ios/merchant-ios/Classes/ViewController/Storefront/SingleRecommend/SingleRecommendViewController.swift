//
//  SingleRecommendViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/27.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class SingleRecommendViewController: MMUICollectionController<MMCellModel> {
    private var pageNo = 1
    private let GET_COMP_DATAS_SIZE = 10
    private final var contentOffSetY: CGFloat = 0
    
    private var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    
    //MARK: - life
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
        
        if ((self.presentingViewController) != nil) {
             navigationController?.setNavigationBarHidden(true, animated: animated)
        } else {
            if let navigationController = self.navigationController as? MmNavigationController {
                navigationController.setNavigationBarVisibility(offset: 0)
                navigationController.navigationBar.shadowImage = UIImage()
            }
        }
    }
    
    override func onViewWillDisappear(_ animated: Bool) {
        super.onViewWillDisappear(animated)
        
        if ((self.presentingViewController) != nil) {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    override func onViewDidLoad() {
        super.onViewDidLoad()
        table.backgroundColor = .white
        self.title = ""

        if #available(iOS 11.0, *) {
            table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }

        table.mj_header = MMRefreshHeader(refreshingTarget: self, refreshingAction: #selector(headerRefresh))
        table.mj_footer = MMRefreshFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))

        var showCancel = true
        if ((self.presentingViewController) == nil) {
            showCancel = false
            createUIBarButtonItem()
        }
        
        fetchs.fetch.append(SingleRecommendCellBuilder.buiderCellModel(showCancel: showCancel, cancelTap: {
            self.ssn_back()
        }))
        
        showLoading()
        singnRecommendData()
        
        self.view.addSubview(scrollToTopBtn)
    }
    
    func createUIBarButtonItem() {
        let backItem = UIBarButtonItem.createBackItem() { [weak self] (button) in
            if let strongSelf = self {
                button.setImage(UIImage(named: "back_grey"), for: .normal)
                button.addTarget(self, action: #selector(strongSelf.popViewController), for: .touchUpInside)
            }
        }
        navigationItem.leftBarButtonItems = [backItem]
    }
    
    @objc private func popViewController() {
        self.ssn_back()
    }
    
    //MARK: - header & footer refresh
    @objc private func headerRefresh() {
        fetchs.fetch.clear()
        pageNo = 1
        var showCancel = true
        if ((self.presentingViewController) == nil) {
            showCancel = false
        }
        fetchs.fetch.append(SingleRecommendCellBuilder.buiderCellModel(showCancel: showCancel, cancelTap: {
            self.ssn_back()
        }))
        singnRecommendData()
    }
    
    @objc private func footerRefursh()  {
        singnRecommendData()
    }
    
    //MARK: - service
    private func singnRecommendData() {
        if LoginManager.getLoginState() == .validUser {
            SingnRecommendService.userGetRecommendData(pagesize: GET_COMP_DATAS_SIZE, pageno: pageNo, success: { (model) in
                self.fetch(model: model)
            }) { (erro) -> Bool in
                self.endRefresh()
                return true
            }
        } else {
            SingnRecommendService.publickGetRecommendData(pagesize: GET_COMP_DATAS_SIZE, pageno: pageNo, success: { (model) in
                self.fetch(model: model)
            }) { (erro) -> Bool in
                self.endRefresh()
                return true
            }
        }
    }
    
    private func fetch(model:CMSPageComsModel) {
        stopLoading()
        var comps = [CMSPageComsModel]()
        comps.append(model)
        
        if pageNo == 1 {
            table.mj_header.endRefreshing()

        } else {
            table.mj_footer.endRefreshing()
        }
        
        if let data = model.data,data.count > 0 {
           pageNo = pageNo + 1
        } else {
            if pageNo == 1 {
                ssn_back()
            }
        }
        fetchs.fetch.append(CMSPageNewsfeedCellBuilder.buiderCellModel(model, is: false))
    }
    
    private func endRefresh() {
        stopLoading()
        if self.pageNo == 1 {
            table.mj_header.endRefreshing()
            
        } else {
            table.mj_footer.endRefreshing()
        }
        ssn_back()
    }
    
    @objc private func scrollToTopBtnClick(_ btn: UIButton) {
        table.scrollToTopAnimated(true)
    }
    
    //MARK: - MMCollectionViewDelegate
    @objc func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat {
        guard let m = fetchs.object(at: indexPath) as? CMSCellModel else {
            return 0.0
        }
        return m.supportMagicEdge
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > scrollView.height*3  {
            scrollToTopBtn.isHidden = contentOffSetY > scrollView.contentOffset.y ? false : true
            contentOffSetY = scrollView.contentOffset.y
        } else {
            scrollToTopBtn.isHidden = true
        }
    }
    
    //MARK: - private methods
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    override func loadLayoutConfig() -> MMLayoutConfig {
        var _config:MMLayoutConfig = MMLayoutConfig()
        _config.rowHeight = 0
        _config.columnCount = 2
        _config.rowDefaultSpace = 0
        _config.columnSpace = 8
        _config.supportMagicHorizontalEdge = true
        return _config
    }
    
    private lazy var scrollToTopBtn: UIButton = {
        var parentViewY: CGFloat = 0
        if let vc = parent {
            parentViewY = vc.view.y
        }
        let btn = UIButton(frame: CGRect(x: ScreenWidth - 60, y: self.view.height - 100, width: 48, height: 48))
        btn.isHidden = true
        btn.setImage(UIImage(named: "back_to_top"), for: .normal)
        btn.addTarget(self, action: #selector(self.scrollToTopBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
}

extension SingleRecommendViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
