//
//  BrandContainerViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/21.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class BrandContainerViewController: MMPageViewController {
    private let navigationSearchHeight:CGFloat = 32
    
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        createNv()
        setupData()
    }
    
    //MARK: - event response
    @objc func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func searchIconClicked(_ sender: UIView) {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    private func setupData() {
        CMSService.channelList(brand: true, success: { (pageModels) in
            self.setupPageController(pageModels)
        }) { (error) -> Bool in
            self.setupPageController([CMSPageModel]())
            return true
        }
    }
    
    private func setupPageController(_ channels: [CMSPageModel]) {
        var vcs = [UIViewController]()
        var titles = [String]()
        let urlPath = Urls.getURLFinderPath(url: self._node.url)
        for idx in 0..<channels.count {
            let channel = channels[idx]
            var bundle = QBundle()
            bundle[ROUTER_ON_BROWSER_KEY] = QValue(channel.isWeb)
            if channel.pageId != 0 { bundle["pageId"] = QValue(channel.pageId) }
            if channel.chnlId != 0 { bundle["chnlId"] = QValue(channel.chnlId) }
            if !channel.title.isEmpty { bundle["title"] = QValue(channel.title) }
            var link = channel.link

            let path = Urls.getURLFinderPath(url: link)
            if path == urlPath {
                initialIndex = idx
            }

            if let node = Navigator.shared.getRouter(url: link), node.controller == "BrandContainerViewController" { // 防止嵌套
                link = Urls.appendFragmentPath(url: link, relativePath: "/inner")
            }

            if let vc = Navigator.shared.getViewController(link, params: bundle) {
                vcs.append(vc)
                titles.append(channel.title)
            }
        }
        
        if channels.count <= 0 {
            let vc = BrandListViewController()
            vcs.append(vc)
            titles.append("全部")
        }
        
        viewControllers = vcs
        segmentedTitles = titles
        reveal()
    }
    
    //MARK: - private methods
    @objc private func openChatView() {
        Navigator.shared.dopen(Navigator.mymm.imLanding)
    }

    private func createNv()  {
        if let navigationBar = self.navigationController?.navigationBar {
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: navigationBar.width * 0.7, height: navigationSearchHeight))
            customView.round(4)
            customView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.searchIconClicked)))
            customView.backgroundColor = UIColor(hexString: "#F5F5F5")
            searchButton.frame =  CGRect(x: 5, y: 0, width: customView.width - 10, height:customView.height)
            customView.addSubview(searchButton)
     
            navigationItem.titleView = customView

            let histories = Context.getHistory()
            if histories.count > 0 {
                searchButton.setTitle(histories.first, for: .normal)
            } else if let searchTerms = CacheManager.sharedManager.hotSearchTerms, searchTerms.count > 0 {
                searchButton.setTitle(searchTerms.first?.searchTerm, for: .normal)
            }
            
            if (self.navigationController?.viewControllers.count)! > 1 {
                createBackButton()
            } else {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem.menuButtonItem(self, action: #selector(self.showLeftMenuView))
            }
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.messageButtonItem(self, action: #selector(self.openChatView))
        }
    }
    
    private lazy var searchButton:UIButton = {
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = false
        searchButton.setTitle(String.localize("LB_CA_HOMEPAGE_SEARCH"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "btn_Search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        return searchButton
    }()
}

