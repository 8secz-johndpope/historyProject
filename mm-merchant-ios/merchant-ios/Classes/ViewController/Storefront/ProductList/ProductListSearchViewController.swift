//
//  ProductListSearchViewController.swift
//  storefront-ios
//
//  Created by song on 2018/6/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListSearchViewController: MMPageViewController {
  
    var productListViewController:ProductListViewController?
    var discoverUserViewController:DiscoverUserViewController?
    var styleFilter:StyleFilter?
    var styles: [Style] = []
    weak var getStyleDelegate:SearchProductViewDelegage?
    
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.segmentBackgroundColor = UIColor(hexString: "#FAFAFA")
        
        shouldRecordViewTag = false //容器控制器，不进行埋点
        self.isBounce = false
        var vcs = [UIViewController]()
        var titles = [String]()
        
        let discoverUserViewController = DiscoverUserViewController()
        let productListViewController = ProductListViewController()
        productListViewController.delegate = self
        productListViewController.getStyleDelegate = getStyleDelegate
        discoverUserViewController.scrollViewDelegate = self
        productListViewController.searchFetchStylesBlock = { [weak self] searchStr in
            if let strongSelf = self {
                strongSelf.createEmptySearchBox(searchStr)
                discoverUserViewController.searchString = searchStr
                discoverUserViewController.refreshData()
                if let _ =  strongSelf.navigationController?.topViewController as? SearchStyleController {
                    strongSelf.navigationController?.popViewController(animated: false)
                }
            }
        }
        productListViewController.fromSearch = true
        if let styleFilter = styleFilter {
            productListViewController.styles = styles
            productListViewController.setStyleFilter(styleFilter.clone(), isNeedSnapshot: true)
            styleFilter.saveSnapshot()
            productListViewController.setOriginalStylFilter(styleFilter.clone())
            if let block = productListViewController.searchFetchStylesBlock {
                block(styleFilter.queryString)
            }
            productListViewController.searchStyle()
        } else {
            productListViewController.isSearch = true
        }
        
        productListViewController.doSearchBlock = { [weak self] searchStyleController in
            if let strongSelf = self {
                strongSelf.navigationController?.pushViewController(searchStyleController, animated: false)
            }
        }
        
        
        vcs.append(productListViewController)
        vcs.append(discoverUserViewController)
        self.productListViewController = productListViewController
        self.discoverUserViewController = discoverUserViewController
        
        titles.append(String.localize("LB_ITEM"))
        titles.append(String.localize("LB_CA_USER"))
        
        self.viewControllers = vcs
        self.segmentedTitles = titles
    }
    
    //MARK: - event response
    @objc func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func searchIconClicked()  {
        productListViewController?.doSearch()
    }
    
    @objc func searchBarCloseClicked()  {
        productListViewController?.doSearch(didClickCloseBtn: true)
    }
    
    //MARK: - private methods
    func createEmptySearchBox(_ string:String) {
        //View search box
        let searchView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth - 70, height: 32))
        searchView.backgroundColor = UIColor(hexString: "#F1F1F1")
        searchView.layer.cornerRadius = 5
        searchView.layer.masksToBounds = true
        
        let searchIconImageView = UIImageView(image: UIImage(named: "search_grey"))
        searchIconImageView.frame = CGRect(x: 10, y: searchView.bounds.midY - 14 / 2, width: 14, height: 14)
        searchView.addSubview(searchIconImageView)
        
        //Label search term
        let searchTermLabel = UILabel(frame: CGRect(x: searchIconImageView.frame.maxX + 10, y: 0, width: searchView.bounds.maxX - (searchIconImageView.bounds.maxX + 10), height: searchView.bounds.maxY))
        searchTermLabel.textColor = UIColor(hexString: "#333333")
        searchTermLabel.textAlignment = .left
        searchTermLabel.font = UIFont.systemFont(ofSize: 14)
        searchView.addSubview(searchTermLabel)
        searchTermLabel.text = string
        
        let closeBtn = UIButton(type: .custom)
        closeBtn.setImage(UIImage(named: "searchbar_close"), for: .normal)
        closeBtn.frame = CGRect(x: searchView.frame.width - 40, y: 0, width: 32, height: 32)
        closeBtn.addTarget(self, action: #selector(searchBarCloseClicked), for: .touchUpInside)
        //Button Search contains search box
        let searchButton = UIButton(type: UIButtonType.custom)
        searchButton.frame = CGRect(x: 0, y: 0, width: searchView.width - 32, height: 32)
        searchButton .addTarget(self, action:#selector(searchIconClicked), for: .touchUpInside)
        searchButton.contentEdgeInsets = UIEdgeInsets.zero
        searchView.addSubview(searchButton)
        searchView.addSubview(closeBtn)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_grey")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(popViewController))
        navigationItem.titleView = searchView
    }
}

extension ProductListSearchViewController: ProductListViewControllerDelegate {
    
    func productListViewControllerScrollViewDidScroll(_ scrollView: UIScrollView) {
        let newOffsetY = scrollView.contentOffset.y
        if newOffsetY > 0 {
            if newOffsetY < StartYPos {
                segmentedControlView?.frame = CGRect(x: 0, y: StartYPos - newOffsetY , width: ScreenWidth, height: SEGMENT_HEIGHT)
            }
            let searchBarMaxY = segmentedControlView?.frame.maxY ?? StartYPos + SEGMENT_HEIGHT
            pageViewController.view.frame = CGRect(x: 0, y: searchBarMaxY, width: view.frame.size.width, height: ScreenHeight - searchBarMaxY )
        } else {
            segmentedControlView?.frame = CGRect(x: 0, y: StartYPos - newOffsetY , width: ScreenWidth, height: SEGMENT_HEIGHT)
            let searchBarMaxY =  StartYPos + SEGMENT_HEIGHT
            pageViewController.view.frame = CGRect(x: 0, y: searchBarMaxY, width: view.frame.size.width, height: view.frame.size.height  - searchBarMaxY )
        }
    }
}
