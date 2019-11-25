//
//  ProductCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class ProductCell: CollectCell, GHContextOverlayViewDelegate, GHContextOverlayViewDataSource {
    
    enum FanActionMenu: Int {
        case fanCart = 0,
        fanConvStart,
        fanPost,
        fanShare,
        unknown
    }
    typealias ValidateStyleBlock = (Style?) -> Void
    private var menu : GHContextMenuView!
	
    override var style : Style? {
        didSet{
            if let style = self.style {
                if style.isCrossBorder {
                    self.nameLabel.addImage("crossbroder", imageWidth: 30/1.5, imageHeight: 15/1.5)
                } else {
                    nameLabel.removeImage()
                }
                
                if style.videoURL.length > 0 {
                    self.playerImageView.isHidden = false
                } else {
                    self.playerImageView.isHidden = true
                }
                
            } else {
                self.playerImageView.isHidden = true
            }
        }
    }
    var styleFilter : StyleFilter?
    var didBuySuccess: ((ParentOrder?) -> ())?
    
    //ownerViewController : For getting current owner view controlle exactly
    //This is for fixing incorrect view controller when in PageViewController
    weak var ownerViewController: MmViewController?
    
    var referrerUserKey: String?
    var longPressGesture: UILongPressGestureRecognizer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.menu = GHContextMenuView()
        self.menu.dataSource = self
        self.menu.delegate = self
        self.nameLabel.lineBreakMode = .byTruncatingTail
        
        longPressGesture = UILongPressGestureRecognizer(target: self.menu, action: #selector(ProductCell.longPressDetected))
        
        if let strongLongPressGesture = longPressGesture{
            self.contentView.addGestureRecognizer(strongLongPressGesture)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc func longPressDetected(_ id: Any) {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- GHContextOverlayViewDataSource
    func numberOfMenuItems() -> Int {
        return 4
    }
    
    func textForItemAtIndex(_ index: Int) -> String {
        if let fanActionMenu = FanActionMenu(rawValue: index){
            switch fanActionMenu {
            case .fanShare:
                return String.localize("LB_CA_SHARE")
            case .fanCart:
                return String.localize("LB_CA_CART")
            case .fanConvStart:
                return String.localize("LB_CA_CONTACT_CS")
            case .fanPost:
                return String.localize("LB_CA_PUBLISH")
            default:
                break
            }
        }
        
        return ""
    }
    
    func imageForItemAtIndex(_ index: Int) -> UIImage! {
        
        var imageName = "fan_cart"
        if let fanActionMenu = FanActionMenu(rawValue: index){
            switch fanActionMenu {
            case .fanShare:
                imageName = "fan_btn_share"
            case .fanCart:
                imageName = "fan_cart"
            case .fanConvStart:
                imageName = "fan_cs"
            case .fanPost:
                imageName = "fan_btn_post"
            default:
                break
            }
        }
        
        return UIImage(named: imageName)
    }
    
    func shouldShowMenuAtPoint(_ point: CGPoint) -> Bool {
        return true
    }
    
    func didSelectItemAtIndex(_ selectedIndex: Int, forMenuAtPoint point: CGPoint) {
        if let fanActionMenu = FanActionMenu(rawValue: selectedIndex) {
            if fanActionMenu == .fanCart || fanActionMenu == .fanPost || fanActionMenu == .fanConvStart {
                if LoginManager.getLoginState() != .validUser {
                    LoginManager.goToLogin {
                        self.didSelectItemAtIndex(selectedIndex, forMenuAtPoint: point)
                    }
                    return
                }
            }
            
            switch fanActionMenu {
            case .fanShare:
                self.recordAction(.Slide, sourceRef: "Share", sourceType: .Button, targetRef: "Share", targetType: .View)
                self.handleShareAction()
            case .fanCart:
                self.recordAction(.Slide, sourceRef: "AddToCart", sourceType: .Button, targetRef: "Checkout", targetType: .View)
                self.handleAddToCartAction()
            case .fanConvStart:
                self.recordAction(.Tap, sourceRef: "CS", sourceType: .Button, targetRef: "Chat-Customer", targetType: .View)
                self.handleChatWithMerchantAction()
            case .fanPost:
                self.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Button, targetRef: "Editor-Image", targetType: .View)
                self.handlePostAction()
            default:
                break
            }
        }
    }
    
    //MARK:- Handle Action
    func handleShareAction() {
        self.validateStyle { [weak self] (data: Style?) in
            if let _ = self, let style = data {
                if let activeViewController = PushManager.sharedInstance.getTopViewController() as? MmViewController {
                    let shareViewController = ShareViewController ()
                    shareViewController.viewKey = activeViewController.analyticsViewRecord.viewKey
                    shareViewController.didUserSelectedHandler = { (data) in
                        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                        let targetRole: UserRole = UserRole(userKey: data.userKey)
                        
                        WebSocketManager.sharedInstance().sendMessage(
                            IMConvStartMessage(
                                userList: [myRole, targetRole],
                                senderMerchantId: myRole.merchantId
                            ),
                            completion: { (ack) in
                                if let convKey = ack.data {
                                    let viewController = UserChatViewController(convKey: convKey)
                                    
                                    let productModel = ProductModel()
                                    productModel.style = style
                                    productModel.sku = style.defaultSku()
                                    
                                    let chatModel = ChatModel.init(productModel: productModel)
                                    chatModel.messageContentType = MessageContentType.Product
                                    
                                    viewController.forwardChatModel = chatModel
                                    activeViewController.navigationController?.pushViewController(viewController, animated: true)
                                }
                        }, failure: {
                            activeViewController.showFailPopupWithText(String.localize("MSG_ERR_NETWORK_1009"))
                        }
                        )
                    }
                    shareViewController.didSelectSNSHandler = { method in
                        if let searchSku = style.defaultSku() {
                            ShareManager.sharedManager.shareProduct(searchSku, suppliedStyle: style, method: method, referrer:  Context.getUserKey())
                        }
                    }
                    activeViewController.present(shareViewController, animated: false, completion: nil)
                }
            }
        }
    }
    
    func handleAddToCartAction() {
        self.validateStyle { (data: Style?) in
            if let style = data {
                if let activeViewController = PushManager.sharedInstance.getTopViewController() as? MmViewController {
                    activeViewController.showLoading()
                    MerchantService.view(style.merchantId) { response in
                        
                        activeViewController.stopLoading()
                        
                        if response.result.isSuccess {
                            if response.response?.statusCode == 200 {
                                if let array = response.result.value as? [[String: Any]], let obj = array.first, let merchant = Mapper<Merchant>().map(JSONObject: obj) {
                                    let selectedColorId = self.styleFilter?.colors.first?.colorId ?? -1
                                    let selectedSizeId = self.styleFilter?.sizes.first?.sizeId ?? -1
                                    
                                    let targetRef = "PLP"
//                                    if let _ = activeViewController as? DiscoverViewController{
//                                        targetRef = "PLP"
//                                    }
                                    
                                    let checkoutViewController = FCheckoutViewController(checkoutMode: .style, merchant: merchant, style: style, referrer: self.referrerUserKey, selectedColorId: selectedColorId, selectedSizeId: selectedSizeId, redDotButton: activeViewController.buttonCart, targetRef: targetRef)
                                    
                                    checkoutViewController.didDismissHandler = { confirmed, parentOrder in
                                        activeViewController.updateButtonCartState()
                                        
                                        if let action = self.didBuySuccess, confirmed {
                                            action(parentOrder)
                                        }
                                    }
                                    
                                    let navigationController = MmNavigationController()
                                    navigationController.viewControllers = [checkoutViewController]
                                    navigationController.modalPresentationStyle = .overFullScreen
                                    
                                    activeViewController.present(navigationController, animated: false, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleChatWithMerchantAction() {
        self.validateStyle { [weak self] (data: Style?) in
            if let _ = self, let style = data {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                var merchantId: Int?
                merchantId = style.merchantId
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartToCSMessage(
                        userList: [myRole],
                        queue: .Presales,
                        senderMerchantId: myRole.merchantId,
                        merchantId: merchantId
                    ),
                    completion: { ack in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            
                            let productModel = ProductModel()
                            productModel.style = style
                            productModel.sku = style.defaultSku()
                            
                            let chatModel = ChatModel.init(productModel: productModel)
                            chatModel.messageContentType = MessageContentType.Product
                            
                            viewController.forwardChatModel = chatModel
                            PushManager.sharedInstance.getTopViewController().navigationController?.pushViewController(viewController, animated: true)
                        }
                }, failure: {
                    if let activeViewController = PushManager.sharedInstance.getTopViewController() as? MmViewController {
                        activeViewController.showFailPopupWithText(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                }
                )
                
            }
        }
    }
    
    func handlePostAction() {
        self.validateStyle { (data : Style?) in
            if let style = data {
                self.openPhotoCollapgePage(style)
            }
        }
    }
    
    func validateStyle(_ callBack: @escaping ValidateStyleBlock) {
        if let style = self.style {
            callBack(style)
        } else {
            if let sku = self.sku {
                if let activeViewController = PushManager.sharedInstance.getTopViewController() as? MmViewController {
                    let merchantIds = [String(sku.merchantId)]
                    activeViewController.showLoading()
                    firstly{
                        return ProductManager.searchStyleWithStyleCode(sku.styleCode, merchantIds: merchantIds)
                        }.then { response -> Void in
                            if let style = response as? Style {
                                callBack(style)
                            }else {
                                callBack(nil)
                            }
                        }.always {
                            activeViewController.stopLoading()
                        }.catch { _ -> Void in
                            Log.error("error")
                            callBack(nil)
                    }
                } else {
                    callBack(nil)
                }
            } else {
                callBack(nil)
            }
        }
    }

    func openPhotoCollapgePage(_ style: Style) {
        let activeViewController = PushManager.sharedInstance.getTopViewController()
        let photoCollageViewController = CreatePostSelectImageViewController()
        photoCollageViewController.fromMenuSelect = true
        photoCollageViewController.selectedStyles = [style]
        let navController = MmNavigationController()
        navController.viewControllers = [photoCollageViewController]
        activeViewController.present(navController, animated: true, completion: nil)
    }
    
    deinit {
        menu.destory()
    }
}
