//
//  ProfileViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire
import AVFoundation
import SKPhotoBrowser

enum TypeProfile: Int {
    case Private = 0
    case Public
}
enum TagActionButton: Int {
    case ActionButtonTag = 100
}

struct ImageSizeCrop {
    static let width_max = CGFloat(800)
    static let height_max = CGFloat(800)
	
	static let cover_width = CGFloat(1000)
	
    static let profileCuratorWidth = CGFloat(86)
    static let profileCuratorHeight = CGFloat(100)
}

protocol ProfileViewControllerDelegate: NSObjectProtocol {
    func didUpdateUser()
}

class ProfileViewController: MmViewController,BannerCellDelegate {
    enum ProductItem: Int {
        case ShoppingCart
        case Order
        case MyCoupon
        case Wishlist
    }
    
    private final let WidthItemBar: CGFloat = 33
    private final let PlaceHolderMinHeight : CGFloat = 166
    private final let HeightItemBar: CGFloat = 33
    private final let OffsetAllowance = CGFloat(5)
    private final let DefaultUIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private final let HeaderProfileIdentifier = "HeaderMyProfileIdentifier"
    private final let HeaderCuratorIdentifier = "HeaderCuratorProfileCell"
    private final let HeaderOtherCuratorIdentifier = "HeaderOtherCuratorIdentifier"
    private final let ProfileProductsCellIdentifier = "ProfileProductsCellIdentifier"
    private final let LoadingCellIdentifier = "LoadingCellIdentifier"
    private final let PostItemCollectionViewCellIdentifier = "PostItemCollectionViewCell"
    private final let ImageCollectCellIdentifier = "ImageCollectCell"
    private final let idDefault = "CellId"

//    private final let CellId = "Cell"
    private final let HeightCellMyProfile: CGFloat = 256.0
    private final let colorBarItemBackup = UIColor()
    private final let NotiHasAvatar = "NotiHasAvatar"
    
    weak var delegate : ProfileViewControllerDelegate?
    var user = User()
    var publicUser = User()
    var brands: [Brand] = []
    var curators: [User] = []
    var followedUsers: [User] = []
    var followingUsers: [User] = []
    let settingButton = UIButton(type: .custom)
    var messageBtn: ButtonRedDot? = nil
    
    var picker = UIImagePickerController()
    var profileImage = UIImage()
    var avatarImage = UIImageView()
    var isTapAvatar: Bool = false
    var coverImage = UIImage()
    var coverImageView = UIImageView()
    var isRefresh: Bool = false
    var currentType: TypeProfile = .Private
    var buttonBack = UIButton()
    var buttonSearch = UIButton()
    var profileHeader: HeaderMyProfileCell?

    var userType = UserType.UserNormal

    var relationShip: Relationship?
    var isFriend: StatusFriend?
    var floatingActionButton: MMFloatingActionButton?
	
	var profileBtn: UIButton?
    var paidOrder: ParentOrder?
    var aliasDidSave:(() -> Void)?
    var dimBackground: UIView?
    var isFromChat = false

	var addFriendBtn: UIButton?

    var isFromPostComment = false
    
    private var myFeedCollectionViewCells = [UICollectionViewCell]()
    private var heightHeaderProfile : CGFloat = 0
    var customPullToRefreshView: PullToRefreshUpdateView?
    private var profileMemberCardCell: ProfileMemberCardCell?
    
    private var banners : [Banner]?
    private var generalBannerCell: BannerCell?
    private var isPresentingViewController = false
    private var lastPositionY = CGFloat(0)
    
    //Analytics
    var actionTargetType = AnalyticsActionRecord.ActionElement.User
	private enum UserProfileSection: Int {
		case Header
        case FirstLine
        case MemberCard
        case InviteFriend
        case SecondLine
        case Banner
		case Feed
        
        static func count() -> Int{
            return UserProfileSection.Feed.rawValue + 1
        }
	}
    
	//var pullToRefreshView = UIView()
    //var pullToRefreshIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    //var isPullingToRefresh = false
    var isNeedHookPostManager = false
    var isFirstStart = true
    
    
    private var postManager: PostManager!
    
    var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .lightContent
        }
    }
	
	var profileUserKey: String {
		get {
			if currentType == .Private {
				return Context.getUserKey()
			} else {
				return publicUser.userKey
			}
		}
	}
	
    var userName: String{
        get {
            if currentType == .Private {
                return Context.getUsername()
            } else {
                return publicUser.userName
            }
        }
    }
    
    var isLoggingViewRecord = false
    var viewHeader:UICollectionReusableView?
    var isLoadedUserInfo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configImageViewer()
        super.pageAccessibilityId = "MyProfilePage"
        self.automaticallyAdjustsScrollViewInsets = true
		
        if self.publicUser.userKey == Context.getUserKey() {
            currentType = TypeProfile.Private
        }

        backupButtonColorOn()
        configCollectionView()
        setupNavigationBarButtons()
        setupPicker()
        addObserverGetAvatar()
        
        
        setUserType()
        loadBannersData()
        postManager = PostManager(postFeedTyle: .userFeed, authorKey: profileUserKey, collectionView: self.collectionView, viewController: self) 
        let userKey = profileUserKey
        if userKey.length > 0 {
//            postManager.hookPostManager(postFeedType: .UserFeed, authorKey: profileUserKey, collectionView: self.collectionView, viewController: self)
        } else {
            isNeedHookPostManager = true
        }
        
        if currentType == .Private{
            initAnalyticLog()
        }
        
        
        if currentType == TypeProfile.Private {
            updateUserView()
        } else {
            updateUserPublicProfile()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            if self.profileUserKey.length > 0 {
                self.updateNewsFeed(pageno: 1)
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		
		NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.showQRCode), name: Constants.Notification.showQRCodeOnProfileView, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.closeQRCode), name: Constants.Notification.closeQRCodeOnProfileView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.changeAlias), name: Constants.Notification.changeAliasOnProfileView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.aliasBeginEditting), name: Constants.Notification.aliasBeginEditting, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(self.startAllAnimations), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAllAnimations), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveScreenCapNotification(notification:)), name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        
        startAllAnimations()
		
		self.navigationController?.updateViewConstraints()
		
//        styleActionButton()
		
		if profileHeader != nil {
            self.avatarImage = profileHeader!.imageViewAvatar
            self.coverImageView = profileHeader!.coverImageView
		}
        if currentType == TypeProfile.Private {
            user = Context.getUserProfile()
        }
        getUserLoyaltyStatus({ [weak self] (loyalty) in
            if let strongSelf = self, let loyalty = loyalty{
                strongSelf.user.loyalty = loyalty
            }
            }, failure: { [weak self] (errorType) in
                if let strongSelf = self{
                    strongSelf.stopLoading()
                }
            })
        
        self.reloadData()
        
        if let navigationController = self.navigationController as? MmNavigationController {
            if self.navigationBarVisibility == .visible {
                self.navigationItem.title = user.displayName
            } else {
                self.navigationItem.title = ""
            }
            navigationController.setNavigationBarVisibility(offset: self.collectionView.contentOffset.y)
        }
	}
	
    override func refresh() {
        self.loadBannersData()
        if currentType == TypeProfile.Private {
            updateUserView()
        } else {
            updateUserPublicProfile()
        }
        self.updateNewsFeed(pageno: 1)
        
        if let viewHeader = self.viewHeader{
            //log refresh action
            let user = self.currentUser()
            viewHeader.recordAction(.Refresh, sourceRef: user.userKey, sourceType: .View, targetRef: user.userKey, targetType: .View)
        }
    }
    
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		removeActionButton()
		
		stopAllAnimations()
		
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.showQRCodeOnProfileView, object: nil)
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.closeQRCodeOnProfileView, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.changeAliasOnProfileView, object: nil)
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.aliasBeginEditting, object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        isPresentingViewController = false
		//        PostManager.sharedManager.unhookPostManager()
        
        dismissKeyboard()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
//        UIApplication.shared.statusBarStyle = .default
	}

	override func showLoading() {
		super.showLoading()
		
		DispatchQueue.main.async {
			self.floatingActionButton?.isHidden = true
		}
	}
	
	override func stopLoading() {
		super.stopLoading()
		
		DispatchQueue.main.async {
			self.floatingActionButton?.isHidden = false
		}
	}
    
    func shareUser() {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                    checkNetwork: true,
                    viewController: strongSelf,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            
                            let userModel = UserModel()
                            userModel.user = strongSelf.user
                            let chatModel = ChatModel.init(userModel: userModel)
                            chatModel.messageContentType = MessageContentType.ShareUser
                            
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        }
                    }
                )
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            ShareManager.sharedManager.shareUser(self.user, method: method)
            
        }
        self.present(shareViewController, animated: false, completion: nil)
    }
	
    @objc
	func showQRCode() {
		MyQRCodeViewController.presentQRCodeController(self)
		self.floatingActionButton?.isHidden = true
	}

    @objc
	func closeQRCode() {
		self.floatingActionButton?.isHidden = false
	}
    
    @objc
    func changeAlias() {
        aliasDidSave?()
    }

	@objc func refreshNewsFeedPost() {
		self.reloadData()
	}
    
    @objc
    func aliasBeginEditting() {
        if dimBackground == nil {
            dimBackground = { () -> UIView in
                let view = UIView(frame: self.view.frame)
                view.backgroundColor = UIColor.black
                view.alpha = 0.5
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
                return view
            }()
        }

        self.collectionView.addSubview(dimBackground!)
        self.collectionView.bringSubview(toFront: profileHeader!)
        
        if let header = self.profileHeader {
            header.addDimBackgroundWithOffset(self.collectionView.contentOffset.y)
        }
    }

    @objc func dismissKeyboard() {
        if let view = dimBackground {
            view.removeFromSuperview()
        }

        if let header = self.profileHeader {
            header.dismissKeyboard()
        }
    }
    
    // MARK: - setup UI
    
    func setUserType() {
        if publicUser.isCurator == 1 {
            self.userType = .CuratorType
        }
    }
    
    func styleActionButton() {
        let createButton: (CGRect) -> MMFloatingActionButton = { (frame) in
            if self.floatingActionButton == nil {
                self.floatingActionButton = MMFloatingActionButton(frame: frame)
                self.floatingActionButton!.mmFloatingActionButtonDelegate = self
                self.floatingActionButton!.tag = TagActionButton.ActionButtonTag.rawValue
                self.floatingActionButton!.transform = CGAffineTransform.identity
            }
            return self.floatingActionButton!
        }
        
        switch currentType {
        case .Private:
            let floatingFrame = CGRect(x: self.view.frame.width - Constants.Value.WidthActionButton - Constants.Value.MarginActionButton, y: self.view.frame.height - Constants.Value.WidthActionButton - Constants.Value.MarginActionButton - self.tabBarHeight, width: Constants.Value.WidthActionButton, height: Constants.Value.WidthActionButton)
            let bottomActionButton = createButton(floatingFrame)
//            let mainView = UIApplication.shared.delegate?.window
//            mainView!!.addSubview(bottomActionButton)
            self.view.addSubview(bottomActionButton)
            if let button = self.floatingActionButton {
                button.frame = floatingFrame
            }
        default:
            break
        }
    }
    
    func removeActionButton() {
        if self.floatingActionButton != nil {
            self.floatingActionButton?.removeFromSuperview()
            self.floatingActionButton = nil
        }
    }
    
    func configCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.frame = CGRect(x: 0 , y: 0, width: self.view.bounds.width, height: self.view.bounds.height - tabBarHeight)
        self.collectionView.backgroundColor = UIColor.feedCollectionViewBackground()
        self.collectionView.contentInset = UIEdgeInsets(top: -StartYPos, left: 0, bottom: 0, right: 0)
        
        // Setup Cell
        
        self.collectionView.register(MyFeedCollectionViewCell.self, forCellWithReuseIdentifier: PostItemCollectionViewCellIdentifier)
        self.collectionView.register(ProfileProductsCell.self, forCellWithReuseIdentifier: ProfileProductsCellIdentifier)
        self.collectionView.register(ProfileMemberCardCell.self, forCellWithReuseIdentifier: ProfileMemberCardCell.CellIdentifier)
        self.collectionView.register(ProfileInviteFriendCell.self, forCellWithReuseIdentifier: ProfileInviteFriendCell.CellIdentifier)
        self.collectionView.register(ImageCollectCell.self, forCellWithReuseIdentifier: ImageCollectCellIdentifier)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: LoadingCellIdentifier)
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.CellIdentifier)
        self.collectionView.register(PlaceHolderCell.self, forCellWithReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: idDefault)
        
        
        // Setup Header
        self.collectionView?.register(HeaderMyProfileCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderProfileIdentifier)
        self.collectionView?.register(HeaderCuratorProfileView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: HeaderCuratorIdentifier)

        heightHeaderProfile = self.view.width * Constants.Ratio.PanelImageHeight
        
        customPullToRefreshView = PullToRefreshUpdateView(frame: CGRect(x:(self.collectionView.frame.width - Constants.Value.PullToRefreshViewHeight) / 2, y: 435.0, width: Constants.Value.PullToRefreshViewHeight, height: Constants.Value.PullToRefreshViewHeight), scrollView: self.collectionView)
        customPullToRefreshView?.delegate = self
        self.collectionView.addSubview(customPullToRefreshView!)
        
        // Setup Footer
        self.collectionView.register(FooterMyProfileCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "myFooterView")
        
        self.setAccessibilityIdForView("UI_POST_FEED", view: self.collectionView)
        
        if let layout = collectionView.collectionViewLayout as? PinterestLayout {
            layout.delegate = self
        }
        collectionView.bounces = true
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        let layout = PinterestLayout()
        layout.delegate = self
        return layout
    }
    
    func setupNavigationBarButtons() {
        setupBarButtons()
        settingButton.addTarget(self, action: #selector(onSettingButton), for: .touchUpInside)
        let rightButtonItem = UIBarButtonItem.messageButtonItem(self, action: #selector(self.openChatView))
        self.messageBtn = rightButtonItem.customView as? ButtonRedDot
        self.navigationItem.rightBarButtonItems = [rightButtonItem, UIBarButtonItem(customView: shareButton)]

        if (self.navigationController?.viewControllers.count)! > 1 {
            createBackButton(.whiteColor)
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: settingButton)
        }
        // add handle on tap avatar image for iphone 5 screen
        createProfileButton()
    }
    
    func createAddFriendBarButton() -> UIBarButtonItem {
		
		let button = UIButton(type: .custom)
		button.setImage(UIImage(named: "addFriend_icon_wht"), for: .normal)
		button.frame = CGRect(x:0, y: 0, width: WidthItemBar, height: HeightItemBar)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -13, bottom: 0, right: 0)
		button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(ProfileViewController.addFriendButtonClicked), for: .touchUpInside)
		button.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
		addFriendBtn = button
		
		let temp:UIBarButtonItem = UIBarButtonItem()
		temp.customView = addFriendBtn
		return temp

    }
	
	func createProfileButton() {
		if UIScreen.main.bounds.size.width <= 320 && (self.collectionView.contentOffset.y < 44.0) {
			profileBtn = UIButton(type: .custom)
			profileBtn!.frame = CGRect(x: 0, y: 0, width: (self.navigationController?.navigationBar.frame.size.width)!/3, height: (self.navigationController?.navigationBar.frame.size.height)!/2)
			profileBtn!.setTitleColor(UIColor.black, for: UIControlState.normal)
			profileBtn!.titleLabel?.font = UIFont(name: profileBtn!.titleLabel!.font!.fontName, size: 14)
			profileBtn!.addTarget(self, action: #selector(ProfileViewController.onTapAvatarView), for: UIControlEvents.touchUpInside)
			self.navigationItem.titleView = profileBtn
		}
	}
	
    func createBack(imageName: String, selector: Selector, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        buttonBack.setImage(UIImage(named: imageName), for: .normal)
        buttonBack.frame = CGRect(x:0, y: 0, width: size.width, height: size.height)
        let verticalPadding = (size.height - Constants.Value.BackButtonHeight)/2
        buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: verticalPadding, left: left, bottom: verticalPadding, right: right)
        buttonBack.addTarget(self, action: selector, for: UIControlEvents.touchUpInside)
        buttonBack.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = buttonBack
        return temp
    }
    
    func createSearchButton(imageName: String, selectorName: String, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        buttonSearch.setImage(UIImage(named: imageName), for: .normal)
        buttonSearch.frame = CGRect(x:0, y: 0, width: size.width, height: size.height)
        buttonSearch.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        buttonSearch .addTarget(self, action:Selector(selectorName), for: UIControlEvents.touchUpInside)
        
        let temp:UIBarButtonItem = UIBarButtonItem()
        temp.customView = buttonSearch
        return temp
    }
    
    func backupButtonColorOn() {
        self.messageBtn?.setImage(UIImage(named: "message"), for: .normal)
        self.shareButton.setImage(UIImage(named: "share_black-1"), for: .normal)
        settingButton.setImage(UIImage(named: "setting_btn"), for: .normal)
        buttonBack.setImage(UIImage(named: "back_grey"), for: .normal)
        buttonSearch.setImage(UIImage(named: "ic_search_black"), for: .normal)
		addFriendBtn?.setImage(UIImage(named: "addFriend_icon"), for: .normal)
    }
    
    func setupBarButtons() {
        self.messageBtn?.setImage(UIImage(named: "meassage_white"), for: .normal)
        self.shareButton.setImage(UIImage(named: "share_white-1"), for: .normal)
        buttonBack.setImage(UIImage(named: "back_wht"), for: .normal)
        buttonSearch.setImage(UIImage(named: "search_white"), for: .normal)
		settingButton.setImage(UIImage(named: "setting_btn_wht"), for: .normal)
		addFriendBtn?.setImage(UIImage(named: "addFriend_icon_wht"), for: .normal)
    }
    
    func setupPicker() {
        picker.delegate = self
    }
    
    func addObserverGetAvatar() {
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getImageAvatar(notification:)), name:NSNotification.Name(NotiHasAvatar), object: nil)
    }
    
    @objc func getImageAvatar(notification: Notification) {
        let imageViews = notification.object as! NSArray
        self.avatarImage = imageViews[0] as! UIImageView
        self.coverImageView = imageViews[1] as! UIImageView
    }
    
    func originY() -> CGFloat {
        var originY:CGFloat = 0;
        let application: UIApplication = UIApplication.shared
        if (application.isStatusBarHidden) {
            originY = application.statusBarFrame.size.height
        }
        return originY;
    }
    
    //MARK: - action button bar
    @objc private func openChatView() {
        Navigator.shared.dopen(Navigator.mymm.imLanding)
    }
    
    // Public profile actioin 
    @objc func onBackButton() {
        self.navigationController?.popViewController(animated:true)
    }
    
    func searchIconClicked() {
		let searchViewController = ProductListSearchViewController()
		self.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    @objc func onSettingButton() {
        settingButton.recordAction(.Tap, sourceRef: "MySetting", sourceType: .Button, targetRef: "MySetting", targetType: .View)
        Navigator.shared.dopen(Navigator.mymm.setting)
    }
    
    @objc func addFriendButtonClicked() {
        if let addFriendBtn = self.addFriendBtn {
            addFriendBtn.recordAction(.Tap, sourceRef: "AddUser", sourceType: .Button, targetRef: "AddUser", targetType: .View)
        }
        self.navigationController?.pushViewController(AddFriendViewController(), animated: true)
    }
    
    //MARK: - Delegate & Datasource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if postManager.displayingObjectKey == profileUserKey {
            return UserProfileSection.count()
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case UserProfileSection.Header.rawValue:
            if currentType == .Private {
                return 1
            }
            return 0
        case UserProfileSection.FirstLine.rawValue:
            if currentType == .Private {
                return 1
            }
            return 0
        case UserProfileSection.SecondLine.rawValue:
            if currentType == .Private {
                return 1
            }
            return 0
        case UserProfileSection.Banner.rawValue:
			if currentType == .Private {
				return 1
			}
            return 0
            
        case UserProfileSection.MemberCard.rawValue:
            if currentType == .Private {
                return 1
            }
            return 0

        case UserProfileSection.InviteFriend.rawValue:
            return Constants.SNSFriendReferralEnabled && currentType == .Private ? 1 : 0
            
        case UserProfileSection.Feed.rawValue:
            if postManager.currentPosts.count == 0 {
                return 1
            }
            return postManager.currentPosts.count + (postManager.hasLoadMore ? 1 : 0)
            
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case UserProfileSection.Header.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileProductsCellIdentifier, for: indexPath) as! ProfileProductsCell
            
            let cartNum = CacheManager.sharedManager.numberOfCartItems()
            if cartNum > 0 {
                cell.showCartBadge(show: true, number: cartNum)
            } else {
                cell.showCartBadge(show: false)
            }
            
            cell.showCouponRedDot(show: CacheManager.sharedManager.hasNewClaimedCoupon)
            cell.showWishlistRedDot(show: CacheManager.sharedManager.hasWishListItem())
            
            cell.actionTapHandler = { [weak self] index in
                
                if let strongSelf = self {
                    
                    switch index {
                    case ProductItem.ShoppingCart.rawValue:
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            cell.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey)
                            cell.recordAction(.Tap, sourceRef: "Cart", sourceType: .Button, targetRef: "Cart", targetType: .View)
                        }
                        Navigator.shared.dopen(Navigator.mymm.website_cart)
                        
                    case ProductItem.Order.rawValue:
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            cell.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey)
                            cell.recordAction(.Tap, sourceRef: "MyOrder", sourceType: .Button, targetRef: "MyOrder", targetType: .View)
                        }
                        Navigator.shared.dopen(Navigator.mymm.website_order_list)
                        
                    case ProductItem.MyCoupon.rawValue:
                        //record action
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            cell.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey)
                            cell.recordAction(.Tap, sourceRef: "My-MyCouponList", sourceType: .Button, targetRef: "MyCouponList", targetType: .View)
                        }
                        
                        Navigator.shared.dopen(Navigator.mymm.website_myCoupon)
                        
                    case ProductItem.Wishlist.rawValue:
                        if let cell = collectionView.cellForItem(at: indexPath) {
                            cell.initAnalytics(withViewKey: strongSelf.analyticsViewRecord.viewKey)
                            cell.recordAction(.Tap, sourceRef: "Collection", sourceType: .Button, targetRef: "MyCollection", targetType: .View)
                        }
                   let collectionViewController = MyCollectionViewController()
                        collectionViewController.user = strongSelf.user
                        strongSelf.navigationController?.pushViewController(collectionViewController, animated: true)
                        
                    default: break
                    }
                }
            }
            
            return cell
        case UserProfileSection.SecondLine.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: idDefault, for: indexPath)
            cell.backgroundColor = UIColor(hexString: "#F3F3F3")
            return cell
        case UserProfileSection.FirstLine.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: idDefault, for: indexPath)
            cell.backgroundColor = UIColor(hexString: "#F3F3F3")
            return cell
        case UserProfileSection.Banner.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.CellIdentifier, for: indexPath) as! BannerCell
            cell.delegate = self
            cell.analyticsViewKey = self.analyticsViewRecord.viewKey
            cell.positionLocation = "MyProfile"
            cell.positionComponent = "TileBanner"
            cell.impressionVariantRef = ""
            cell.sourceType = .TileBanner
            cell.bannerList = self.banners ?? []
            cell.showOverlay(false)
            generalBannerCell = cell

            cell.isHidden = cell.bannerList.count == 0
            
            return cell
            
        case UserProfileSection.MemberCard.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileMemberCardCell.CellIdentifier, for: indexPath) as! ProfileMemberCardCell
            cell.showRedDot(!Context.getVisitedVipCard())
            
            cell.titleImageView.image = UIImage(named: "icon_vip")
            cell.titleLabel.text = String.localize("LB_CA_VIP_ENTRYPOINT")
            cell.cardTypeImageView.image = UIImage(named: "icon_vip_circle_lv5")
            cell.cardTypeImageView.isHidden = false
            cell.viewAllLabel.isHidden = false
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            
            self.profileMemberCardCell = cell
            self.profileMemberCardCell?.loyalty = self.user.loyalty
            cell.viewDidTap = { [weak self] profileMemberCardCell in
                if let strongSelf = self{
                    if strongSelf.user.loyalty == nil{
                        strongSelf.showLoading()
                        strongSelf.getUserLoyaltyStatus({ [weak self] (loyalty) in
                            if let strongSelf = self{
                                strongSelf.stopLoading()

                                if let loyalty = loyalty{
                                    strongSelf.user.loyalty = loyalty
                                    DispatchQueue.main.async {
                                        strongSelf.profileHeader?.updateViewWithLoyalty(loyalty)
                                        strongSelf.profileMemberCardCell?.loyalty = loyalty
                                    }
                                }
                            }
                            }, failure: { [weak self] (errorType) in
                                if let strongSelf = self{
                                    strongSelf.stopLoading()
                                }
                            })
                    }
                    else{
                        Context.setVisitedVipCard(true)
                        
                        let vc = MemberCardViewController()
                        vc.paymentTotal = strongSelf.user.paymentTotal
                        vc.cardTypeName = strongSelf.user.loyalty?.loyaltyStatusName ?? ""
                        if let memberCardType = MemberCardType(rawValue: strongSelf.user.loyaltyStatusId){
                            vc.memberCardType = memberCardType
                        }
                        strongSelf.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                    profileMemberCardCell.recordAction(.Tap, sourceRef: "MyProfile", sourceType: .Button, targetRef: "VIP-Dashboard-User", targetType: .View)
                
                }
            }
            return cell
            
        case UserProfileSection.InviteFriend.rawValue:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileInviteFriendCell.CellIdentifier, for: indexPath) as! ProfileInviteFriendCell
            cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
            cell.viewDidTap = { [weak self] in
                if let strongSelf = self {
                    cell.recordAction(.Tap, sourceRef: "InviteFriend", sourceType: .Button, targetRef: "Share", targetType: .View)
                    BannerManager.sharedManager.getCampaigns().then { (success) -> Void in
                        if !success {
                            strongSelf.inviteFriend()
                        }
                    }
                }
            }
            return cell
        default:
            if postManager.currentPosts.count == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaceHolderCell.PlaceHolderCellIdentifier, for: indexPath) as! PlaceHolderCell
                return cell
            }
            
            if indexPath.row == postManager.currentPosts.count {
                let cell = loadingCellForIndexPath(indexPath: indexPath)
                if (!postManager.hasLoadMore) {
                    cell.isHidden = true
                } else {
                    cell.isHidden = false
                    
                    self.updateNewsFeed(pageno: postManager.currentPageNumber + 1)
                }
                return cell
            }
            
            
            let cell = postManager.getSimpleNewsFeedCell(indexPath)
            if let cell = cell as? SimpleFeedCollectionViewCell {
                
                if !myFeedCollectionViewCells.contains(cell) {
                    myFeedCollectionViewCells.append(cell)
                }
                cell.isUserInteractionEnabled = true
                var positionLocation = ""
                if self.currentType == .Public{
                    positionLocation = self.user.targetProfilePageTypeString()
                }
                else if self.currentType == .Private{
                    positionLocation = "MyProfile"
                }
                cell.recordImpressionAtIndexPath(indexPath, positionLocation: positionLocation, viewKey: self.analyticsViewRecord.viewKey)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: IndexPath) {
        //Turn off the timer to avoid crashing if banner cell is disappeared
        if let bannerCell = cell as? BannerCell {
            bannerCell.isAutoScroll = false
        }
    }
    
    func showThankYouPage(){
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = paidOrder
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
            DispatchQueue.main.async {
                self.floatingActionButton?.isHidden = true
            }
        }
        self.present(navigationController, animated: true, completion: nil)
        self.stopLoading()
        DispatchQueue.main.async {
            self.floatingActionButton?.isHidden = true
        }
    }
    
    func loadingCellForIndexPath(indexPath: IndexPath) -> UICollectionViewCell {
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
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCellIdentifier, for: indexPath)
        return cell
    }

    func getBannerSize() -> CGSize{
        if let banners = self.banners  {
            if banners.count > 0 {
                return CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width * 300 / 1125) //Image size 1125 x 300
            }
        }
        return CGSize(width: 1, height: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            
            let user = self.currentUser()
            if userType == .CuratorType {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderCuratorIdentifier, for: indexPath)
                
                if self.isLoadedUserInfo{
                    view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(nil, authorType: nil, brandCode: nil, impressionRef: user.userKey, impressionType: "Curator", impressionVariantRef: nil, impressionDisplayName: user.userName, merchantCode: nil, parentRef: nil, parentType: nil, positionComponent: "HeroImage", positionIndex: nil, positionLocation: "CPP", referrerRef: nil, referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
                    self.viewHeader = view
                }

                if let header = (view as? HeaderCuratorProfileView) {
                    header.completionAboutHandler = {
                        self.didSelectDescriptionView()
                        self.logAction(view: header, sourceRef: "About")
                    }
                    self.profileHeader = header
                }
            }
            else {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderProfileIdentifier, for: indexPath)
                
                if self.isLoadedUserInfo{
                    view.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(nil, authorType: nil, brandCode: nil, impressionRef: user.userKey, impressionType: "User", impressionVariantRef: nil, impressionDisplayName: user.userName, merchantCode: nil, parentRef: nil, parentType: nil, positionComponent: "HeroImage", positionIndex: nil, positionLocation: "UPP", referrerRef: nil, referrerType: nil, viewKey: self.analyticsViewRecord.viewKey))
                    self.viewHeader = view
                }
                self.profileHeader = (view as! HeaderMyProfileCell)
            }

            if let header = self.profileHeader {
                header.dismissKeyboardHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.dismissKeyboard()
                    }
                }
                
                header.userType = self.userType
                header.delegateMyProfile = self
				
				if user.userKey == Context.getUserKey() {
					currentType = TypeProfile.Private
				}
				
                if currentType == TypeProfile.Private {
                    header.isPrivateProfile = true
                    header.currentProfileType = .Private
                } else {
                    header.isPrivateProfile = false
                    header.currentProfileType = .Public
                }
                
                header.wishlistCount = user.wishlistCount
                header.setupDataWithUser(user)
                
                 header.coverImageView.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: self.profileUserKey, impressionType: "User", impressionDisplayName: getDisplayName(), positionComponent: "HeroImage", positionIndex: nil, positionLocation: "UPP", viewKey: self.analyticsViewRecord.viewKey))
                
                return header
            }
        } else if kind == UICollectionElementKindSectionFooter {
            
            if postManager.hasLoadMore {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "LoadingFooterView", for: indexPath)
                if let footer = view as? LoadingFooterView {
                    footer.activity.isHidden = !postManager.hasLoadMore
                }
                return view
            } else if currentType == .Private {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "myFooterView", for: indexPath)
                // configure footer view
                return view
            }
        }
        
        return UICollectionReusableView()
    }
    
    func getDisplayName() -> String {
        
        var displayName = ""
        
        if currentType == .Private {
            
            let user : User = Context.getUserProfile()
            
            displayName = user.displayName
            
        } else {
            
            displayName = publicUser.displayName
            
        }
        
        return displayName
    }
    
    /**
     go to  curator description page
     */
	
	func didSelectDescriptionView() {
		let merchantDescriptionVC = MerchantDescriptionViewController()
        merchantDescriptionVC.mode = DescriptionMode.modeCurator
		merchantDescriptionVC.user = self.user
		self.navigationController?.pushViewController(merchantDescriptionVC, animated: true)
	}
		
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: section == UserProfileSection.Header.rawValue ? heightHeaderProfile : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView == self.collectionView  && section == UserProfileSection.Feed.rawValue && currentType == .Private && postManager.currentPosts.count > 0 {
            if postManager.hasLoadMore {
                return CGSize(width: 320, height: 100)
            }
            return CGSize(width: self.view.frame.width, height: FooterMyProfileCell.FooterMyProfileCellHeight)
        }

        return CGSize(width: self.view.frame.width, height: 0.0)
        
        
    }
    
	
	//MARK: - UIScrollView Delegate
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		//NotificationCenter.default.post(name: Constants.Notification.ToggleHideOrShowProductTags, object: true)
	}
	
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //Log.debug("contentOffset Y : \(scrollView.contentOffset.y) ")
        
        dismissKeyboard()
        
        let scrollOffsetY = 80.0 - scrollView.contentOffset.y
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: scrollView.contentOffset.y)
        }
        
        if (scrollOffsetY < 44.0) {
            
			// remove profile button to show title
			self.navigationItem.titleView = nil
			
            self.navigationBarVisibility = .visible
            self.navigationItem.title = user.displayName
            backupButtonColorOn()
        } else {
            
            self.navigationBarVisibility = .hidden
            self.navigationItem.title = ""
            setupBarButtons()
            createProfileButton()
            
            let diff = 80 - scrollOffsetY
            if (diff < 0){
                 self.profileHeader?.setCoverImageSize(CGFloat(80 - scrollOffsetY))
            }
        }
        if scrollView == self.collectionView {
            
            let offsetY = scrollView.contentOffset.y - lastPositionY
            lastPositionY = scrollView.contentOffset.y
            let maxY = CGFloat(64)
            if scrollView.contentOffset.y > maxY {
                if offsetY > OffsetAllowance  {
                    floatingActionButton?.fadeIn()
                }else if offsetY < -1 * OffsetAllowance{
                    floatingActionButton?.fadeOut()
                }
            }else if scrollView.contentOffset.y < maxY && (offsetY * -1) >= 0 {
                floatingActionButton?.fadeOut()
            }
        }
    }
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customPullToRefreshView?.scrollViewDidEndDragging()
    }
    
    //MARK: - Invite Friend Method
    func inviteFriend() {
        let shareViewController = ShareViewController(screenCapSharing: false)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        shareViewController.isSharingByInviteFriend = true
        shareViewController.didSelectSNSHandler = { method in
            let appName = Bundle.main.infoDictionary!["CFBundleDisplayName"] as? String ?? ""
            var title = String.localize("LB_CA_NATURAL_REF_SNS_MSG")
            title = title.replacingOccurrences(of: "{0}", with: appName)
            
            ShareManager.sharedManager.inviteFriend(title, description: String.localize("LB_CA_NATURAL_REF_SNS_DESC"), url: Constants.Path.InviteLinkURL, image: UIImage(named : "AppIcon"), method: method)
        }
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    //MARK: - handle data
    func updateUserView() {
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return self.fetchUser()
        }.then { _ -> Void in
            self.renderUserView()
            
            self.getUserLoyaltyStatus(
                { [weak self] (loyalty) in
                    if let strongSelf = self, let loyalty = loyalty{
                        strongSelf.user.loyalty = loyalty
                        main_async {
                            strongSelf.stopLoading()
                            strongSelf.profileHeader?.updateViewWithLoyalty(loyalty)
                            strongSelf.profileMemberCardCell?.loyalty = loyalty
                        }
                        
                    }
                },
                failure: { [weak self] (errorType) in
                    if let strongSelf = self{
                        strongSelf.stopLoading()
                    }
                }
            )
            
            self.initAnalyticLog()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func updateUserPublicProfile(){
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return self.fetchPublicUser()
            }.then { _ -> Void in
                
                if LoginManager.getLoginState() == .validUser {
                    self.checkStatusUser(self.publicUser)
                }
                
                if self.isNeedHookPostManager {
                    self.isNeedHookPostManager = false
                    self.postManager = PostManager(postFeedTyle: .userFeed, authorKey: self.profileUserKey, collectionView: self.collectionView, viewController: self)
                    self.updateNewsFeed(pageno: self.postManager.currentPageNumber + 1)
                }
                self.renderUserView()
                self.initAnalyticLog()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func renderUserView() {
		self.reloadData()
	}
	    
    func fetchPublicUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            let success:(_ value: User) -> Void = { [weak self]  (user) in
                if let strongSelf = self {
                    strongSelf.publicUser.userKey = strongSelf.user.userKey
                    strongSelf.publicUser.isCurator = strongSelf.user.isCurator //Fix MM-22606 missing Curator type for analytic record
                    
                    strongSelf.user.isFriendUser = true
                    strongSelf.isRefresh = false
                    strongSelf.isLoadedUserInfo = true
                }
                
                fulfill("OK")
            }
            
            let failure:(_ error: Error) -> Bool = { (error) in
                reject(error)
                return false
            }
            
            if publicUser.userName.length > 0 {
                UserService.viewWithUserName(publicUser.userName, success: success, failure: failure)
            } else {
                UserService.viewWithUserKey(publicUser.userKey, success: success, failure: failure)
            }
        }
    }
    
    func fetchUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)!
                            strongSelf.isLoadedUserInfo = true
                            if (strongSelf.user.isCurator == 1) {
                                
                                strongSelf.userType = .CuratorType
                                
                            } else {
                                
                                strongSelf.userType = .UserNormal

                            }
							
							Context.saveUserProfile(strongSelf.user)

                            strongSelf.isRefresh = false
							
                            if Context.getLoyaltyStatus() > 0{
                                if Context.getLoyaltyStatus() < strongSelf.user.loyaltyStatusId{
                                    Context.setVisitedVipCard(false)
                                }
                            }
                            
                            Context.setLoyaltyStatus(strongSelf.user.loyaltyStatusId)
                            
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
            }
        }
    }
    
    func updateNewsFeed(pageno: Int){
        firstly {
            // update inventory location if needed
            // if it is not updated, it will return success without api call
            return postManager.fetchNewsFeed(.userFeed, userKey: profileUserKey, pageno: pageno)
            }.then { postIds -> Promise<Any> in
                return self.postManager.getPostActivitiesByPostIds(postIds as! String)
            }.then { _ -> Promise<[PostLike]> in
        
                if pageno == 1 && self.currentType == TypeProfile.Private{
                    return PostManager.fetchUserLikes()
                }
                return Promise.init(value: [])
        
            }.always {
				
				self.renderUserView()

            }.catch { _ -> Void in
                Log.error("error")
        }
	}
    
    // friend api
    private func addFriend(user:User) {
        self.relationShip?.isLoading = true
        firstly {
            return self.addFriendRequest(user: user)
        }.then { _ -> Void in
            user.isFriendUser = true
            user.isLoading = false
            if user.isFollowUser == false {
                user.isFollowUser = true
                user.followerCount += 1
				FollowService.instance.cachedFollowingUserKeys.insert(user.userKey)
            }
            self.showSuccessPopupWithText(String.localize("MSG_SUC_FRIEND_REQ_SENT"))
        }.always {
            self.relationShip?.isLoading = false
            self.user.isLoading = false
            self.renderUserView()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
	
    func addFriendRequest(user:User) -> Promise<Any> {
        return Promise { fulfill, reject in
            FriendService.addFriendRequest(user, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            //Server is caching by Etag, data will update later, shouldn't update immediately
                             //strongSelf.checkStatusUser(strongSelf.publicUser)
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            })
        }
    }
    
    func deleteRequest(user:User) {
        firstly {
            return self.deleteFriendRequest(user: user)
        }.then { _ -> Void in
            user.isFriendUser = false
            self.renderUserView()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func deleteFriendRequest(user:User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.deleteRequest(user, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            //Server is caching by Etag, data will update later, shouldn't update immediately
                            //strongSelf.checkStatusUser(strongSelf.publicUser)
                            CacheManager.sharedManager.deleteFriend(user)
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            })
        }
    }
    
    //cancel friend 
    
    
    private func cancelRequest(_ user:User) {
        self.relationShip?.isLoading = true
        firstly{
            return self.deleteFriendRequest(user: user)
        }.then { _ -> Void in
            user.isFriendUser = false
        }.always {
            self.relationShip?.isLoading = false
            self.renderUserView()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func cancelFriendRequest(_ user:User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.cancelFriend(user, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.handleApiResponseError(response, reject: reject)
                    }
                }
            })
        }
    }
    
    func acceptRequest(_ user:User) {
        firstly{
            return self.acceptFriendRequest(user)
            }.then
            { _ -> Void in
                user.isFriendUser = true
                self.relationShip?.isFriend = true
                if user.isFollowUser == false{
                    user.isFollowUser = true
                    user.followerCount += 1
                }
                self.renderUserView()
                CacheManager.sharedManager.addFriend(user)
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func acceptFriendRequest(_ user:User) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FriendService.acceptRequest(user, completion:
                {
                    [weak self] (response) in
                    if let strongSelf = self {
                        
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                            } else {
                                strongSelf.handleApiResponseError(response, reject: reject)
                            }
                        }
                        else{
                            reject(response.result.error!)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }
                })
        }
    }
    
    // follow api 
    func followUser(_ user:User) {
        user.isLoading = true
        self.renderUserView()
        firstly {
            return FollowService.requestFollow(user.userKey)
        }.then { _ -> Void in
            user.isLoading = false
            user.isFollowUser = true
            user.followerCount += 1
            self.renderUserView()
            NotificationCenter.default.post(name: Constants.Notification.followingDidUpdate, object: nil)
        }.catch { _ -> Void in
            user.isLoading = false
            self.renderUserView()
            Log.error("error")
        }
    }
    
    func unfollowUser(_ user:User) {
        let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: user.displayName)
        Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
            user.isLoading = true
            self.renderUserView()
            // call api unfollow request
            firstly {
                return FollowService.requestUnfollow(user.userKey)
                }.then { _ -> Void in
                    user.isLoading = false
                    let filteredPosts = PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue]?.filter({$0.user?.userKey != user.userKey})
                    PostStorageManager.sharedManager.userPosts[FeedType.newsFeed.rawValue] = filteredPosts

                    user.isFollowUser = false
					
					if user.followerCount > 0 {
						user.followerCount -= 1
					} else {
						user.followerCount = 0
					}
                    self.renderUserView()
                    NotificationCenter.default.post(name: Constants.Notification.followingDidUpdate, object: nil)
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.handleApiResponseError(apiResponse: apiResp, statusCode: error.code)
                    }
                    user.isLoading = false
                    self.renderUserView()
            }
            }, cancelActionComplete:{() -> Void in
                user.isLoading = false
                self.renderUserView()
        })
    }
    
    func checkStatusUser(_ user: User) {
        RelationshipService.relationshipByUser(user.userKey, timestamp: Double(Date().timeIntervalSince1970)) { [weak self] (response) in
            if let strongSelf = self {
                if response.response?.statusCode == 200 {
                    
                    strongSelf.relationShip = Mapper<Relationship>().map(JSONObject: response.result.value)!
                    
                    strongSelf.user.isFollowUser = strongSelf.relationShip!.isFollowing
                    strongSelf.reloadData()
                } else {
                    strongSelf.handleError(response, animated: true)
                }
            }
        }
    }
    
    //List loyalty status
    func getUserLoyaltyStatus(_ success: ((Loyalty?)->())? = nil, failure: ((Error?)->())? = nil){
        LoyaltyManager.handleListLoyaltyStatus(success: { [weak self] (loyalties) in
            if let strongSelf = self{
                let filterLoyalties = loyalties.filter{$0.loyaltyStatusId == strongSelf.user.loyaltyStatusId}
                success?(filterLoyalties.first)
            }
            }, failure: { (errorType) in
                failure?(errorType)
        })
    }
    
    //MARK: - Handle When edit avatar
    
    func changeProfileImage(_ sender: UITapGestureRecognizer, isTapAvatar: Bool){
        var keyViewProfile: String?
        var keyDeleteProfile: String?
        var keyTakeProfile: String?
        var keyChooseProfile: String?
        
        if isTapAvatar {
            keyViewProfile = String.localize("LB_CA_VIEW_PROF_PIC")
			keyDeleteProfile = String.localize("LB_CA_DEL_CURR_PROF_PIC")
        } else {
            keyViewProfile = String.localize("LB_CA_VIEW_COVER_PIC")
			keyDeleteProfile = String.localize("LB_CA_DEL_CURR_COVER_PIC")
        }
		
        keyTakeProfile = String.localize("LB_CA_PROF_PIC_TAKE_PHOTO")
        keyChooseProfile = String.localize("LB_CA_PROF_PIC_CHOOSE_LIBRARY")
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if (self.user.profileImage != "" && self.isTapAvatar == true) ||  (self.user.coverImage != "" && self.isTapAvatar == false) {
            createButtonDeleteAndViewFullScreen(optionMenu: optionMenu, keyView: keyViewProfile!, keyDelete: keyDeleteProfile!)
        }
        
        let takePhoto = UIAlertAction(title: keyTakeProfile , style: .`default`, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        let saveAction = UIAlertAction(title: keyChooseProfile, style: .`default`, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openGallery()
        })
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showFloatingActionButton()
        })
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        
		self.present(optionMenu, animated: true, completion: nil)
		optionMenu.view.tintColor = UIColor.alertTintColor()

	}
	
	func showFloatingActionButton() -> Void {
        self.floatingActionButton?.isHidden = false
    }
	
	// create button delete and view Full screen
    func createButtonDeleteAndViewFullScreen (optionMenu: UIAlertController, keyView: String, keyDelete: String) {
        let viewFullScreen = UIAlertAction(title: keyView, style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.viewFullScreen()
        })
        let deleteAction = UIAlertAction(title: keyDelete, style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.deleteImages()
            
        })
        optionMenu.addAction(viewFullScreen)
        optionMenu.addAction(deleteAction)
    }
    
    func openCamera() {
        Utils.checkCameraPermissionWithCallBack({[weak self] (granted) in
            if let strongSelf = self, granted {
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                    strongSelf.picker.sourceType = UIImagePickerControllerSourceType.camera
                    if strongSelf.isTapAvatar == true {
                        strongSelf.picker.cameraDevice = UIImagePickerControllerCameraDevice.front
                    } else {
                        strongSelf.picker.cameraDevice = UIImagePickerControllerCameraDevice.rear
                    }
                    
                    strongSelf.present(strongSelf.picker, animated: true, completion: nil)
                } else {
                    Alert.alert(strongSelf, title: "Camera not found", message: "Cannot access the front camera. Please use photo gallery instead.")
                }
            }
        })
    }
    
    func openGallery() {
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.present(picker, animated: true, completion: nil)
        } else {
            Alert.alert(self, title: "Tablet not suported", message: "Tablet is not supported in this function")
        }
    }
    
    
    func showCropView(_ image: UIImage) {
        let imageCopy: UIImage = image.copy() as! UIImage
        let imagecropVc = ImageCropViewController(image: imageCopy)
        imagecropVc?.delegate = self
        imagecropVc?.blurredBackground = true
        imagecropVc?.square = self.isTapAvatar
        imagecropVc?.horizontalRectangle = !self.isTapAvatar
        
        if self.isTapAvatar == false {
            if let header = self.profileHeader {
                imagecropVc?.ratio = NSNumber(value: Float(header.frame.sizeHeight / header.frame.sizeWidth))
                imagecropVc?.horizontalRectangle = true
                imagecropVc?.square = false
            }
        }
        
        imagecropVc?.title = String.localize("LB_CA_EDIT_PICTURE")
        
        self.navigationController?.pushViewController(imagecropVc!, animated: true)
    }
    
	
	//MARK: - Upload Image
	func uploadProfileImage(_ image: UIImage){
        if image.size.width > 0 {
            self.user.pendingUploadProfileImage = image
            self.isRefresh = false
            self.renderUserView()
            
            UserService.uploadImage(image, imageType: .profile, success: { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							
							
							if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
								strongSelf.user.profileImage = imageUploadResponse.profileImage
                                strongSelf.user.pendingUploadProfileImage = nil
								strongSelf.isRefresh = false
								strongSelf.renderUserView()
                                Context.saveUserProfile(strongSelf.user)
                                NotificationCenter.default.post(name: Constants.Notification.profileImageUploadSucceed, object: nil)
                                for conv in WebSocketManager.sharedInstance().convList {
                                    if let me = conv.me {
                                        me.profileImage = imageUploadResponse.profileImage
                                        CacheManager.sharedManager.cacheListObjects([me.cacheableObject()])
                                    }
                                }
							}
						}
					}
					Log.debug("error")
					strongSelf.stopLoading()
				}
            }, fail: { [weak self] encodingError in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    strongSelf.showSuccessPopupWithText(String.localize("error"))
                }
			})
        }
    }
    
	func uploadCoverImage(image: UIImage) {
        if image.size.width > 0 {
            self.user.pendingUploadCoverImage = image
            self.isRefresh = false
            self.renderUserView()
            UserService.uploadImage(image, imageType: .cover, success: { [weak self] (response) in
				if let strongSelf = self {
					if response.result.isSuccess {
						if response.response?.statusCode == 200 {
							
							
							if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
								strongSelf.user.coverImage = imageUploadResponse.coverImage
                                strongSelf.user.pendingUploadCoverImage = nil
								strongSelf.isRefresh = false
                                Context.saveUserProfile(strongSelf.user)
                                strongSelf.renderUserView()
							}
						}
					}
					
					Log.debug("error")
					strongSelf.stopLoading()
				}
            }, fail: { [weak self] encodingError in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    strongSelf.showSuccessPopupWithText(String.localize("error"))
                }
            })
        }
    }
    
    func viewFullScreen() {
        var images = [SKPhoto]()
        if (self.isTapAvatar == true && self.user.profileImage != "") {
            if let image = self.avatarImage.image {
                images.append(SKPhoto.photoWithImage(image))
            }
        } else if (self.user.coverImage != "") {
            if let image = self.coverImageView.image {
                images.append(SKPhoto.photoWithImage(image))
            }
        }
		
		self.showFloatingActionButton()
        
        let browser = SKPhotoBrowser(photos: images)
        browser.initializePageIndex(0)
        self.navigationController?.present(browser, animated: true, completion: {})
    }
    
    func deleteImages() {
        if self.isTapAvatar == true {
            self.deleteAvatar()
        } else {
            self.deleteCover()
        }
		
		self.showFloatingActionButton()
    }
    
    func deleteAvatar() {
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                
        }, to: Constants.Path.Host + "/user/upload/profileimage", method: .post, headers: Context.getHTTPHeader(Constants.AppVersion),
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        
                        if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
                            self.user.profileImage = imageUploadResponse.profileImage
                            Context.saveUserProfile(self.user)
                            self.isRefresh = false
                            self.renderUserView()
                            
                            for conv in WebSocketManager.sharedInstance().convList {
                                if let me = conv.me {
                                    me.profileImage = imageUploadResponse.profileImage
                                    CacheManager.sharedManager.cacheListObjects([me.cacheableObject()])
                                }
                            }
                        }
                    }
                case .failure(_): break
                }
            }
        )
    }
    
    func deleteCover() {

        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                
        }, to: Constants.Path.Host + "/user/upload/coverimage", method: .post, headers: Context.getHTTPHeader(Constants.AppVersion),
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        
                        if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
                            self.user.coverImage = imageUploadResponse.coverImage
                            Context.saveUserProfile(self.user)
                            self.renderUserView()
                        }
                    }
                case .failure(_): break
                }
            }
        )
    }
    
    func didCropedImage(imageCroped: UIImage!) {
        if self.isTapAvatar == true {
            profileImage = imageCroped
            self.uploadProfileImage(getCropImage(croppedImage: profileImage))
        } else {
            coverImage = imageCroped
            self.uploadCoverImage(image: resizeCoverImage(image: coverImage))
        }
    }
    
    func getCropImage(croppedImage: UIImage) -> UIImage {
		
		var image = croppedImage
		
        if (croppedImage.size.width > ImageSizeCrop.width_max || croppedImage.size.height > ImageSizeCrop.height_max) {
            if let resizeImage = croppedImage.resize(CGSize(width: ImageSizeCrop.width_max, height: ImageSizeCrop.height_max), contentMode: UIImage.UIImageContentMode.scaleToFill ,quality: CGInterpolationQuality.high) {
				image = ImageHelper.getServerAcceptedImageSize(resizeImage)
			}
        } else {
			image = ImageHelper.getServerAcceptedImageSize(croppedImage)
        }
		
		return image
    }
    
    func resizeCoverImage(image: UIImage) -> UIImage {
		
		var finalImage = image
		
        let maxWidth = ImageSizeCrop.cover_width
        var ratio = CGFloat(1)
        if maxWidth < image.size.width {
            ratio = maxWidth / image.size.width
        }
        var newSize = CGSize.zero
        
        newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
		
		finalImage = ImageHelper.getServerAcceptedImageSize(image.scaleToSize(newSize))
		
        return finalImage
        
    }

    // MARK: - Handle animations
    @objc func startAllAnimations() {
        generalBannerCell?.reset()
    }
    
    @objc func stopAllAnimations() {
        generalBannerCell?.isAutoScroll = false
    }
    
    // MARK: -  lazyload
    
    private lazy var shareButton:UIButton = {
        let shareButton = UIButton(type: .custom)
        shareButton.addTarget(self, action: #selector(self.shareButtonTapped), for: .touchUpInside)
        shareButton.frame = CGRect(x: 0, y: 0, width: 33, height: 33)
        shareButton.clipsToBounds = false
        return shareButton
    }()
}

extension ProfileViewController : PullToRefreshViewUpdateDelegate{
    func didEndPullToRefresh() {
        self.refresh()
    }
}
extension ProfileViewController: MMFloatingActionButtonDelegate {
    
    //MARK: Floating Action Button

    @objc func didSelectedActionButton(gesture: UITapGestureRecognizer) {
        PopManager.sharedInstance.selectPost()
        
        self.view.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Button, targetRef: "Editor-Image-Album", targetType: .View)
    }
   
}

// MARK: -  HeaderMyProfileDelegate
extension ProfileViewController: HeaderMyProfileDelegate {
    
    @objc func shareButtonTapped() {
        shareButton.recordAction(.Tap, sourceRef: "Share", sourceType: .Button, targetRef: "Share", targetType: .View)
        shareUser()
    }

    func onTapWishlistButton(_ sender: UIButton) {
        
        //record action
        
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        
        sender.recordAction(.Tap, sourceRef: (user.isCurator == 1 ? "Curator-Wishlist" : "User-Wishlist"), sourceType: .Button, targetRef: "Collection", targetType: .View)
        
        
        let wishlistPublicVC = PublicWishlistViewController()
        wishlistPublicVC.publicUser = self.publicUser
        self.navigationController?.pushViewController(wishlistPublicVC, animated: true)
    }
    
    @objc func onTapAvatarView(_ sender: UITapGestureRecognizer) {
        self.isTapAvatar = true
        
        if currentType == TypeProfile.Private {
            changeProfileImage(sender, isTapAvatar: self.isTapAvatar)
        } else {
            self.viewFullScreen()
        }
        
        self.floatingActionButton?.isHidden = true
    }
    
    func onTapEditCoverView(_ sender: UITapGestureRecognizer) {
        self.isTapAvatar = false
        if currentType == TypeProfile.Private {
            changeProfileImage(sender, isTapAvatar: self.isTapAvatar)
        } else {
            self.viewFullScreen()
        }
        self.floatingActionButton?.isHidden = true
    }
    
    func onTapMerchantListView(_ sender: UIButton) {
        //record action
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        if currentType == .Private {
            sender.recordAction(.Tap, sourceRef: "My-MyFollow-Brand", sourceType: .Button, targetRef: "MyFollow-Brand", targetType: .View)
        } else {
            sender.recordAction(.Tap, sourceRef: (user.isCurator == 1 ? "Curator-MyFollow-Brand" : "User-MyFollow-Brand"), sourceType: .Button, targetRef: "MyFollow-Brand", targetType: .View)
            
        }
        
        let followVC = FollowViewController()
        followVC.user = self.user
        followVC.currentProfileType = self.currentType
        followVC.merchantGetMode = MerchantGetMode.getMerchantListByUserKey
        followVC.modelist = ModeList.curatorList
        self.navigationController?.pushViewController(followVC, animated: true)
    }
    
    func didSelectDescriptionView(_ gesture: UITapGestureRecognizer) {
        let merchantDescriptionVC = MerchantDescriptionViewController()
        merchantDescriptionVC.mode = DescriptionMode.modeCurator
        merchantDescriptionVC.user = self.user
        self.navigationController?.pushViewController(merchantDescriptionVC, animated: true)
    }
    
    func onTapFriendList(_ sender: UIButton) {
        //record action
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        sender.recordAction(.Tap, sourceRef: "My-ContactList", sourceType: .Button, targetRef: "Contact-All", targetType: .View)
        
        let contactListVC = ContactListViewController()
        contactListVC.isAgent = false
        contactListVC.isFromProfile = true
       // contactListVC.isAgent = false
        // disable additional tabs on user profile
        //		if let merchants = Context.customerServiceMerchants().merchants {
        //			contactListVC.isAgent = !merchants.isEmpty
        //		}
        
        self.navigationController?.pushViewController(contactListVC, animated: true)
        
    }
    
    func didSelectCustomerList(_ sender: UIButton) {
        //record action
        sender.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
         if currentType == .Private {
            sender.recordAction(.Tap, sourceRef: "My-MyFollow-User", sourceType: .Button, targetRef: "MyFollow-User", targetType: .View)
         } else {
            sender.recordAction(.Tap, sourceRef: (user.isCurator == 1 ? "Curator-MyFollow-User" : "User-MyFollow-User"), sourceType: .Button, targetRef: "MyFollow-User", targetType: .View)
        }

        let followVC = FollowViewController()
        followVC.user = self.user
        followVC.modelist = ModeList.usersList
        followVC.selectedIndex = ModeList.curatorList.rawValue
        followVC.currentProfileType = self.currentType
        self.navigationController?.pushViewController(followVC, animated: true)
    }
    
    func onHandleAddFriend(_ friendStatus: StatusFriend) {
        guard LoginManager.getLoginState() == .validUser else {
            NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
            return
        }
        
        switch friendStatus {
        case .friend:
            let str = String.localize("LB_CA_REMOVE_FRD_CONF")
            let message = str.replacingOccurrences(of: "{0}", with: " \(self.user.displayName) ")
            Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
                self.deleteRequest(user: self.user)
                self.relationShip?.isFriend = false
                self.reloadData()
                self.logAction(view: self.view, sourceRef: "Unfriend")
            }, cancelActionComplete:{ () -> Void in
                self.renderUserView()
            })
            break
        case .pending:
            let str = String.localize("LB_CA_FRD_REQ_CANCEL_CONF")
            let message = str.replacingOccurrences(of: "{0}", with: " \(self.user.displayName) ")
            Alert.alert(self, title: "", message: message, okActionComplete: { () -> Void in
                // call api cancel request
                self.cancelRequest(self.user)
                self.relationShip?.isFriendRequested = false
                self.reloadData()
            }, cancelActionComplete: { () -> Void in
                self.renderUserView()
            })
            break
        case .receivedFriendRequest:
            self.acceptRequest(user)
            break
        default:
            break
        }
        
    }
    
    func onHandleAddFollow(_ followStatus: Bool) {
        guard LoginManager.getLoginState() == .validUser else {
            NotificationCenter.default.post(name: Constants.Notification.notifyUserLogin, object: SignupMode.publicProfile.rawValue)
            return
        }
        
        if followStatus {
            unfollowUser(user)
        } else {
            followUser(user)
        }
        self.logAction(view: self.view, sourceRef: (followStatus ? "Unfollow" : "Follow"))
       
    }
    
    func onTapMyFollowersListView(_ sender: UIButton) {
        
        let myFollowersViewController = MyFollowersViewController()
        myFollowersViewController.currentProfileType = currentType
        myFollowersViewController.thisUser = self.publicUser
        self.navigationController?.pushViewController(myFollowersViewController, animated: true)
        self.logAction(view: sender, sourceRef: "FansCount")
    }
    
    func onTapCuratorsListView(_ sender: UIButton) {
        let followVC = FollowViewController()
        followVC.user = self.user
        followVC.currentProfileType = self.currentType
        followVC.selectedIndex = ModeList.curatorList.rawValue
        followVC.modelist = ModeList.curatorList
        self.navigationController?.pushViewController(followVC, animated: true)
    }
    
    func didSelectOption(_ sender: UIButton) {
        
        showAlertOption()
        self.logAction(view: sender, sourceRef: "More")
    }
    
    func showAlertOption() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let share = UIAlertAction(title: String.localize("LB_CA_SHARE_USER_PROD"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.shareSocial()
        })
        let chat = UIAlertAction(title: String.localize("LB_CA_PROFILE_MSG_CHAT"), style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.chatView(user: self.publicUser)
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        optionMenu.addAction(share)
        if self.relationShip?.isFriend == true {
            optionMenu.addAction(chat)
        }
       // optionMenu.addAction(report)
        
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    func shareSocial() {
        shareUser()
    }
    
    func chatView(user: User) {
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        let targetRole: UserRole = UserRole(userKey: user.userKey)
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
            checkNetwork: true,
            viewController: self,
            completion: { [weak self] (ack) in
                if let strongSelf = self, let convKey = ack.data {
                    let viewController = UserChatViewController(convKey: convKey)
                    strongSelf.navigationController?.pushViewController(viewController, animated: true)
                }
            }
        )
    }
    
    private func loadBannersData() {
        firstly {
            return BannerService.fetchBanners([.profileBanner])
            }.then {  banners -> Void in
                self.banners = banners
                self.reloadData()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    
    // MARK: - Banner Cell Delegate
    
    
    func didSelectBanner(_ banner: Banner) {
        if !isPresentingViewController {
            //This flag prevent fast click on banner
            isPresentingViewController = true
            Log.debug("didSelectBanner")

            if banner.link.contain(Constants.MagazineCoverList) {
                // open as magazine cover list
                if LoginManager.isLoggedInErrorPrompt() {
                    PostManager.isSkipLoadingNewFeedInHome = true
                    let magazineCollectionViewController = MagazineCollectionViewController()
                    self.navigationController?.pushViewController(magazineCollectionViewController, animated: true)
                    self.isPresentingViewController = false
                }
            } else {
                if let deepLinkDictionary = DeepLinkManager.sharedManager.getDeepLinkTypeValue(banner.link) {
                    if let deepLinkType = deepLinkDictionary.keys.first as DeepLinkManager.DeepLinkType? {
                        if deepLinkType == .Conversation || deepLinkType == .OrderReturn {
                            // check user login
                            if LoginManager.getLoginState() != .validUser {
                                isPresentingViewController = false
                                return
                            }
                        }
                        if Navigator.shared.open(banner.link) {
                            self.isPresentingViewController = false
                        }
                    }
                }
            }
        }

    }

    func reloadData() {
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @objc func didReceiveScreenCapNotification(notification: NSNotification){
        self.postManager.sharePost()
    }
}

extension ProfileViewController: ImageCropViewControllerDelegate {
    
    
    func imageCropViewControllerSuccess(_ controller: UIViewController!, didFinishCroppingImage croppedImage: UIImage!) {
        didCropedImage(imageCroped: croppedImage)
        self.navigationController?.popViewController(animated:true)
    }
    
    func imageCropViewControllerDidCancel(_ controller: UIViewController!) {
        
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            if self.isTapAvatar == true {
                profileImage = image
                profileImage = profileImage.normalizedImage()
                showCropView(profileImage)
            } else {
                coverImage = image
                coverImage = coverImage.normalizedImage()
                showCropView(coverImage)
            }
            //        self.navigationController?.pushViewController(controller, animated: true)
            
            self.showFloatingActionButton()
            if picker.sourceType == .camera {
                CustomAlbumHelper.saveImageToAlbum(image)
            }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true) { () -> Void in
            self.showFloatingActionButton()
        }
    }
    
    // MARK: Logging
    
    func currentUser() -> User{
        let user =  self.currentType == .Public ? self.user : Context.getUserProfile()
        user.pendingUploadProfileImage = self.user.pendingUploadProfileImage
        user.pendingUploadCoverImage = self.user.pendingUploadCoverImage
        return user
    }
    
    func initAnalyticLog(){
        if isLoggingViewRecord == false{
            let user = self.currentUser()
            let viewLocation = ((self.currentType == .Private) ? "MyProfile" : user.targetProfilePageTypeString())
            initAnalyticsViewRecord(
                nil,
                authorType: nil,
                brandCode: nil,
                merchantCode: nil,
                referrerRef: nil,
                referrerType: nil,
                viewDisplayName: user.userName,
                viewParameters: nil,
                viewLocation: viewLocation,
                viewRef: user.userKey,
                viewType: user.userTypeString()
            )
            isLoggingViewRecord = true
        }
    }
    
    func getTargetType() {
        
        if currentType == .Private {
            
            let user = Context.getUserProfile()
            
            shouldActionTargetType(user: user)
            
        } else {
            
            shouldActionTargetType(user: publicUser)
            
        }
    }
    
    func shouldActionTargetType (user: User) {
        
        if user.isCurator == 1 {
            
            self.actionTargetType = .Curator
            
        } else {
            
            self.actionTargetType = .User
        }
    }
    
    func logAction(view : UIView, sourceRef: String) {
        
        getTargetType()
        
        view.analyticsViewKey = self.analyticsViewRecord.viewKey
        view.recordAction(
            .Tap,
            sourceRef: sourceRef,
            sourceType: .Button,
            targetRef: self.profileUserKey,
            targetType: self.actionTargetType)
    }
}

extension ProfileViewController : PinterestLayoutDelegate {
    
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case UserProfileSection.Header.rawValue:
            return CGSize(width: self.view.frame.size.width, height: ProfileProductsCell.HeaderHeight)
            
        case UserProfileSection.MemberCard.rawValue:
            return CGSize(width: self.view.frame.size.width, height: ProfileMemberCardCell.getHeight())
            
        case UserProfileSection.SecondLine.rawValue:
            return CGSize(width: self.view.frame.size.width, height: 10)
            
        case UserProfileSection.FirstLine.rawValue:
            return CGSize(width: self.view.frame.size.width, height: 10)
            
        case UserProfileSection.Banner.rawValue:
            return self.getBannerSize()
            
        case UserProfileSection.InviteFriend.rawValue:
            return CGSize(width: self.view.frame.size.width, height: ProfileInviteFriendCell.getHeight())
        case UserProfileSection.Feed.rawValue:
        
            if postManager.currentPosts.count == 0 {
                var height: CGFloat = 0
                if currentType == .Private {
                    height = self.collectionView.frame.height - (ProfileProductsCell.HeaderHeight + self.getBannerSize().height + heightHeaderProfile)
                } else {
                    height = self.collectionView.frame.height - heightHeaderProfile
                }
                
                if height < PlaceHolderMinHeight {
                    height = PlaceHolderMinHeight
                }
                return CGSize(width: self.view.frame.size.width, height: height)
            }else {
                if indexPath.row == postManager.currentPosts.count {
                    if (postManager.hasLoadMore) {
                        return CGSize(width: self.view.frame.size.width, height: Constants.Value.CatCellHeight)
                    }
                }
                var text = ""
                var userSourceName: String? = nil
                if postManager.currentPosts.indices.contains(indexPath.row) {
                    let post = postManager.currentPosts[indexPath.row]
                    userSourceName = post.userSource?.userName
                    text = post.postText
                }
                let height = SimpleFeedCollectionViewCell.getHeightForCell(text, userSourceName: userSourceName)
                return CGSize(width: SimpleFeedCollectionViewCell.getCellWidth(), height: height)
            }
            
        default:
            return CGSize(width: self.view.frame.size.width, height: 0)
            
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int {
        if section == UserProfileSection.Feed.rawValue && postManager.currentPosts.count > 0 {
            return 2
        }
        return 1
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets {
        let profileUIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 13, right: 0)
        if let sectionType = UserProfileSection(rawValue: section){
            switch sectionType {
            case .Header:
                return DefaultUIEdgeInsets
            case .MemberCard:
                if !Constants.SNSFriendReferralEnabled && currentType == .Private{
                    return profileUIEdgeInsets
                }
                return DefaultUIEdgeInsets
            case .InviteFriend:
                if Constants.SNSFriendReferralEnabled && currentType == .Private {
                    return DefaultUIEdgeInsets
                }
            case .Banner:
                if currentType == .Private {
                    return profileUIEdgeInsets
                }
            case .Feed:
                return UIEdgeInsets(top: 0, left: PostManager.NewsFeedLineSpacing, bottom: 25, right:PostManager.NewsFeedLineSpacing)
            default:
                return DefaultUIEdgeInsets
            }
        }
        return DefaultUIEdgeInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        if section == UserProfileSection.Header.rawValue || section == UserProfileSection.Banner.rawValue {
            return 0
        }
        return PostManager.NewsFeedLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return section == UserProfileSection.Feed.rawValue ? PostManager.NewsFeedLineSpacing : 0
    }
}

extension ProfileViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}

