//
//  HomeContainerController.swift
//  merchant-ios
//
//  Created by Tony Fung on 11/5/2017.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import YYText
import XLPagerTabStrip



class HomeContainerController: ButtonBarPagerTabStripViewController {
    private var startNum:Int = 0
    private var hotSearchs: [SearchTerm] = [] // 热门搜索记录
    private final var navigationSearchBarBtn: UIButton!
    var isReload = false
    var channelVCList = [UIViewController]()
    var analyticsViewRecord = AnalyticsViewRecord() //统计相关
    
    override func viewDidLoad() {
        // 设置tab样式
        settings.style.selectedBarVerticalAlignment = .bottom
        settings.style.selectedBarHeight = 2
        settings.style.buttonBarLeftContentInset = 10
        settings.style.buttonBarRightContentInset = 10
        settings.style.buttonBarItemLeftRightMargin = 0
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = .orange
        settings.style.buttonBarItemBackgroundColor = .white
        
        super.viewDidLoad()
        
        buttonBarView.selectedBar.backgroundColor = .white
        buttonBarView.backgroundColor = .white
        self.edgesForExtendedLayout = .bottom
        if #available(iOS 11.0, *) {
            buttonBarView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        analyticsViewRecord.viewKey = Utils.UUID()
        analyticsViewRecord.timestamp = Date()

        self.retrieveChannels()
        self.setupNavigationBarButton()
        self.setupSearchBar()
        loadHotSearch()
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else {
                return
            }
            if self.channelVCList.count > 0  && animated == true{
                if let cmsVC = self.channelVCList[self.currentIndex] as? CMSPageViewController {
                    cmsVC.updateDailyRecommendCom()
                }
            }
            oldCell?.label.textColor = UIColor.gray
            oldCell?.label.font = UIFont.systemFont(ofSize: 15)
            newCell?.label.textColor = .black
            newCell?.label.font = UIFont.boldSystemFont(ofSize: 15)
            if animated {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    newCell?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    oldCell?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                })
            } else {
                newCell?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                oldCell?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            }
        }
    }
    
    @objc func appMovedToBackground() {
        if startNum != 0{
            couponRequest()
        }
        startNum = startNum + 1
    }
    
    func couponRequest()  {
        guard (LoginManager.getLoginState() == .validUser) else {
            return
        }
        CouponService.popupCouponList(success: { (coupon) in
            if let _ =  self.navigationController?.topViewController as? HomeContainerController {
                if let count = coupon.pageData?.count{
                    if count > 0 {
                        CacheManager.sharedManager.hasNewClaimedCoupon = true
                        
                        guard let _ = PushManager.sharedInstance.getTopViewController() as? SingleRecommendViewController else {
                            PopManager.sharedInstance.popupCoupon(coupon, couponCallback: {
                                Navigator.shared.dopen(Navigator.mymm.website_myCoupon, modal: false)
                            })
                            return
                        }
                    } else {
                        guard let _ = PushManager.sharedInstance.getTopViewController() as? SingleRecommendViewController else {
                            BannerManager.sharedManager.showPopupBanner()
                            return
                        }
                    }
                } else {
                    guard let _ = PushManager.sharedInstance.getTopViewController() as? SingleRecommendViewController else {
                        BannerManager.sharedManager.showPopupBanner()
                        return
                    }
                }
            }
        }) { (erro) -> Bool in
            return true
        }
    }
    
    private func retrieveChannels(_ forceRequest: Bool = false) {
        if let channels = Context.getCMSChannel(), !forceRequest {
            setupPageData(channels)
        } else {
            CMSService.channelList(success: { (channels) in
                let channels = channels.filter({$0.status == 2})
                if channels.count > 0 {
                    Context.setCMSChannel(channels: channels)
                }
                self.setupPageData(channels)
            }) { (error) -> Bool in
                if let channels = Context.getCMSChannel(forceCache: true) {
                    self.setupPageData(channels)
                } else {
//                    self.showNoConnectionView(reloadHandler: {
//                        self.retrieveChannels(true)
//                    })
                    Log.debug("Unable Retrieve CMS Channel")
                }
                return true
            }
        }
    }
    
    private func setupPageData(_ channels: [CMSPageModel]) {
        var vcs = [UIViewController]()
        var titles = [String]()
        for channel in channels {
            var bundle = QBundle()
            bundle[ROUTER_ON_BROWSER_KEY] = QValue(channel.isWeb)
            if channel.pageId != 0 { bundle["pageId"] = QValue(channel.pageId) }
            if channel.chnlId != 0 { bundle["chnlId"] = QValue(channel.chnlId) }
            if !channel.title.isEmpty { bundle["title"] = QValue(channel.title) }
            var link = channel.link
            if let node = Navigator.shared.getRouter(url: link), node.controller == "BrandContainerViewController" { // 防止嵌套
                link = Urls.appendFragmentPath(url: link, relativePath: "/inner")
            }
            if let vc = Navigator.shared.getViewController(link, params:bundle) {
                if let mmVC = vc as? MMUIController {
                    mmVC.itemInfo = IndicatorInfo(title: channel.title)
                    vcs.append(mmVC)
                }
                if let otherVC = vc as? MmViewController {
                    otherVC.itemInfo = IndicatorInfo(title: channel.title)
                    vcs.append(otherVC)
                }
                titles.append(channel.title)
            }
        }
        
        //兼容防止没有首页的情况
        if (channels.count == 0) {
            var bundle = QBundle()
            bundle["title"] = QValue("社区") //直接先中文在代码里面不是很合适
            if let vc = Navigator.shared.getViewController(Navigator.mymm.website_post_list,params:bundle) {
                if let mmVC = vc as? MMUIController {
                    mmVC.itemInfo = IndicatorInfo(title: "社区")
                    vcs.append(mmVC)
                }
                if let otherVC = vc as? MmViewController {
                    otherVC.itemInfo = IndicatorInfo(title: "社区")
                    vcs.append(otherVC)
                }
            }
        }
        
        guard vcs.count > 0 && titles.count > 0 else {
//            self.showNoConnectionView(reloadHandler: {
//                self.retrieveChannels(true)
//            })
            return
        }
        
        self.channelVCList = vcs
        
        self.view.disableScrollToTop()
        if let window = UIApplication.shared.keyWindow{
            window.disableScrollToTop()
        }
        
        reloadPagerTabStripView()
        buttonBarView.selectedBar.backgroundColor = .red
    }

    @objc private func openChatView() {
        Navigator.shared.dopen(Navigator.mymm.imLanding)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard (LoginManager.getLoginState() == .validUser) else {
//            showPopup(defaultsKey: "publicPopWindowOnceADay")
            return
        }
        showPopup(defaultsKey: "popWindowOnceADay")

    }

    func showPopup(defaultsKey:String) {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy.MM.dd"
        //        dateFormat.dateFormat = "yyyy.MM.dd HH:mm"
        
        let todayTime = dateFormat.string(from: Date())
        
        let defaults = UserDefaults()
        
        var isFirst = false
        if defaults.object(forKey: defaultsKey) == nil  {
            UserDefaults().set(todayTime , forKey: defaultsKey)
            isFirst = true
            Navigator.shared.dopen(Navigator.mymm.deeplink_x_recommendpopup, modal:true)
        }
        
        
        let dateStr = defaults.object(forKey: defaultsKey) as? String
        
        if dateStr != todayTime {
            defaults.set(todayTime , forKey: defaultsKey)
            Navigator.shared.dopen(Navigator.mymm.deeplink_x_recommendpopup, modal:true)
        } else {
            defaults.set(todayTime , forKey: defaultsKey)
            if !isFirst{
                self.couponRequest()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.setSearchBarPlaceHolder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: - tab methods
    override func reloadPagerTabStripView() {
        isReload = true
        super.reloadPagerTabStripView()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        guard isReload else {
            var childViewControllers = [UIViewController]()
            let vc = MMUIController()
            vc.itemInfo = IndicatorInfo(title: "")
            childViewControllers.append(vc) //默认塞一个
            return childViewControllers
        }
        return channelVCList
    }
  
    private func setupNavigationBarButton() {
        // 逻辑统一到UIBarButtonItemExt
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.menuButtonItem(self, action: #selector(self.showLeftMenuView))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.messageButtonItem(self, action: #selector(self.openChatView))
    }
    
    private func setupSearchBar() {
        let searchBarContainer = UIView(frame: CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.width)! * 0.7, height: 32))
        searchBarContainer.backgroundColor = UIColor(hexString: "#F5F5F5")
        let searchBarBtn = UIButton(type: .custom)
        searchBarBtn.setImage(UIImage(named: "btn_Search"), for: .normal)
        searchBarBtn.setTitleColor(UIColor(hexString: "#BCBCBC"), for: .normal)
        searchBarBtn.setTitle(" " + String.localize("LB_CA_HOMEPAGE_SEARCH"), for: .normal)
        searchBarBtn.addTarget(self, action: #selector(self.searchClicked), for: UIControlEvents.touchUpInside)
        searchBarBtn.frame = CGRect(x: 5, y: 0, width: searchBarContainer.frame.width - 10 , height: searchBarContainer.frame.height)
        searchBarBtn.round(4)
        searchBarBtn.titleLabel?.lineBreakMode = NSLineBreakMode.byTruncatingTail
        searchBarBtn.titleLabel?.font = UIFont(name: "Helvetica", size: 12)
        searchBarContainer.addSubview(searchBarBtn)
        navigationSearchBarBtn = searchBarBtn
        self.navigationItem.titleView = searchBarContainer
    }
    
    // MARK: - Views And Actions
    @objc func searchClicked() {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.pushViewController(searchViewController, animated: false)
    }

    private func loadHotSearch() { // 请求热门搜索
        SearchService.searchComplete("", pageSize: Constants.Paging.newOffset, pageNo: 1, sort: "Priority", order: "desc", merchantId: nil) { (response) in
            if response.result.isSuccess {
                if let term = Mapper<SearchTerm>().mapArray(JSONObject: response.result.value) {
                    let brandSearchTerms = term.filter({$0.entity == "Brand"})
                    let categorySearchTerms = term.filter({$0.entity == "Category"})
                    let merchantSearchTerms = term.filter({$0.entity == "Merchant"})
                    let residualSearchTerms = term.filter({$0.entity != "Brand" && $0.entity != "Category" && $0.entity != "Merchant"})
                    self.hotSearchs = merchantSearchTerms + brandSearchTerms + categorySearchTerms + residualSearchTerms
                    CacheManager.sharedManager.hotSearchTerms = self.hotSearchs
                    self.setSearchBarPlaceHolder()
                }
            }
        }
    }
    
    private func setSearchBarPlaceHolder() {
        let histories = Context.getHistory()
        if histories.count > 0 {
            navigationSearchBarBtn.setTitle(" " + histories.first!, for: .normal)
        } else if self.hotSearchs.count > 0 {
            navigationSearchBarBtn.setTitle(" " + self.hotSearchs[0].searchTerm, for: .normal)
        } else {
            navigationSearchBarBtn.setTitle(" " + String.localize("LB_CA_HOMEPAGE_SEARCH"), for: .normal)
        }
    }

    // MARK: -  lazyload
    private lazy var menuLeftButton: ButtonRedDot = {
       let btn = ButtonRedDot(frame: CGRect(x: 0, y: 0, width: 18, height: 15))
        btn.setImage(UIImage(named: "menu_ic"), for: .normal)
        btn.addTarget(self, action: #selector(self.showLeftMenuView), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc override func track_support() -> Bool {
        return true
    }
}
