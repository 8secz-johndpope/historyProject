//
//  CMSPageViewController.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/25.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import ObjectMapper
import Alamofire
import MJRefresh
import ObjectMapper
import PromiseKit
import MBProgressHUD

class CMSPageViewController:MMUICollectionController<MMCellModel>,FlyNotice {
    
    let GET_COMP_DATAS_SIZE = 50
    var index = 0
    var pageNo = 1
    open var channel: CMSPageModel?
    private final let WidthItemBar: CGFloat = 33
    private final let HeightItemBar: CGFloat = 33
    private final var contentOffSetY: CGFloat = 0
    var likeCount = 0
    private var needFooter = false
    
    var loadLikeStatue = false
    let heightBottomView: CGFloat = 44 // 此页面bottom_bar不需要对iPhoneX做特殊处理
    var comsDatas = [CMSPageComsModel]()
    
    private var pageChannelId: String? {
        get {
            guard let pIdStr = self.ssn_Arguments["pageId"]?.string else {
                return nil
            }
            var idStr = pIdStr
            if let channelIdStr = self.ssn_Arguments["chnlId"]?.string {
                idStr = "\(idStr) \(channelIdStr)"
            }
            
            return idStr
        }
    }
    
    private var dailyRecommendComIndex:[CMSPageComsModel] = [CMSPageComsModel]()
    
    convenience init(_ str:String) {
        self.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        Fly.page.unbind(self)
        if let id = self.pageChannelId {
            VideoPlayManager.shared.videoPageDestroy(pageId: id)
        }
    }
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    //MARK: - life
    public override func onLoadView() -> Bool {
        let rt = super.onLoadView()
        if rt {
            //            let chnlId = self.ssn_Arguments["chnlId"]?.int
            //            if chnlId == nil || chnlId! == 0 {
            //                setupBottomView()
            //            }
        }
        return true
    }
    
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
        
        if let id = pageChannelId {
            VideoPlayManager.shared.videoPageWillAppear(pageId: id)
        }
    }
    
    override func onViewDidAppear(_ animated: Bool) {
        super.onViewDidAppear(animated)
        
        if let id = pageChannelId {
            VideoPlayManager.shared.videoPageDidAppear(pageId: id)
        }
    }
    
    override func onViewWillDisappear(_ animated: Bool) {
        super.onViewWillDisappear(animated)
        if let id = pageChannelId {
            VideoPlayManager.shared.videoPageWillDisappear(pageId: id)
        }
    }
    
    override func onViewDidDisappear(_ animated: Bool) {
        super.onViewDidDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToTopBtn.frame = CGRect(x: ScreenWidth - 60, y: self.view.height - 100, width: 48, height: 48)
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.headerRefresh), name: Constants.Notification.loginSucceed, object: nil)
        
        if IsIphoneX {
            self.edgesForExtendedLayout = UIRectEdge.bottom

            if #available(iOS 11.0, *) {
                table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
            } else {
                self.automaticallyAdjustsScrollViewInsets = false
            }
        }
 
        
        if let title = self.ssn_Arguments["title"]?.string, !title.isEmpty {
            self.title = title
        }
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: shareButton),UIBarButtonItem(customView: heartBtn)]
        table.backgroundColor = .white
        
        showLoading()
        pageListService()
        let head = MMRefreshHeader(refreshingTarget: self, refreshingAction: #selector(headerRefresh))
        
        table.mj_header = head
        
        
        self.view.addSubview(noConnectionView)
        noConnectionView.reloadHandler = {[weak self] in
            if let strongSelf = self {
                strongSelf.pageListService()
            }
        }
        self.view.addSubview(scrollToTopBtn)
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            navigationItem.leftBarButtonItem = self.createButtonBar(
                "back_grey",
                selectorName: #selector(popViewController),
                size: CGSize(width: 30,height: 25),
                left: Constants.Value.BackButtonMarginLeft,
                right: 0
            )
        }
    }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
  
    //MARK: - Header & Footer Refresh
    @objc func headerRefresh() {
        self.dailyRecommendComIndex.removeAll()
        self.fetchs.fetch.clear()
        if let id = pageChannelId {
            VideoPlayManager.shared.videoPageDestroy(pageId: id)
        }
        
        pageListService()
    }
    
    @objc func footerRefursh()  {
        
        if comsDatas.count > 0{
            let com =  comsDatas[comsDatas.count - 1]
            if com.isAPI && com.comType != .couponSection && com.comType != .dailyRecommend {
                needAPIGetData(comp: com,footerRefresh:true,feedFooter:true)
            }else {
                self.table.mj_footer.endRefreshing()
            }
        }else {
            self.table.mj_footer.endRefreshing()
        }
    }
    
    //MARK: - CMSService
    func pageListService()  {
        if let id = self.ssn_Arguments["pageId"]?.int {
            
            var chnlId = 0
            if let chid = self.ssn_Arguments["chnlId"]?.int {
                chnlId = chid
            }
            CMSService.list(id, chnlId: chnlId, success: { (model) in
                self.noConnectionView.isHidden = true
                self.stopLoading()
                
                if let coms = model.coms{
                    self.pageNo = 1
                    self.comsDatas = [CMSPageComsModel]()
                    self.comsDatas = coms
                    self.upFeatch(coms: coms)
                    self.table.mj_header.endRefreshing()
                    self.table.scrollsToTop = true
                }
                
                if !model.isShareable {
                    self.navigationItem.rightBarButtonItem = nil
                } else {
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.shareButton)
                }
                
                if !model.title.isEmpty {
                    self.title = model.title
                }
                
                self.channel = model
                
                self.updateLikeViewStatus()
            }) { (erro) -> Bool in
                self.stopLoading()
                self.view.addSubview(self.noConnectionView)
                self.noConnectionView.isHidden = false
                self.table.mj_header.endRefreshing()
                return true
            }
        }
    }
    
    func needAPIGetData(comp:CMSPageComsModel,footerRefresh:Bool,feedFooter:Bool = false) {
        if let pageId = self.ssn_Arguments["pageId"]?.int {
            var id = 0
            if let comId = Int(comp.comId){
                id = comId
            }
            
            CMSService.getComponentDatas(comp,id, pageId, pagesize: GET_COMP_DATAS_SIZE, pageno: pageNo, compIdx: comp.comIdx, success: { (model) in
                var comps = [CMSPageComsModel]()
                
                model.title = comp.title
                model.bottom = comp.bottom
                model.w = comp.w
                model.h = comp.h
                model.moreLink = comp.moreLink
                model.colCount = comp.colCount
                model.isActive = comp.isActive
                model.isAPI = comp.isAPI
                model.bottom = comp.bottom
                model.border = comp.border
                model.comCMSPath = comp.comCMSPath
                model.extraInfo = comp.extraInfo
                model.orientation = comp.orientation
                
                comps.append(model)
                self.upFeatch(coms:comps, noApi:true,feedFooter:feedFooter)
                if self.needFooter {
                    self.table.mj_footer.endRefreshing()
                }
                
                if self.comsDatas.count > 0 {
                    let com =  self.comsDatas[self.comsDatas.count - 1]
                    if comp.title == com.title && model.data?.count != 0 {
                        self.pageNo = self.pageNo + 1
                    }
                }
            }, successArray: { (models) in
                var comps = [CMSPageComsModel]()
                let comsModel = comp
                comp.recommends = models
                var recommendLinks = [String]()
                if let data = comp.data {
                    for model in data {
                        recommendLinks.append(model.link)
                    }
                }
                comp.recommendLinks = recommendLinks
                comps.append(comsModel)
                self.upFeatch(coms:comps, noApi:true,feedFooter:feedFooter)
            
            }) { (erro) -> Bool in
                if self.needFooter {
                    self.table.mj_footer.endRefreshing()
                }
                
                return true
            }
        }
    }
    
    //MARK: - Featch
    func updateDailyRecommendCom() {
        
        for com in dailyRecommendComIndex {
            var exist = false
            var index = self.findComponentInsertLocation(index: com.comIdx,exist:&exist)
            if exist && index > 0 {//表示前面已经有一部分数据，注意尾部间隔
                if let model = self.fetchs.fetch[index - 1] as? CMSPageBottomCellModel,model.modelGroup == com.comGroupId  {
                    index = index - 1
                }
            }
            
            self.fetchs.fetch.update(index - 1)
        }
    }
    func upFeatch(coms:[CMSPageComsModel], noApi: Bool = false,feedFooter:Bool = false) {
        self.fetchs.fetch.transaction({ [weak self] in
            guard let sself = self else { return }
            for com in coms {
                var support = false
                if com.comType == .swiperBanner {
                    support = true
                    
//                    sself.fetchs.fetch.append(CMSPageRecommendCellBuilder.buiderCellModel(com, cancelTap: {
//                        print("点击了取消")
//                    }))
                    sself.fetchs.fetch.append(CMSPageSwiperBannerCellBuilder.buiderCellModel(com))
                } else if com.comType == .gridBanner {
                    let shouldAppend = com.comCMSPath != .newUserRegister || !LoginManager.isValidUser() /* guest user should see register banner */
                    if shouldAppend {
                        support = true
                        sself.fetchs.fetch.append(CMSPagePageGegridBannerCellBuilder.buiderCellModel(com))
                    }
                } else if com.comType == .productBanner {
                    support = true
                    sself.fetchs.fetch.append(CMSPageProductBannerCellBuilder.buiderCellModel(com))
                } else if com.comType == .heroBanner {
                    support = true
                    sself.fetchs.fetch.append(CMSPageHeroBannerCellBuilder.buiderCellModel(com))
                } else if com.comType == .brandListBanner {
                    support = true
                    sself.fetchs.fetch.append(CMSPageBrandListBannerCellBuilder.buiderCellModel(com))
                } else if com.comType == .rankingBanner {
                    support = true
                    sself.fetchs.fetch.append(CMSPageRankingBannerCellBuilder.buiderCellModel(com))
                } else if com.comType == .newsfeed
                    || com.comType == .Newsfeed
                    || com.comType == .productList
                    || com.comType == .ProductList {
                    support = true
                    var exist = false
                    var index = sself.findComponentInsertLocation(index: com.comIdx,exist:&exist)
                    if exist  && index > 0 {//表示前面已经有一部分数据，注意尾部间隔
                        if let model = sself.fetchs.fetch[index - 1] as? CMSPageBottomCellModel,model.modelGroup == com.comGroupId  {
                            index = index - 1
                        }
                    }
                    sself.fetchs.fetch.insert(CMSPageNewsfeedCellBuilder.buiderCellModel(com, is: !exist),atIndex: index)
                } else if com.comType == .couponSection {
                    support = true
                    var exist = false
                    var index = sself.findComponentInsertLocation(index: com.comIdx,exist:&exist)
                    if exist && index > 0 {//表示前面已经有一部分数据，注意尾部间隔
                        if let model = sself.fetchs.fetch[index - 1] as? CMSPageBottomCellModel,model.modelGroup == com.comGroupId  {
                            index = index - 1
                        }
                    }
                    sself.fetchs.fetch.insert(CMSPageCouponCellBuilder.buiderCellModel(com, delegate: sself, is: !exist),atIndex: index)
                } else if com.comType == .dailyRecommend {
                    support = true
                    var exist = false
                    var index = sself.findComponentInsertLocation(index: com.comIdx,exist:&exist)
                    if exist && index > 0 {//表示前面已经有一部分数据，注意尾部间隔
                        if let model = sself.fetchs.fetch[index - 1] as? CMSPageBottomCellModel,model.modelGroup == com.comGroupId  {
                            index = index - 1
                            sself.dailyRecommendComIndex.append(com)
                        }
                    }
                    sself.fetchs.fetch.insert(CMSPageDailyRecommendBuilder.buiderCellModel(com, is: !exist),atIndex: index)
                }
                
                //加载 api 数据
                if support && !noApi && com.isAPI {
                    sself.needAPIGetData(comp: com,footerRefresh:false)
                    
                }
                if com.isAPI && com.comType != .couponSection && com.comType != .dailyRecommend {
                    sself.needFooter = true
                }

            }
            if sself.needFooter {
                sself.table.mj_footer = MMRefreshFooter(refreshingTarget: sself, refreshingAction: #selector(sself.footerRefursh))
            }
        })
    }
    
    private func findComponentInsertLocation(index:Int,is head:Bool = false, exist: inout Bool) -> Int {
        if self.fetchs.fetch.count() == 0 {
            return 0
        }
        
        //反向查找
        for idx in (0...index).reversed() {
            let group = "\(idx)"
            if let range = self.fetchs.fetch.range(group: group) {
                exist = idx == index
                if head {
                    return range.lowerBound
                } else {
                    return range.upperBound
                }
            }
        }
        
        return 0
    }
    
    //MARK: - CollectionViewDelegate
    @objc func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat {
        guard let m = fetchs.object(at: indexPath) as? CMSCellModel else {
            return 0.0
        }
        return m.supportMagicEdge
    }
    
    @objc func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y == 0.0 {
            VideoPlayManager.shared.isActivePlayerOutOfScreen()
        }
    }
    
    @objc func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        VideoPlayManager.shared.isActivePlayerOutOfScreen()
    }
    
    @objc override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ProductBannerVideoCell, cell.isVideo {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
    
    @objc override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ProductBannerVideoCell, cell.isVideo {
            VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let channel = self.channel {
            if channel.chnlId <= 0 {
                if scrollView.contentOffset.y > scrollView.height*3  {
                    scrollToTopBtn.isHidden = contentOffSetY > scrollView.contentOffset.y ? false : true
                    contentOffSetY = scrollView.contentOffset.y
                } else {
                    scrollToTopBtn.isHidden = true
                }
            }
        }
    }
    
    //MARK: - MMLayout
    override func loadLayoutConfig() -> MMLayoutConfig {
        var _config:MMLayoutConfig = MMLayoutConfig()
        _config.rowHeight = 0
        _config.columnCount = 2
        _config.rowDefaultSpace = 0
        _config.columnSpace = 8
        _config.supportMagicHorizontalEdge = true
        return _config
    }
    
    //MARK: - Touch events
    @objc func likeButtonOnTap(_ sender: ButtonNumberDot) {
        
        // detect guest mode
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        sender.isSelected = !sender.isSelected
        let isLike: Int =  sender.isSelected ? 1 : 0
        if let channel = self.channel {
            sender.isUserInteractionEnabled = false
            actionLike(isLike, pageModel: channel, completion: {
                sender.isUserInteractionEnabled = true
                sender.track_consoleTitle = sender.isSelected ? "取消喜欢" : "喜欢"
            }, fail: {
                sender.isUserInteractionEnabled = true
                sender.isSelected = !sender.isSelected
                sender.setLikeBadgeNumber(channel.likeCount)
                Log.debug("Error")
            })
        }
    }
    
    @objc func shareButtonTapped() {
        let shareViewController = ShareViewController()
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(
                        userList: [myRole, targetRole],
                        senderMerchantId: myRole.merchantId
                    ),
                    checkNetwork: true,
                    viewController: strongSelf,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let chatModel = ChatModel(text: strongSelf._node.url)
                            let viewController = UserChatViewController(convKey: convKey)
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                })
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            if let channel = self.channel {
                ShareManager.sharedManager.shareCMSContentPage(channel, method: method)
            }
        }
        
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    @objc private func scrollToTopBtnClick(_ btn: UIButton) {
        table.scrollToTopAnimated(true)
    }
    
    // MARK: -  lazyload
    
    lazy var shareButton: UIButton = {
        let shareButton = UIButton(type: .custom)
        shareButton.frame = CGRect(x:0, y: 0, width: WidthItemBar, height: HeightItemBar)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        shareButton.setImage(UIImage(named:"share_black"), for: .normal)
        shareButton.track_consoleTitle = "分享"//埋点需要
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat(-19))
        shareButton.clipsToBounds = false
        return shareButton
    }()
    
    private lazy var heartBtn: ButtonNumberDot = {
        let ShareButtonHeight = CGFloat(44)
        let ShareButtonWidth = CGFloat(44)
        let btn = ButtonNumberDot(type: .custom)
        btn.setImage(UIImage(named: "icon_heart_filled"), for: .selected)
        btn.setImage(UIImage(named: "icon_heart_stroke"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: ShareButtonWidth, height: ShareButtonHeight)
        btn.addTarget(self, action: #selector(CMSPageViewController.likeButtonOnTap), for: .touchUpInside)
        btn.track_consoleTitle = "喜欢"
        return btn
    }()
    
    private lazy var scrollToTopBtn: UIButton = {
        var parentViewY: CGFloat = 0
        if let vc = parent {
          parentViewY = vc.view.y
        }
        let btn = UIButton(frame: CGRect(x: ScreenWidth - 60, y: self.view.height - 100, width: 48, height: 48))
        btn.isHidden = true
        btn.setImage(UIImage(named: "back_to_top"), for: .normal)
        btn.addTarget(self, action: #selector(CMSPageViewController.scrollToTopBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    private func createButtonBar(_ imageName: String, selectedImageName: String? = nil, selectorName: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        let button: UIButton = UIButton()
        button.setImage(UIImage(named: imageName), for: UIControlState())
        if let selected = selectedImageName { button.setImage(UIImage(named: selected), for: .selected) }
        button.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        button.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        button .addTarget(self, action: selectorName, for: .touchUpInside)
        
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = button
        return temp
    }
}

extension CMSPageViewController: MMPageViewControllerDelegate {
    func setIndex(index: Int) {
        self.index = index
    }
    
    func getIndex() -> Int {
        return index
    }
}

//MARK: - Bottom And Like
extension CMSPageViewController {
    func updateLikeViewStatus() {
        guard let channel = self.channel else { return  }
        //非单页的不要有喜欢
        if channel.chnlId > 0 {
            return
        }
        likeCount = channel.likeCount
        if !channel.pageKey.isEmpty {
            Fly.page.bind(channel.pageKey, notice: self) //绑定数据状态变化
        }
    }
    
    func on_data_update(dataId: String, model: FlyModel?, isDeleted: Bool) {
        //同一个数据,非单页的不要有喜欢
        guard let pageLike = model as? Fly.PageHotData, let channel = self.channel,channel.chnlId == 0 else { return  }
        let upLikeCount = channel.isLike != pageLike.isLike
        channel.isLike = pageLike.isLike
        if upLikeCount  {
            channel.likeCount = channel.likeCount + (pageLike.isLike ? 1 : -1)
            heartBtn.isSelected = pageLike.isLike
        }
        heartBtn.setLikeBadgeNumber(likeCount)
    }

    /**
     action like on content page
     
     - parameter isLike:     1: 0
     - parameter contentKey: contetn page key
     
     - returns: Promize
     */
    @discardableResult
    func actionLike(_ isLike: Int, pageModel: CMSPageModel, completion: (()->())?,  fail: (()->())? ) -> Promise<Any>{
        
        return Promise{ fulfill, reject in
            
            MagazineService.actionLikeMagazine(isLike, contentPageKey: pageModel.pageKey, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
                        if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                            Log.debug("likePostCall OK" + pageModel.pageKey)
                            
                            let pageLike = Fly.PageHotData()
                            pageLike.pageKey = pageModel.pageKey
                            pageLike.isLike = isLike == 1
                            if pageLike.isLike {
                                self.likeCount += 1
                            } else {
                                self.likeCount -= 1
                            }
                            Fly.page.save(pageLike)
                            
                            //以下代码将废弃，使用Fly.page管理即可
                            if isLike == 1 {
                                CacheManager.sharedManager.addLikedMagazieCover(pageModel.toMagazineModel())
                            } else {
                                CacheManager.sharedManager.removeLikedMagazieCover(pageModel.toMagazineModel())
                            }
                            
                            fulfill(pageModel.pageKey)
                            if let callback = completion {
                                callback()
                            }
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                        
                        if let callback = fail {
                            callback()
                        }
                        
                    }
                } else {
                    reject(response.result.error!)
                    
                    if let callback = fail {
                        callback()
                    }
                }
                
            })
        }
    }
}

extension CMSPageViewController: MerchantCouponDelegate {
    
    func clickOnCoupon(_ coupon: Coupon, cell: MerchantCouponCell, claimCompletion: (() -> Void)?) {
        guard LoginManager.getLoginState() == .validUser else {
            Navigator.shared.dopen(Navigator.mymm.website_login, modal: true)
            return
        }
        guard let merchantId = coupon.merchantId else { return }
        
        if coupon.isClaimed {
            //use directly
            var merchantId = -1
            var brandId = -1
            if let mId = coupon.merchantId, mId > 0 {
                merchantId = mId
            } else if let mId = coupon.segmentMerchantId, mId > 0 {
                merchantId = mId
            } else if let bId = coupon.segmentBrandId, bId > 0 {
                brandId = bId
            }
            
            if merchantId > 0 {
                Navigator.shared.dopen(Navigator.mymm.website_merchant_merchantId + "\(merchantId)")
            } else if brandId > 0 {
                Navigator.shared.dopen(Navigator.mymm.website_brand_brandId + "\(brandId)")
            }
            
        } else {
            CouponService.claimCoupon(coupon.couponReference, merchantId: merchantId, complete: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        coupon.isClaimed = true
                        CacheManager.sharedManager.hasNewClaimedCoupon = true
                        strongSelf.showSuccessPopupWithText(String.localize("LB_CA_COUPON_CLAIMED_SUC"))
                        CouponManager.shareManager().invalidate(wallet: CouponMerchant.combine.rawValue)
                        CouponManager.shareManager().invalidate(wallet: merchantId)
                        
                        if let completion = claimCompletion {
                            completion()
                        }
                    }
                }
            })
        }
    }
    
    func viewAllCoupon() {
        
    }
    
    func showSuccessPopupWithText(_ text: String, delegate: MmViewController? = nil, isAddWindow: Bool? = nil, delay : Double = 1.5) {
        var hud : MBProgressHUD?
        
        if let isAdd = isAddWindow, let window = UIApplication.shared.windows.last, isAdd {
            MBProgressHUD.hideAllHUDs(for: window, animated: false)
            hud = MBProgressHUD.showAdded(to: window, animated: true)
        }
        else if let view = self.navigationController?.view {
            MBProgressHUD.hideAllHUDs(for: view, animated: false)
            hud = MBProgressHUD.showAdded(to: view, animated: true)
        }
        
        if let hud = hud {
            if let dlgate = delegate {
                hud.delegate = dlgate
            }
            hud.mode = .customView
            hud.opacity = 0.7
            let imageView = UIImageView(image: UIImage(named: "alert_ok"))
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            hud.customView = imageView
            hud.isUserInteractionEnabled = false
            hud.labelText = text
            hud.hide(true, afterDelay: delay)
        }
    }
}

