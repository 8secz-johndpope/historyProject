//
//  StyleFeedController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class StyleFeedController : MmViewController, CuratorCellDelegate{
    
    enum SectionType: Int {
        case curatorSection = 0,
        feedSection = 1
    }
    
    private var myFeedCollectionViewCells = [MyFeedCollectionViewCell]()
    var curatorDatasources = [Curator]()
    
    private final let LoadingCellIdentifier = "LoadingCellIdentifier"
    var paidOrder : ParentOrder?
    var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    
    var customPullToRefreshView: PullToRefreshUpdateView?
    private var currentCurator: Curator?
    
    private var searchButton = UIButton()
    var isUpdatingNewFeeds = false
    
    var postManager : PostManager!
    private var needReloadData = false
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if let displayViewController = Utils.findActiveNavigationController()?.viewControllers[0] {
            postManager = PostManager(postFeedTyle: .styleFeed, collectionView: self.collectionView, viewController: displayViewController)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.followCuratorWithGuestUser), name: Constants.Notification.followCuratorWithGuestUser, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.followingDidUpdate), name: Constants.Notification.followingDidUpdate, object: nil)
        view.backgroundColor = UIColor.white
        self.setupNavigationBar()
        self.configCollectionView()
        
        self.updateNewsFeed(pageNo: 1)
        initAnalyticLog()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchCuratorsList(false)//fix bug follow status not update
        NotificationCenter.default.addObserver(self, selector: #selector(self.startAllAnimations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAllAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveScreenCapNotification), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        if self.needReloadData {
            self.needReloadData = false
            self.updateNewsFeed(pageNo: 1)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Fix animation conflict for showing MyFeedCollectionViewCell at first time
        let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.startAllAnimations()
        }
        
        
        if hasToPushToCuratorList {
            hasToPushToCuratorList = false
            curatorCellDidSelectSeeAllCuratorButton()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopAllAnimations()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
    }
    
    func loadBaseData(){
        self.fetchCuratorsList()
        self.updateNewsFeed(pageNo: 1)
    }
    
    func loadCuratorFeed() {
        self.updateNewsFeed(pageNo: 1)
    }
    
    @objc func searchIconClicked(_ id : Any) {
        let searchViewController = ProductListSearchViewController()
        self.navigationController?.push(searchViewController, animated: false)
    }
    
    func configCollectionView() {
        self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight)
        self.collectionView.backgroundColor = UIColor.feedCollectionViewBackground()
        
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: LoadingCellIdentifier)
        self.collectionView.register(CuratorCollectionViewCell.self, forCellWithReuseIdentifier: CuratorCollectionViewCell.CellId)
        
        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x: (self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 258.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        customPullToRefreshView?.delegate = self
        self.collectionView.addSubview(customPullToRefreshView!)
    }
    
    
    // MARK: - Follow Curator With Guest User
    @objc func followCuratorWithGuestUser(_ notification: Notification) {
        LoginManager.goToLogin()
    }
    
    func showThankYouPage(){
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
        }
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoading()
        
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCellIdentifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if postManager.currentPosts.indices.contains(indexPath.row) {
            let post = self.postManager.currentPosts[indexPath.row]
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.recordAction(.Tap, sourceRef: "\(post.postId)", sourceType: .Post, targetRef: "Post-Detail", targetType: .View)
            }
            let postDetailController = PostDetailViewController(postId: post.postId)
            postDetailController.post = post
            self.navigationController?.push(postDetailController, animated: true)
        }
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    // MARK: - UIScrollView Delegate
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customPullToRefreshView?.scrollViewDidEndDragging()
    }
    
    // MARK: - UICollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == SectionType.curatorSection.rawValue { return self.curatorDatasources.count >= CuratorCollectionViewCell.MinimumCurator ? 1 : 0 }
        
        return postManager.currentPosts.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard section == SectionType.feedSection.rawValue && postManager.hasLoadMore else {
            return CGSize.zero
        }
        
        return CGSize(width: 320, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView", for: indexPath)
        
        if let footer = view as? LoadingFooterView {
            footer.activity.isHidden = !postManager.hasLoadMore
        }
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 && indexPath.row == 0 {
            let height = Constants.Ratio.CuratorViewHeight * self.view.frame.width
            return CGSize(width: self.view.frame.size.width, height: height)
        }
        if indexPath.row == postManager.currentPosts.count {
            if (postManager.hasLoadMore) {
                return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
            }
        }
        return CGSize(width: self.view.frame.size.width, height: postManager.getHeightAtIndex(indexPath))
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let defaultCell = self.getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        
        if indexPath.row == 0 && indexPath.section == 0{
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CuratorCollectionViewCell.CellId, for: indexPath) as? CuratorCollectionViewCell {
                cell.delegate = self
                cell.curatorDatasources = self.curatorDatasources
                cell.updateCurrentCurator(self.currentCurator)
                cell.analyticsViewKey = self.analyticsViewRecord.viewKey
                return cell
            }else {
                return defaultCell
            }
        }
        
        if indexPath.row == postManager.currentPosts.count - 1 && postManager.hasLoadMore{
            self.updateNewsFeed(pageNo: postManager.currentPageNumber + 1)
        }
        
        if let cell = postManager.getNewsfeedCell(indexPath) as? MyFeedCollectionViewCell {
            if !myFeedCollectionViewCells.contains(cell) {
                myFeedCollectionViewCells.append(cell)
            }
            
            
            cell.recordImpressionAtIndexPath(indexPath, positionLocation: "Newsfeed-Curator-User", viewKey: self.analyticsViewRecord.viewKey)
            return cell
        }else {
            return defaultCell
        }
        
        
    }
    
    //MARK: - Scroll View Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let scrollOffsetY = 80.0 - scrollView.contentOffset.y
        let navigationBarHeight: CGFloat = 44.0
        
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: scrollView.contentOffset.y)
        }
        
        if (scrollOffsetY < navigationBarHeight) {
            self.navigationBarVisibility = .visible
            self.title = String.localize("LB_AC_CURATOR_RECOMM")
            updateNavigationViews(isShowBackground: true)
        } else {
            self.navigationBarVisibility = .hidden
            self.title = ""
            updateNavigationViews(isShowBackground: false)
        }
    }
    
    
    func updateNavigationViews(isShowBackground: Bool) {
        if isShowBackground {
            if buttonCart != nil {
                buttonCart?.setImage(UIImage(named: "create_post_grey"), for: UIControlState())
            }
            if buttonWishlist != nil {
                buttonWishlist?.setImage(UIImage(named: "icon_heart_stroke"), for: UIControlState())
            }
            searchButton.setImage(UIImage(named: "search_grey"), for: UIControlState())
        } else {
            if buttonCart != nil {
                buttonCart?.setImage(UIImage(named:"create_post_white"), for: UIControlState())
            }
            if buttonWishlist != nil {
                buttonWishlist?.setImage(UIImage(named: "heart"), for: UIControlState())
            }
            searchButton.setImage(UIImage(named: "search_wht"), for: UIControlState())
        }
    }
    
    func setupNavigationBar() {
        
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        setupNavigationBarSearchButton()
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)
        
        buttonCart?.accessibilityIdentifier = UIComponentKey.NavigationBar.Item.CartButton
        buttonWishlist?.accessibilityIdentifier = UIComponentKey.NavigationBar.Item.WishListButton
        
        if let cartButton = self.buttonCart {
            if let wishlistButton = self.buttonWishlist {
                let rightButtonItems = [
                    UIBarButtonItem(customView: cartButton),
                    UIBarButtonItem(customView: wishlistButton)
                ]
                self.navigationItem.rightBarButtonItems = rightButtonItems
            }
        }
        
        updateNavigationViews(isShowBackground: false)
    }
    
    func setupNavigationBarSearchButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        searchButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        searchButton.setImage(UIImage(named: "search_wht"), for: UIControlState())
        searchButton.addTarget(self, action: #selector(StyleFeedController.searchIconClicked), for: UIControlEvents.touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: searchButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    // MARK: - Handle animations
    @objc func startAllAnimations() {
        for cell in myFeedCollectionViewCells {
            cell.resetAnimation()
        }
    }
    
    @objc func stopAllAnimations() {
        for cell in myFeedCollectionViewCells {
            cell.stopAnimation()
        }
    }
    
    //MARK: - Curator Methods
    func fetchCuratorsList(_ isShowLoading : Bool = true) -> Void {
        firstly{
            return self.getCuratorDatasources()
        }.then{  (_) -> Promise<[User]> in
            return FollowService.listFollowingUsers(.getCuratorOnly, start: 0, limit: Constants.Paging.All)
        }.then {  users -> Void in
            self.mixRecommendListAndFollowingList(users)
            self.collectionView.reloadData()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func mixRecommendListAndFollowingList(_ followingCurators: [User]){
        var recommendedCurator = [Curator]()
        for user in curatorDatasources{
            let followingUsers = followingCurators.filter({$0.userKey == user.userKey})
            if followingUsers.count == 0 && !FollowService.instance.cachedFollowingUserKeys.contains(user.userKey) && user.userKey != Context.getUserKey()  {
                recommendedCurator.append(user)
            }
        }
        self.curatorDatasources = recommendedCurator
    }
    
    func getCuratorDatasources() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.getRecommendedList (start: 0, limit: Constants.Paging.Curator, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let curatorList:[Curator] = Mapper<Curator>().mapArray(JSONObject: response.result.value) ?? []
                            strongSelf.curatorDatasources = curatorList
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                    
                }
                })
        }
        
        
    }
    
    private var hasToPushToCuratorList = false
    
    func pushToCuratorList() {
        hasToPushToCuratorList = true
    }
    
    //MARK: - Curator Cell Delegate
    func curatorCellDidSelectSeeAllCuratorButton() {
        let viewController = FilterCuratorsViewController()
        if let naviController = Utils.findActiveNavigationController() {
            naviController.push(viewController, animated: true)
        }
        
    }
    
    func curatorCellDidTapOnCuratorImageProfile(_ item: Curator) {
        let publicProfileVC = CuratorProfileViewController()
        publicProfileVC.currentType = (item.userKey == Context.getUserKey()) ? .Private : .Public
        
        let user = User()
        user.userKey = item.userKey
        user.userName = item.userName
        user.isCurator = 1
        publicProfileVC.publicUser =  user
        if item.userKey == Context.getUserKey() {
            publicProfileVC.user = user
        }
        if let naviController = Utils.findActiveNavigationController() {
            naviController.push(publicProfileVC, animated: true)
        }
        
    }
    
    func curatorCellDidAnimateToCuratorProfile(_ item: Curator) {
        self.currentCurator = item
        
        //record impression
        if let cell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: SectionType.curatorSection.rawValue)){
            if let viewKey = cell.analyticsViewKey{
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: item.userKey, impressionType: "Curator", impressionDisplayName: item.displayName, positionComponent: "RecommendedCuratorListing", positionIndex: ((curatorDatasources.index(of: item) ?? 0) + 1), positionLocation: "Newsfeed-Curator-User", viewKey: viewKey))
                
                //record swipe action
                cell.recordAction(.Slide, sourceRef: "\(item.userKey)", sourceType: .Curator, targetRef: "\(item.userKey)", targetType: .Curator)
            }
        }
    }

    func curatorCellShowLoading() {
        self.showLoading()
    }
    
    func curatorCellStopLoading() {
        self.stopLoading()
    }
    
    func curatorCellHandleApiResponseError(_ apiResponse: ApiResponse, errorCode: Int) {
        self.handleApiResponseError(apiResponse: apiResponse, statusCode: errorCode)
    }
    
    
    func showFollowSuccessPopUp() {
        self.showSuccessPopupWithText(String.localize("MSG_SUC_FOLLOWED"))
    }
    
    func updateNewsFeed(pageNo: Int){
        if isUpdatingNewFeeds {
            return
        }
        isUpdatingNewFeeds = true
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return self.postManager.fetchNewsFeed(.styleFeed, pageno: pageNo)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Void in
                self.collectionView.reloadData()
            }.always {
                super.stopLoading()
                self.isUpdatingNewFeeds = false
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: String.localize("LB_CA_CURATOR_ALL"),
            viewParameters: nil,
            viewLocation: "Newsfeed-Curator-User",
            viewRef: Context.getUserKey(),
            viewType: "Newsfeed"
        )
    }
    
    //MARK: Handle update following event
    @objc func followingDidUpdate() {
        needReloadData = true
    }
    
    override func refresh() {
        self.loadBaseData()
    }
    
    @objc func didReceiveScreenCapNotification(_ notification: Notification){
        self.postManager.sharePost()
    }
}

extension StyleFeedController : PullToRefreshViewUpdateDelegate{
    func didEndPullToRefresh() {
        self.loadBaseData()
    }
}

extension StyleFeedController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
