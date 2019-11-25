//
//  SyteProductListViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/7/27.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import MJRefresh

class SyteProductListViewController: MMUICollectionController<MMCellModel> {
    private var pageNo = 1
    private let GET_COMP_DATAS_SIZE = 50
    private var skuid:Int?
    private var brandList = [Brand]()

    
    //MARK: - life
    override func onViewDidLoad() {
        super.onViewDidLoad()
        table.backgroundColor = .white
        self.title = ""
        
        let head = MMRefreshHeader(refreshingTarget: self, refreshingAction: #selector(headerRefresh))
        let footer = MMRefreshFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))
        
        table.mj_header = head
        table.mj_footer = footer
        
        if let skuid = ssn_Arguments["skuid"]?.int {
            self.skuid = skuid
        }
        
        styleSearchData()
        
        createUIBarButtonItem()
    }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func goToPLP() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    //MARK: - header & footer refresh
    @objc private func headerRefresh() {
        self.fetchs.fetch.clear()
        self.pageNo = 1
        self.brandList.removeAll()
        styleSearchData()
    }
    
    @objc private func footerRefursh()  {
        styleSearchData()
    }
    
    //MARK: - service
    private func styleSearchData() {
        if let skuid = skuid {
            SingnRecommendService.styleSearchData(skuid: skuid, pagesize: GET_COMP_DATAS_SIZE, pageno: self.pageNo, success: { (response) in

                let syteList = SyteProductListBuilder.buiderStyleCellModel(response, brandList: &self.brandList)
                if self.pageNo == 1 {
                    self.table.mj_header.endRefreshing()
                } else {
                    self.table.mj_footer.endRefreshing()
                }

                if self.pageNo == 1 {
                    if self.brandList.count >= 3 {
                        self.fetchs.fetch.append(SyteProductListBuilder.buiderUserCellModel(self.brandList))
                    }
                } else {
                    if let cellModel = self.fetchs.fetch[0] as? SyteBrandCellModel {
                        cellModel.brandList = self.brandList
                        self.fetchs.fetch.update(0)
                    } else {
                        if self.brandList.count >= 3 {
                            self.fetchs.fetch.insert(SyteProductListBuilder.buiderUserCellModel(self.brandList), atIndex: 0)
                        }
                    }
                }

                self.fetchs.fetch.append(syteList)

                if syteList.count > 0 {
                    self.pageNo = self.pageNo + 1
                }
            }) { (erro) -> Bool in
                self.table.mj_header.endRefreshing()
                self.table.mj_footer.endRefreshing()
                return true
            }
        }
    }
    
    //MARK: - private methods
    func createUIBarButtonItem() {
        let backItem = UIBarButtonItem.createBackItem() { [weak self] (button) in
            if let strongSelf = self {
                button.setImage(UIImage(named: "back_grey"), for: .normal)
                button.addTarget(self, action: #selector(strongSelf.popViewController), for: .touchUpInside)
            }
        }
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth * 0.8, height: 35 ))
        customView.layer.cornerRadius = 4
        customView.layer.masksToBounds = true
        customView.backgroundColor = UIColor.imagePlaceholder()
        
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = false
        searchButton.setTitle(String.localize("LB_CA_HOMEPAGE_SEARCH"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        searchButton.frame =  CGRect(x: (customView.width - searchButton.width) / 2, y: (35 - searchButton.height) / 2, width: searchButton.width, height:searchButton.height)
        customView.addSubview(searchButton)
        customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToPLP)))
        navigationItem.titleView = customView
        navigationItem.leftBarButtonItems = [backItem]
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
