//
//  MerchantDetailViewController.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/10/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import CSStickyHeaderFlowLayout
import Alamofire
import Kingfisher

class MerchantDetailViewController: MmViewController, UINavigationControllerDelegate, HeaderMerchantProfileDelegate {
    
    private enum SectionType: Int {
        case productInfoSection = 0
        case newsFeedSection = 1
        case categoriesSection = 2
    }
    
    final let WidthItemBar: CGFloat = 25
    final let HeightItemBar: CGFloat = 25
    final let DefaultUIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    final let HeaderProfileIdentifier = "HeaderMerchantProfileView"
    private final let PostItemCollectionViewCellIdentifier = "PostItemCollectionViewCell"
    final let CellId = "Cell"
    final let HeightCellMyProfile: CGFloat = Constants.ScreenSize.SCREEN_WIDTH * Constants.Ratio.PanelImageHeight + 200.0
    final let colorBarItemBackup = UIColor()
    final let WidthLogo: CGFloat = 120.0
    final let HeightLogo: CGFloat = 35.0

    var searchBarButtonItem: UIBarButtonItem!
    var buttonSearch: UIButton?
    var buttonBack = UIButton()
    var backButtonItem = UIBarButtonItem()
    var imageViewLogo: UIImageView?
    var header: HeaderMerchantProfileView?
    
    var merchant: Merchant?
	
    weak var delegateMerchantProfile: HeaderMerchantProfileDelegate?
    var mode: DescriptionMode?
    
    var isFromUserChat = false
    var relationShip = Relationship()
    var isFollowing = false
    
    var paidOrder: ParentOrder?
    
    private var myFeedCollectionViewCells = [MyFeedCollectionViewCell]()
    var customPullToRefreshView: PullToRefreshUpdateView?
    private var layout: CSStickyHeaderFlowLayout? {
        return self.collectionView?.collectionViewLayout as? CSStickyHeaderFlowLayout
    }
    
    var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
    
    var postManager : PostManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backupButtonColorOn()
        configCollectionView()
        setupNavigationProfile()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.updateViewConstraints()
        
        if LoginManager.getLoginState() == .validUser {
			self.updateMerchantViewWithRefreshedData()
        } else {
            self.updateMerchantViewForGuestUser()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(MerchantDetailViewController.removeLogo), name: Constants.Notification.removeProfileNavBarLogo, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startAllAnimations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAllAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        startAllAnimations()
        
        if self.navigationBarVisibility == .visible {
            addLogoOnNavi()
        }
        
        if let merchantId = self.merchant?.merchantId {
            showLoading()
            postManager = PostManager(postFeedTyle: .merchantFeed, merchantId: merchantId, collectionView: self.collectionView, viewController: self)
			
            updateNewsFeed(pageno: 1)
        }
    }
    	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopAllAnimations()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.removeProfileNavBarLogo, object: nil)
		
		if self.navigationBarVisibility == .visible {
			removeLogo()
		}
    }

    // MARK: - setup UI
    
    func configCollectionView() {
        self.collectionView.backgroundColor = UIColor.primary2()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight)
        let flowLayout = CSStickyHeaderFlowLayout()
        flowLayout.disableStickyHeaders = true
        flowLayout.parallaxHeaderReferenceSize = CGSize.zero
        self.collectionView.setCollectionViewLayout(flowLayout, animated: false)
        self.collectionView.bounces = true
        // Setup Cell
        self.collectionView.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: PostItemCollectionViewCellIdentifier)
        self.collectionView.register(PostItemCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.layout?.itemSize = CGSize(width: self.view.frame.size.width, height: 44)
        
        // Setup Header
        self.collectionView?.register(HeaderMerchantProfileView.self, forSupplementaryViewOfKind: CSStickyHeaderParallaxHeader, withReuseIdentifier: HeaderProfileIdentifier)
        self.layout?.parallaxHeaderReferenceSize = CGSize(width: self.view.frame.size.width, height: HeightCellMyProfile)
		self.layout?.parallaxHeaderMinimumReferenceSize = CGSize(width: self.view.frame.size.width, height: HeightCellMyProfile)
        
        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x: (self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 435.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        customPullToRefreshView?.delegate = self
        self.collectionView.addSubview(customPullToRefreshView!)
    }
    
    func setupNavigationProfile() {
        setupNavigationBarButtons()
    }
		
    func setupNavigationBarButtons() {
        setupNavigationBarCartButton()
        setupNavigationBarWishlistButton()
        setupBarButtons()
        var rightButtonItems = [UIBarButtonItem]()
        rightButtonItems.append(UIBarButtonItem(customView: buttonCart!))
        rightButtonItems.append(UIBarButtonItem(customView: buttonWishlist!))
        
        buttonCart?.addTarget(self, action: #selector(self.goToShoppingCart), for: .touchUpInside)
        buttonWishlist?.addTarget(self, action: #selector(self.goToWishList), for: .touchUpInside)
        
        self.backButtonItem = self.createBack("back_wht", selector: #selector(MerchantDetailViewController.onBackButton), size: CGSize(width: Constants.Value.BackButtonWidth,height: Constants.Value.BackButtonHeight), left: -36, right: 0)
        self.searchBarButtonItem = backButtonItem
        let searchButtonItem = UIBarButtonItem.createSearchBarButton("search_wht", selectorName: "searchIconClicked", target:self, size: CGSize(width: WidthItemBar,height: 24), left: -41, right: 0)
        if let searchButton = searchButtonItem.customView as? UIButton {
            self.buttonSearch = searchButton
        }
        var leftButtonItems = [UIBarButtonItem]()
        leftButtonItems.append(backButtonItem)
        leftButtonItems.append(searchButtonItem)
        
        self.navigationItem.rightBarButtonItems = rightButtonItems
        self.navigationItem.leftBarButtonItems = leftButtonItems
    }
    
	
    func createBack(_ imageName: String, selector: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        buttonBack.setImage(UIImage(named: imageName), for: UIControlState())
        buttonBack.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        buttonBack .addTarget(self, action: selector, for: UIControlEvents.touchUpInside)
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = buttonBack
        return temp
    }
	
    func backupButtonColorOn() {
        buttonCart?.setImage(UIImage(named: "cart_grey"), for: UIControlState())
        buttonWishlist?.setImage(UIImage(named: "icon_heart_stroke"), for: UIControlState())
        buttonSearch?.setImage(UIImage(named: "search_grey"), for: UIControlState())
        buttonBack.setImage(UIImage(named: "back_grey"), for: UIControlState())
        
        if merchant != nil {
            addLogoOnNavi()
        } else {
            self.title = ""
        }
    }
	
    func setupBarButtons() {
        if buttonCart != nil {
            buttonCart?.setImage(UIImage(named:"shop"), for: UIControlState())
        }
        if buttonWishlist != nil {
            buttonWishlist?.setImage(UIImage(named: "heart"), for: UIControlState())
        }
        if searchBarButtonItem != nil {
            buttonSearch?.setImage(UIImage(named: "search_wht"), for: UIControlState())
        }
        buttonBack.setImage(UIImage(named: "back_wht"), for: UIControlState())
        removeLogo()
    }
	
    func addLogoOnNavi() {
		removeLogo()
		
        imageViewLogo = UIImageView(frame: CGRect(x: (self.view.frame.width - WidthLogo)/2, y: 0, width: WidthLogo, height: HeightLogo))

        setDataImageviewLogo(merchant!.headerLogoImage)
        imageViewLogo?.tag = 99
        self.navigationItem.titleView = imageViewLogo!
    }
	
	func setDataImageviewLogo(_ key: String) {
        imageViewLogo?.mm_setImageWithURL(ImageURLFactory.URLSize512(merchant!.headerLogoImage, category: .merchant), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: nil)
    }
	
	@objc func removeLogo() {
        self.navigationItem.titleView = nil
    }

	func originY() -> CGFloat {
        var originY:CGFloat = 0
        let application: UIApplication = UIApplication.shared
        
        if application.isStatusBarHidden {
            originY = application.statusBarFrame.size.height
        }
        return originY
    }
	
	//MARK: - action button bar
    
    @objc func onBackButton() {
        self.navigationController?.popViewController(animated: true)
    }

	func searchIconClicked() {
		let searchViewController = ProductListSearchViewController()
		self.navigationController?.push(searchViewController, animated: false)
    }
    
    //MARK: - Delegate & Datasource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sectionType = SectionType(rawValue: section) {
            switch sectionType {
            case .productInfoSection:
                return 2
            case .newsFeedSection:
                return (merchant != nil && postManager.currentPosts.count > 0) ? postManager.currentPosts.count + (postManager.hasLoadMore ? 1 : 0) : 0
            case .categoriesSection:
                return 1
            }
        }
        
        return 0
    }
	
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let sectionType = SectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .productInfoSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PostItemCollectionViewCell
                cell.backgroundColor = UIColor.white
                switch(indexPath.row) {
                case 0:
                    cell.setupDataDummy("merchant_banner")
                    break
                case 1:
                    cell.setupDataDummy("new_product")
                    break
                default:
                    break
                }
                return cell
            case .newsFeedSection:
                if indexPath.row == postManager.currentPosts.count {
                    let cell = loadingCellForIndexPath(indexPath)
                    if (!postManager.hasLoadMore) {
                        cell.isHidden = true
                    } else {
                        cell.isHidden = false
                        
                        self.updateNewsFeed(pageno: postManager.currentPageNumber + 1)
                    }
                    return cell
                }
                
                let cell = postManager.getNewsfeedCell(indexPath) as! MyFeedCollectionViewCell
                
                if !myFeedCollectionViewCells.contains(cell) {
                    myFeedCollectionViewCells.append(cell)
                }
                
                return cell
            case .categoriesSection:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PostItemCollectionViewCell
                cell.backgroundColor = UIColor.white
                cell.setupDataDummy("feature_cat")
                return cell
            }
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PostItemCollectionViewCell
        cell.backgroundColor = UIColor.white
        cell.setupDataDummy("feature_cat")
        return cell
    }
	
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
        return cell
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return PostManager.NewsFeedLineSpacing
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return DefaultUIEdgeInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let sectionType = SectionType(rawValue: indexPath.section) {
            switch sectionType {
            case .productInfoSection:
                switch indexPath.row {
                case 0:
                    return CGSize(width: self.view.frame.size.width, height: 218.0)
                case 1:
                    return CGSize(width: self.view.frame.size.width, height: 338.0)
                default:
                    return CGSize(width: self.view.frame.size.width, height: 0.0)
                }
            case .newsFeedSection:
                if indexPath.row == postManager.currentPosts.count {
                    if (postManager.hasLoadMore) {
                        return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
                    }
                }
                
                return CGSize(width: self.view.frame.size.width, height: postManager.getHeightAtIndex(indexPath))
            case .categoriesSection:
                return CGSize(width: self.view.frame.size.width, height: 168.0)
            }
        }
        
        return CGSize(width: self.view.frame.size.width, height: 0.0)
        
    }
	
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == CSStickyHeaderParallaxHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderProfileIdentifier, for: indexPath)
            header = (view as! HeaderMerchantProfileView)
            header?.configDataWithMerchant(merchant!,isFollowing: self.isFollowing)
            header?.delegateMerchantProfile = self
            return header!
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 0.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 0.0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollOffsetY = 80.0 - scrollView.contentOffset.y
        
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: scrollView.contentOffset.y)
        }
        
        if (scrollOffsetY < 44.0) {
            self.navigationBarVisibility = .visible
            backupButtonColorOn()
        } else {
            self.navigationBarVisibility = .hidden
            setupBarButtons()
        }
    }
    
    func reloadDataSource() {
        self.collectionView.reloadData()
    }
    
    //MARK: - handle data
    
    func updateMerchantView() {
		guard merchant != nil else { return }
		
        self.showLoading()
        firstly {
            
            return self.fetchMerchant(merchant!)
        }.then { _ -> Void in
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return self.checkMerchant(self.merchant!)
        }.then { _ -> Void in
            self.reloadDataSource()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }

	func updateMerchantViewForGuestUser(){
		guard merchant != nil else { return }
		
		self.showLoading()
		firstly {
			// update inventory location if needed
			// if it is not updated, it will return success without api call
			return self.fetchMerchant(merchant!)
        }.then { _ -> Void in
            self.reloadDataSource()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
		}
	}

	func updateMerchantViewWithRefreshedData(){
		guard merchant != nil else { return }
		
		self.showLoading()
		firstly {
			// update inventory location if needed
			// if it is not updated, it will return success without api call
				return self.fetchMerchant(merchant!)
			}.then { _ -> Void in
				return self.checkMerchant(self.merchant!)
			}.then { _ -> Void in
				self.reloadDataSource()
			}.always {
//				self.stopLoading()
			}.catch { _ -> Void in
				Log.error("error")
		}
	}
	
    func fetchMerchant(_ merchant: Merchant) -> Promise<Any>{
        return Promise{ fulfill, reject in
            MerchantService.view(merchant.merchantId){[weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
							
                            if let array = response.result.value as? [[String: Any]], let obj = array.first , let merchant = Mapper<Merchant>().map(JSONObject: obj) {
								strongSelf.merchant = merchant
								fulfill("OK")

							} else {
								let error = NSError(domain: "", code: -999, userInfo: nil)
								reject(error)
							}
							
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
            }
        }
    }
	
    // Handle api follow merchant
    
    func unfollowMerchant(_ merchant: Merchant) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: merchant.merchantNameInvariant)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            // call api unfollow request
            firstly {
                return FollowService.requestUnfollow(merchant: merchant)
                }.then { _ -> Void in
                    merchant.followStatus = false
                    self.renderMerchantView()
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleError(apiResp, statusCode: error.code, animated: true)
                    }
            }
            }, cancelActionComplete:nil)
    }
	
    
	
    func followMerchant(_ merchant: Merchant) {
        firstly {
            return FollowService.requestFollow(merchant: merchant)
        }.then { _ -> Void in
            merchant.followStatus = true
            self.renderMerchantView()
        }.always {
            self.stopLoading()
        }.catch { error -> Void in
            Log.error("error")
            let error = error as NSError
            if let apiResp = error.userInfo["data"] as? ApiResponse {
                self.handleError(apiResp, statusCode: error.code, animated: true)
            }
        }
    }
    
	@discardableResult
    func checkMerchant(_ merchant: Merchant)-> Promise<Any> {
        return Promise{ fulfill, reject in
            RelationshipService.relationshipByMerchant(merchant.merchantId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.response?.statusCode == 200 {
                        
                        strongSelf.relationShip = Mapper<Relationship>().map(JSONObject: response.result.value)!
                        strongSelf.isFollowing = strongSelf.relationShip.isFollowing
                        self?.collectionView.reloadData()
                        fulfill("OK")
                    } else {
                        strongSelf.handleError(response, animated: true)
                    }
                }
            }
        }
    }
	
    func renderMerchantView() {
        self.collectionView.reloadData()
    }
    
    //MARK: - Delegate Header Profile
    func didSelectButtonFollow(_ sender: UIButton, status: Bool) {
		guard LoginManager.getLoginState() == .validUser else {
			NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.merchantDetail.rawValue)
			return
		}
        
		if status {
			self.unfollowMerchant(merchant!)
		} else {
			self.followMerchant(merchant!)
		}
		self.isFollowing = !status
		header?.configButtonFollow(!status)
    }
	
    func didSelectButtonShare(_ sender: UIButton) {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
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
                            let viewController = UserChatViewController(convKey: convKey)
                            let merchantModel = MerchantModel()
                            merchantModel.merchant = strongSelf.merchant
                            let chatModel = ChatModel.init(merchantModel: merchantModel)
                            chatModel.messageContentType = MessageContentType.ShareMerchant
                            
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                })
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            if let merchant = self.merchant {
                ShareManager.sharedManager.shareMerchant(merchant, method: method)
            }
            
        }
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    func didSelectButtonChat(_ sender: UIButton) {
        guard LoginManager.getLoginState() == .validUser else {
            NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.merchantDetail.rawValue)
            return
        }
        
        if let merchant = self.merchant {
            
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartToCSMessage(
                    userList: [myRole],
                    queue: .General,
                    senderMerchantId: myRole.merchantId,
                    merchantId: merchant.merchantId
                ),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                    }
                }
            )
        }
    }
    
    func didSelectFollowerList(_ gesture: UITapGestureRecognizer) {
        let merchantFollowerListViewController = MerchantFollowerListViewController()
        merchantFollowerListViewController.merchant = self.merchant!
        self.navigationController?.push(merchantFollowerListViewController, animated: true)
    }
    
    func didSelectDescriptionView(_ gesture: UITapGestureRecognizer) {
        let merchantDescriptionVC = MerchantDescriptionViewController()
        merchantDescriptionVC.merchant = self.merchant!
        merchantDescriptionVC.mode = DescriptionMode.modeMerchant
        self.navigationController?.push(merchantDescriptionVC, animated: true)
    }
    
    //MARK: Config view
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activity.center = cell.center
        var rect = activity.frame
        rect.origin.y -= 0.0
        activity.frame = rect
        cell .addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func updateNewsFeed(pageno: Int) {
        guard merchantKey != "0" else {
            return
        }
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return postManager.fetchNewsFeed(.merchantFeed, merchantId: merchant?.merchantId, pageno: pageno)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Void in
                self.reloadDataSource()
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    var merchantKey: String {
        get {
            if let merchant = self.merchant {
                return String(merchant.merchantId)
            }
            return "0"
        }
    }

    func showThankYouPage() {
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
    
    //MARK: -ScrollViewDelete
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customPullToRefreshView?.scrollViewDidEndDragging()
        
    }

}
extension MerchantDetailViewController : PullToRefreshViewUpdateDelegate {
    func didEndPullToRefresh() {
        self.updateNewsFeed(pageno: 1)
    }
}

extension MerchantDetailViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
