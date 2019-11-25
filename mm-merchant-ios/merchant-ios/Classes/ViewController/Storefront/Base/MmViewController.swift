//
//  MMViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 11/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
import MBProgressHUD
import ObjectMapper
import PromiseKit
import Alamofire
import JPSVolumeButtonHandler
import SKPhotoBrowser
import XLPagerTabStrip

typealias LoginAfterCompletion = (() -> Void) // 登录成功后的回调

class MmViewController : LoadingViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MBProgressHUDDelegate, IncorrectViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate,IndicatorInfoProvider {
    
    var pageAccessibilityId = ""
    enum ButtonStyle: Int {
        case grayColor = 0,
        whiteColor,
        cross,
        cancelTitle,
        crossSmall
    }
    
    enum Theme {
        case unknown
        case normal
        case black
        case resume
    }
    
    private var currentTheme = Theme.unknown
    
    var shouldRecordViewTag = true
    var collectionView : MMCollectionView!
    
    var buttonCart: ButtonRedDot?
    var buttonWishlist: ButtonRedDot?
    var errorView: IncorrectView?
    
    private var buttonBack: UIButton?
    var bottomButtonContainer: UIView?
    private var bottomButton: UIButton?
    
    var tabBarHeight: CGFloat = 0
    
    var volumeButtonHandler: JPSVolumeButtonHandler!
    var volumeUpCount = 0
    var volumeDownCount = 0
    
    var dismissKeyboardGesture: UITapGestureRecognizer?
    
    private var loadingDelayAction: DelayAction?
    
    // MMAnalytics
    var analyticsViewRecord = AnalyticsViewRecord()
    
    var viewIsAppearing = false
    var noConnectionView: NoConnectionView?
    var index = 0
    var itemInfo = IndicatorInfo(title: "View")
    
    init(itemInfo: IndicatorInfo) {
        super.init(nibName: nil, bundle: nil)
        self.itemInfo = itemInfo
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem?.tintColor = UIColor.black
        
        self.view.backgroundColor = UIColor.white
        
        var frame = self.view.frame
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController, !navigationController.isNavigationBarHidden {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        
        if let tabBarController = self.tabBarController,let nav = self.navigationController, nav.viewControllers.count == 1 {
            tabBarHeight = tabBarController.tabBar.bounds.height
        }
        
        frame.origin.y = navigationBarMaxY + self.collectionViewTopPadding()
        frame.size.height = frame.size.height - (navigationBarMaxY + tabBarHeight + self.collectionViewBottomPadding() + self.collectionViewTopPadding())
        
        if shouldHaveCollectionView() {
            
            let layout: UICollectionViewFlowLayout = getCustomFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.itemSize = CGSize(width: self.view.frame.width, height: 120)
            
            collectionView = MMCollectionView(frame: frame, collectionViewLayout: layout)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.alwaysBounceVertical = true
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
            collectionView.backgroundColor = UIColor.white
            self.view.addSubview(collectionView)
        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        
        if Platform.DeveloperMode {
            setupVolumeButtonHandler()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonCartState), name: NSNotification.Name(rawValue: "refreshShoppingCartFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonWishlistState), name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        analyticsViewRecord.viewKey = Utils.UUID()
        analyticsViewRecord.timestamp = Date()
        
        Log.debug("[This class name] : \(self.classForCoder)")
        
        viewIsAppearing = true
        
        // fix nav bar tint color
        self.setupNavigationBarTitleColor()
        
        updateButtonCartState()
        updateButtonWishlistState()
        
        if let _ = dismissKeyboardGesture {
            NotificationCenter.default.addObserver(self, selector: #selector(MmViewController.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MmViewController.keyboardDidShowNotification(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(MmViewController.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if shouldRecordViewTag {
            // MMAnalytics
            AnalyticsManager.sharedManager.recordView(analyticsViewRecord)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewIsAppearing = false
        self.dismissKeyboardFromView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func sgm_safeAreaInset(view: UIView) -> UIEdgeInsets{
        if #available(iOS 11.0, *){
            return view.safeAreaInsets
        }
        return UIEdgeInsets.zero
    }
    
    
    deinit {
        
        Log.debug("[deinit class name] : \(self.classForCoder)")
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Newly added loading view placeholder
    
    private var loadingPlaceholder : UIView?
    private var loadingIndicator : MMRefreshAnimator?
    private var loadingLabel : UILabel?
    
    private var showingLoadingIndicator = false
    
    func startBackgroundLoadingIndicator(_ superView: UIView? = nil){
        
        guard !showingLoadingIndicator else {
            return
        }
        showingLoadingIndicator = true
        
        let placeHolderViewSize = CGSize(width: 90, height: 100)
        
        if loadingPlaceholder == nil {
            if let superView = superView{
                loadingPlaceholder = UIView(frame: CGRect(x: (superView.width - placeHolderViewSize.width) / 2, y: (superView.height - placeHolderViewSize.height) / 2, width: placeHolderViewSize.width, height: placeHolderViewSize.height))
            }
            else{
                loadingPlaceholder = UIView(frame: CGRect(x: (view.width - placeHolderViewSize.width) / 2, y: (collectionView.height + collectionView.y + 64 - placeHolderViewSize.height) / 2, width: placeHolderViewSize.width, height: placeHolderViewSize.height))
            }
        }
        
        if loadingIndicator == nil {
            loadingIndicator = MMRefreshAnimator(frame: CGRect(x: 0, y: 0, width: placeHolderViewSize.width, height: 80))
            loadingPlaceholder?.addSubview(loadingIndicator!)
        }
        
        if loadingLabel == nil {
            let label = UILabel(frame: CGRect(x:0, y: 80, width: placeHolderViewSize.width, height: 20))
            label.backgroundColor = UIColor.clear
            label.numberOfLines = 0
            label.textAlignment = NSTextAlignment.center
            label.text = String.localize("LB_LTB_LOADING")
            label.textColor = UIColor.secondary1()
            loadingLabel = label
            loadingPlaceholder?.addSubview(loadingLabel!)
        }
        
        if let superView = superView{
            superView.addSubview(loadingPlaceholder!)
        }
        else{
            self.view.addSubview(loadingPlaceholder!)
        }
        
        loadingIndicator?.animateImageView()
    }
    
    func stopBackgroundLoadingIndicator(){
        
        loadingIndicator?.animateImageView()
        if loadingPlaceholder?.superview != nil { loadingPlaceholder?.removeFromSuperview() }
        showingLoadingIndicator = false
    }
    
    
    
    func setupNavigationBarTitleColor() {
        if let navigationController = self.navigationController {
            DispatchQueue.main.async(execute: {
                navigationController.navigationBar.tintColor = UIColor.primary1()
                navigationController.navigationBar.titleTextAttributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor.black]
            })
        }
    }
    
    func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        return UICollectionViewFlowLayout()
    }
    
    func setMultilineTitle(_ title: String){
        let label = UILabel(frame: CGRect(x:0, y: 0, width: self.navigationController?.navigationBar.width ?? 0, height: self.navigationController?.navigationBar.height ?? 0))
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.center
        label.text = title
        self.navigationItem.titleView = label
    }
    
    func setupNavigationBarWishlistButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        buttonWishlist = ButtonRedDot(type: .custom)
        buttonWishlist?.setImage(UIImage(named: "star_nav bar"), for: .normal)
        buttonWishlist?.frame = CGRect(x:0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonWishlist?.badgeAdjust = CGPoint(x: -20, y: 2)
        buttonWishlist?.redDotAdjust = CGPoint(x: -2, y: 0)
        buttonWishlist?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -14)
        setAccessibilityIdForView("UIBT_WISHLIST", view: buttonWishlist)
    }
    
    func setupNavigationBarCartButton() {
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        buttonCart = ButtonRedDot(number: 0)
        buttonCart?.track_consoleTitle = "购物车" //埋点需要
        buttonCart!.setImage(UIImage(named: "btn_bag_grey"), for: .normal)
        buttonCart!.frame = CGRect(x:0, y: 0, width: ButtonWidth, height: ButtonHeight)
        buttonCart!.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        buttonCart?.badgeAdjust = CGPoint(x: -10, y: -4)
        setAccessibilityIdForView("UIBT_CART", view: buttonCart)
    }
    
    func setupDismissKeyboardGesture() {
        dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboardFromView))
    }
    
    @objc func dismissKeyboardFromView() {
        view.endEditing(true)
    }
    
    @objc func updateButtonCartState() {
        //        buttonCart?.hasRedDot(CacheManager.sharedManager.hasCartItem())
        buttonCart?.setBadgeNumber(CacheManager.sharedManager.numberOfCartItems())
        NotificationCenter.default.post(name: Constants.Notification.updateCartBadgeNotification, object: nil)
    }
    
    @objc func updateButtonWishlistState() {
        buttonWishlist?.hasRedDot(CacheManager.sharedManager.hasWishListItem())
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
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
    
    func showNoConnectionView() {
        if noConnectionView == nil {
            let ViewSize = CGSize(width: self.view.width, height: 198)
            noConnectionView = NoConnectionView(frame: CGRect(x:0, y: (self.view.height - ViewSize.height) / 2.0, width: ViewSize.width, height: ViewSize.height))
        }
        
        if noConnectionView!.superview == nil {
            self.view.addSubview(noConnectionView!)
        }
    }
    
    func dismissNoConnectionView() {
        if let view = noConnectionView, view.superview != nil {
            view.removeFromSuperview()
        }
    }
    
    func collectionViewBottomPadding() -> CGFloat {
        return 0
    }
    
    func collectionViewTopPadding() -> CGFloat {
        return 0
    }
    
    func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    func handleError(_ apiResponse: ApiResponse, statusCode: Int, animated: Bool, reject : ((Error) -> Void)? = nil) {
        
        if let appCode = apiResponse.appCode {
            var msg = String.localize(appCode)
            if let range : Range<String.Index> = msg.range(of: "{0}") {
                if let loginAttempts = apiResponse.loginAttempts {
                    msg = msg.replacingCharacters(in: range, with: "\(Constants.Value.MaxLoginAttempts - loginAttempts)")
                }
            }
            self.showError(msg,animated: animated)
            
            if let reject = reject {
                reject(NSError(domain: "", code: statusCode, userInfo: ["Error" : (String.localize(appCode))]))
            }
        } else {
            self.showError(String.localize("LB_ERROR"),animated: animated)
            
            if let reject = reject {
                reject(NSError(domain: "", code: statusCode, userInfo: nil))
            }
        }
        
    }
    
    func handleError(_ response : DataResponse<Any>, animated: Bool, reject : ((Error) -> Void)? = nil) {
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value){
            self.handleError(resp, statusCode: response.response!.statusCode, animated: true, reject: reject)
        } else {
            self.showError(
                Utils.formatErrorMessage(
                    String.localize("LB_ERROR"),
                    error: response.result.error
                )
                ,animated: animated
            )
            if let reject = reject {
                reject(getError(response))
            }
        }
    }
    
    func getError(_ response : DataResponse<Any>) -> NSError {
        var statusCode = 0
        if let code = response.response?.statusCode {
            statusCode = code
        }
        return NSError(domain: "", code: statusCode, userInfo: nil)
    }
    
    func showNetworkError(_ error: Error?, animated: Bool) {
        let message = Utils.formatErrorMessage(
            String.localize("MSG_ERR_NETWORK_FAIL"),
            error: error
        )
        self.showError(message, animated: animated)
    }
    
    func showError(_ message: String, animated: Bool) {
        guard message.length != 0 else {
            return
        }
        
        var y = CGFloat(0)
        var minHeight = CGFloat(40)
        
        if let navigationController = self.navigationController as? MmNavigationController {
            if navigationController.navigationBarVisibility != .hidden && !navigationController.isNavigationBarHidden {
                y = navigationController.navigationBar.frame.maxY
            } else {
                minHeight = 60
            }
        } else if let navigationController = self.navigationController {
            if navigationController.isNavigationBarHidden == true {
                minHeight = 60
            } else {
                y = navigationController.navigationBar.frame.maxY
            }
        }
        
        var height = StringHelper.heightForText(message, width: self.view.bounds.width - 10, font: UIFont.systemFontWithSize(14)) + 10
        if height < minHeight {
            height = minHeight
        }
        
        if errorView == nil {
            errorView = IncorrectView()
            errorView!.displayTime = 3
            self.view.addSubview(errorView!)
        }
        
        errorView!.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: height)
        
        if errorView!.delegate == nil {
            errorView!.delegate = self
        }
        errorView!.showMessage(message, animated: animated)
    }
    
    func checkNetworkConnection(_ isHiddenCollectionView: Bool, reloadHandler: (() -> Void)? = nil, completion: (()->())?) -> Bool{
        if Reachability.shared().currentReachabilityStatus() == NotReachable {
            self.dismissNoConnectionView()
            self.showLoading()
            self.loadingDelayAction = DelayAction(delayInSecond: 2.0, actionBlock: { [weak self] in
                if let strongSelf = self{
                    DispatchQueue.main.async(execute: {
                        strongSelf.stopLoading()
                        strongSelf.showNoConnectionView(isHiddenCollectionView, reloadHandler: reloadHandler)
                        completion?()
                    })
                }
                else{
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
            
            return false
        }
        
        self.loadingDelayAction?.cancel()
        self.loadingDelayAction = nil
        
        return true
    }
    
    func isNetworkReachable() -> Bool{
        return !(Reachability.shared().currentReachabilityStatus() == NotReachable)
    }
    
    func showNoConnectionView(_ isHiddenCollectionView: Bool = true, reloadHandler: (() -> Void)? = nil){
        self.collectionView?.isHidden = isHiddenCollectionView
        
        if isHiddenCollectionView{
            self.showNoConnectionView()
            
            if let noConnectionView = self.noConnectionView {
                self.view.bringSubview(toFront: noConnectionView)
                noConnectionView.reloadHandler = {
                    reloadHandler?()
                }
            }
        }
    }
    
    // Back button clicked event's
    @objc func backButtonClicked(_ button: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func bottomButtonAction(_ button: UIButton) {
        print("bottomButtonAction")
    }
    
    // Override back button of navigation bar
    
    func createBackButton() {
        
        //MM-22244 Container to reduce tap area of back button
        let container = UIView(frame: CGRect(x:0, y: 0, width: Constants.Value.BackButtonWidth + 15, height: Constants.Value.BackButtonHeight + 20))
        
        buttonBack = UIButton(type: .custom)
        buttonBack?.setImage(UIImage(named: "back_grey"), for: .normal)
        buttonBack?.frame = CGRect(x:0, y: 0, width: container.width, height: container.height)
        let verticalPadding = (container.height - Constants.Value.BackButtonHeight)/2
        buttonBack?.contentEdgeInsets = UIEdgeInsets.init(top: verticalPadding, left: 0, bottom: verticalPadding, right: (container.width - Constants.Value.BackButtonWidth))
        buttonBack?.addTarget(self, action: #selector(MmViewController.backButtonClicked(_:)), for: .touchUpInside)
        buttonBack?.accessibilityIdentifier = "UIBT_BACK"
        container.addSubview(buttonBack!)
        let backButtonItem = UIBarButtonItem(customView: container)
        self.navigationItem.leftBarButtonItem = backButtonItem
    }
    
    func setAccessibilityIdForView(_ identifier:String, view:UIView?){
        if let view = view{
            view.accessibilityIdentifier = pageAccessibilityId + "-" + identifier
        }
    }
    
    // Override this function to create different back button style
    func createBackButton(_ buttonStyle: ButtonStyle) {
        createBackButton()
        
        var buttonBackImageName : String?
        
        switch (buttonStyle) {
        case .grayColor:
            buttonBackImageName = "back_grey"
        case .whiteColor:
            buttonBackImageName = "back_wht"
        case .cross:
            buttonBackImageName = "icon_cross"
        case .crossSmall:
            buttonBackImageName = "btn_close"
        case .cancelTitle:
            buttonBackImageName = nil
            self.formatCancelTextButton(buttonBack)
        }
        
        if let imageName = buttonBackImageName {
            buttonBack?.setImage(UIImage(named: imageName), for: .normal)
            self.navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.secondary4()], for: .normal)
        }else {
            buttonBack?.setImage(nil, for: .normal)
        }
        
    }
    
    
    func createRightButton(_ title: String = "", action: Selector) {
        let rightButton = UIButton(type: UIButtonType.system)
        rightButton.setTitle(title, for: .normal)
        rightButton.titleLabel?.formatSize(14)
        rightButton.setTitleColor(UIColor.primary1(), for: .normal)
        rightButton.setTitleColor(UIColor.secondary1(), for: .disabled)
        rightButton.setTitleColor(UIColor.primary1().alpha(0.3), for: .highlighted)
        
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Constants.Value.BackButtonHeight)
        let boundingBox = title.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: rightButton.titleLabel!.font], context: nil)
        rightButton.frame = CGRect(x: 0, y: 0, width: boundingBox.width, height: Constants.Value.BackButtonHeight)
        rightButton.addTarget(self, action: action, for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    
    func createRightButton(_ title: String = "", action: Selector,isEnable: Bool) {
        let rightButton = UIButton(type: UIButtonType.system)
        rightButton.setTitle(title, for: .normal)
        rightButton.titleLabel?.formatSize(14)
        rightButton.setTitleColor(UIColor.white, for: .normal)
        if isEnable {
            rightButton.backgroundColor = UIColor.primary1()
        } else {
            rightButton.backgroundColor = UIColor.secondary1()
        }
        rightButton.layer.cornerRadius = 3
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Constants.Value.BackButtonHeight)
        let boundingBox = title.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: rightButton.titleLabel!.font], context: nil)
        rightButton.frame = CGRect(x: 0, y: 0, width: boundingBox.width + 20, height: Constants.Value.BackButtonHeight)
        rightButton.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    
    func createRightButtonWithImage(_ title: String = "", imageName:String = "", action: Selector) {
        let imageView = UIImageView(image: UIImage(named: imageName))
        let rightButton = UIButton(type: UIButtonType.system)
        rightButton.setTitle(title, for: .normal)
        rightButton.titleLabel?.formatSmall()
        rightButton.setTitleColor(UIColor.primary1(), for: .normal)
        rightButton.setTitleColor(UIColor.secondary1(), for: .disabled)
        rightButton.setTitleColor(UIColor.primary1().alpha(0.3), for: .highlighted)
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Constants.Value.BackButtonHeight)
        let imageViewWith = imageView.image?.size.width ?? 0
        let boundingBox = title.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: rightButton.titleLabel!.font], context: nil)
        rightButton.frame = CGRect(x: 0, y: 0, width: boundingBox.width + imageViewWith * 2, height: Constants.Value.BackButtonHeight)
        
        var frame = imageView.frame
        frame.origin.x = rightButton.bounds.maxX - imageViewWith
        frame.origin.y = rightButton.center.y - (imageView.image?.size.height)! / 2
        imageView.frame = frame
        rightButton.addSubview(imageView)
        rightButton.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    
    func createRightCancelButton(_ action: Selector) {
        self.createRightButton(String.localize("LB_CA_CANCEL"), action: action)
    }
    
    func formatCancelTextButton(_ button: UIButton?){
        button?.setTitle(String.localize("LB_CA_CANCEL"), for: .normal)
        button?.setTitleColor(UIColor.secondary4(), for: .normal)
        button?.titleLabel?.formatSize(14)
    }
    
    func createBottomButton(_ title: String, customAction: Selector?, useSecondaryStyle: Bool = false) {
        bottomButtonContainer = UIView()
        bottomButton = UIButton()
        bottomButton?.accessibilityIdentifier = "bottom_button"
        bottomButtonContainer!.frame = CGRect(
            x: 0,
            y: view.frame.size.height - ScreenBottom - Constants.BottomButtonContainer.Height,
            width: view.frame.size.width,
            height: Constants.BottomButtonContainer.Height
        )
        
        bottomButton!.frame = CGRect(
            x: Constants.BottomButtonContainer.MarginHorizontal,
            y: Constants.BottomButtonContainer.MarginVertical,
            width: (bottomButtonContainer?.frame.size.width)! - (Constants.BottomButtonContainer.MarginHorizontal * 2),
            height: (bottomButtonContainer?.frame.size.height)! - (Constants.BottomButtonContainer.MarginVertical * 2)
        )
        
        if useSecondaryStyle {
            bottomButton!.formatSecondary()
            bottomButton!.setTitleColor(UIColor.primary1(), for: .normal)
        } else {
            bottomButton!.formatPrimary()
            bottomButton!.setTitleColor(UIColor.white, for: .normal)
        }
        
        bottomButton!.setTitle(title, for: .normal)
        
        if customAction != nil && self.responds(to: customAction!) {
            bottomButton!.addTarget(self, action: customAction!, for: .touchUpInside)
        } else {
            bottomButton!.addTarget(self, action: #selector(MmViewController.bottomButtonAction), for: .touchUpInside)
        }
        
        bottomButtonContainer?.addSubview(bottomButton!)
        self.view.addSubview(bottomButtonContainer!)
    }
    
    func updateBottomButtonStyle(_ enabled: Bool, updateState: Bool) {
        if bottomButton != nil {
            if enabled {
                bottomButton!.layer.borderWidth = 0
                bottomButton!.backgroundColor = UIColor.primary1()
                bottomButton!.setTitleColor(UIColor.white, for: .normal)
            } else {
                bottomButton!.layer.borderColor = UIColor.primary1().cgColor
                bottomButton!.layer.borderWidth = Constants.Button.BorderWidth
                bottomButton!.backgroundColor = UIColor.white
                bottomButton!.setTitleColor(UIColor.primary1(), for: .normal)
            }
            
            if updateState {
                bottomButton!.isEnabled = enabled
            }
        }
    }

    func promptCreateNewFeed(_ photoCollageViewController: NewPhotoCollageViewController){
        let navController = MmNavigationController()
        navController.viewControllers = [photoCollageViewController]
        self.present(navController, animated: true, completion: nil)
    }
    
    // MARK: Navigation Bar Button's Function
    
    @objc func goToShoppingCart(_ sender: UIButton) {
        Navigator.shared.dopen(Navigator.mymm.website_cart)
    }
    
    @objc func goToWishList(_ sender: UIButton) {
        // detect guest mode
        guard (LoginManager.getLoginState() == .validUser) else {
//            self.currentContinueAction = GuestContinueAction(guestContinueActionType: .gotoWishlist)
            LoginManager.goToLogin {
                self.goToWishList(sender)
            }
            return
        }
        
        if let controllers = self.navigationController?.viewControllers {
            if controllers.count > 1 && self is ShoppingCartViewController && controllers[controllers.count - 2] is MyCollectionViewController {
                self.navigationController?.popToViewController(controllers[controllers.count - 2], animated: true)
                sender.analyticsViewKey = analyticsViewRecord.viewKey
                //record action
                sender.recordAction(.Tap, sourceRef: "Collection", sourceType: .Button, targetRef: "MyCollection", targetType: .View)
                return
                
            }
        }
        self.navigationController?.pushViewController(MyCollectionViewController(), animated: true)
        //make sure view key not empty
        sender.analyticsViewKey = analyticsViewRecord.viewKey
        //record action
        sender.recordAction(.Tap, sourceRef: "Collection", sourceType: .Button, targetRef: "MyCollection", targetType: .View)
    }
    
    func customServiceButtonTapped(_ sender: UIButton) {
        if let url = ContentURLFactory.urlForContentType(.mmContactUs) {
            navigationController?.pushViewController(ContactUsDetailViewController(title: String.localize("LB_CA_MY_ACCT_CONTACT_US"), urlGetContentPage: url, push: false), animated: true)
        }
        
        sender.analyticsViewKey = analyticsViewRecord.viewKey
        sender.recordAction(.Tap, sourceRef: "CustomerSupport", sourceType: .Button, targetRef: "Chat-Customer", targetType: .View)
    }
    
    // MARK: Keyboard show/hide observer
    
    @objc func keyboardWillShowNotification(_ notification: NSNotification) {
        if let dismissKeyboardGesture = dismissKeyboardGesture {
            view.addGestureRecognizer(dismissKeyboardGesture)
        }
    }
    
    @objc func keyboardDidShowNotification(_ notification: NSNotification) {
        
    }
    
    @objc func keyboardWillHideNotification(_ notification: NSNotification) {
        if let dismissKeyboardGesture = dismissKeyboardGesture {
            view.removeGestureRecognizer(dismissKeyboardGesture)
        }
    }
    // MARK: - Override Volume Button
    
    func setupVolumeButtonHandler() {}
    
    // MARK: - MMAnalytics
    
    func initAnalyticsViewRecord(_ authorRef: String? = nil,
                                 authorType: String? = nil,
                                 brandCode: String? = nil,
                                 merchantCode: String? = nil,
                                 referrerRef: String? = nil,
                                 referrerType: String? = nil,
                                 viewDisplayName: String? = nil,
                                 viewParameters: String? = nil,
                                 viewLocation: String? = nil,
                                 viewRef: String? = nil,
                                 viewType: String? = nil) {
        
        analyticsViewRecord.authorRef = authorRef ?? ""                     // GUID or UserKey
        analyticsViewRecord.authorType = authorType ?? ""                   // Curator, User
        analyticsViewRecord.brandCode = brandCode ?? ""                     //
        analyticsViewRecord.merchantCode = merchantCode ?? ""               //
        analyticsViewRecord.referrerRef = referrerRef ?? ""                 // GUID or UserKey or Link definition
        analyticsViewRecord.referrerType = referrerType ?? ""               // Curator, User, Link
        analyticsViewRecord.viewDisplayName = viewDisplayName ?? ""         //
        analyticsViewRecord.viewParameters = viewParameters ?? ""           //
        analyticsViewRecord.viewLocation = viewLocation ?? ""               // PDP
        analyticsViewRecord.viewRef = viewRef ?? ""                         // GUID or "NJMU5588"
        analyticsViewRecord.viewType = viewType ?? ""                       // Product
        
    }
    
    @discardableResult
    func recordImpression(_ authorRef: String? = nil,
                          authorType: String? = nil,
                          brandCode: String? = nil,
                          impressionRef: String? = nil,
                          impressionType: String? = nil,
                          impressionVariantRef: String? = nil,
                          impressionDisplayName: String? = nil,
                          merchantCode: String? = nil,
                          parentRef: String? = nil,
                          parentType: String? = nil,
                          positionComponent: String? = nil,
                          positionIndex: Int? = nil,
                          positionLocation: String? = nil,
                          referrerRef: String? = nil,
                          referrerType: String? = nil) -> String {
        
        
        return AnalyticsManager.sharedManager.recordImpression(authorRef, authorType: authorType, brandCode: brandCode, impressionRef: impressionRef, impressionType: impressionType, impressionVariantRef: impressionVariantRef, impressionDisplayName: impressionDisplayName, merchantCode: merchantCode, parentRef: parentRef, parentType: parentType, positionComponent: positionComponent, positionIndex: positionIndex, positionLocation: positionLocation, referrerRef: referrerRef, referrerType: referrerType, viewKey: analyticsViewRecord.viewKey)
    }
    
    
    func showPopupConfirmReport(_ report : ((_ confirm: Bool)->())?) {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let confirmAction = UIAlertAction(title: String.localize("LB_CA_REPORT"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            
            
            if let action = report {
                action(true)
            }
            
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .cancel, handler: { (alert: UIAlertAction!) -> Void in
            if let action = report {
                action(false)
            }
        })
        
        optionMenu.addAction(confirmAction)
        optionMenu.addAction(cancelAction)
        
        optionMenu.view.tintColor = UIColor.secondary2()
        
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    func scrollToTop(){
        if let collectionView = self.collectionView {
            collectionView.scrollToTopAnimated(true)
            self.refresh()
        }
    }
    
    func refresh(){ //Will be overridden
        
    }
    
    func updateTopConstraint(_ constraint: NSLayoutConstraint) {
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController, !navigationController.isNavigationBarHidden {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        constraint.constant = navigationBarMaxY
    }
    
    func updateBottomConstraint(_ constraint: NSLayoutConstraint) {
        if let tabBarController = self.tabBarController, let nav = self.navigationController, nav.viewControllers.count == 1 {
            tabBarHeight = tabBarController.tabBar.bounds.height
        }
        constraint.constant = tabBarHeight
    }
    
    func configImageViewer() {
        SKPhotoBrowserOptions.displayCounterLabel = false                         // counter label will be hidden
        SKPhotoBrowserOptions.displayBackAndForwardButton = false                 // back / forward button will be hidden
        SKPhotoBrowserOptions.displayAction = false                               // action button will be hidden
        SKPhotoBrowserOptions.displayDeleteButton = false                          // delete button will be shown
        SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false            // horizontal scroll bar will be hidden
        SKPhotoBrowserOptions.displayVerticalScrollIndicator = false              // vertical scroll bar will be hidden
        SKPhotoBrowserOptions.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        SKPhotoBrowserOptions.displayCloseButton = false
        SKPhotoBrowserOptions.enableSingleTapDismiss = true
    }
}

extension MmViewController: MMPageViewControllerDelegate {
    func setIndex(index: Int) {
        self.index = index
    }
    
    func getIndex() -> Int {
        return index
    }
}

