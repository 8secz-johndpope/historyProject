//
//  PushManager.swift
//  merchant-ios
//
//  Created by Leslie Zhang on 2017/11/19.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//=======================================================
// MARK: - PushList
// GetTopViewController
// GoToShare
// goToShareWithUser
// GoToPost
// GoToShareWithUser
// GOToShareWithBrand
// GoToChatMerchant
// GoToProfile
// GotoBrandList
// GoToPLP
// GoToMerchantConversation
// GoToSingleRecommend
//=======================================================

import UIKit
import ObjectMapper

class PushManager {
    private init() {
        
    }
    
    static let sharedInstance = PushManager()
    
    //=======================================================
    // MARK: - GetTopViewController
    //=======================================================
    func getTopViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController {
        if let present = base?.presentedViewController {
            if let nav = present as? UINavigationController {
                return nav.topViewController!
            }
        }
        
        if let nav = base as? UINavigationController {
            return nav.topViewController!
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                if let nav = selected as? UINavigationController {
                    return nav.topViewController!
                }
                return selected
            }
        }

        return base!
    }
    
    //=======================================================
    // MARK: - goToShareWithUser
    //=======================================================
    func goToShareWithUser(_ viewKey:String,viewController:UIViewController,user:User,pushChat: @escaping (_ result:UIViewController)->()) {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = viewKey
        
        shareViewController.didUserSelectedHandler = { (data) in
            
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: data.userKey)
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                checkNetwork: true,
                viewController: viewController,
                completion: { (ack) in
                    if let convKey = ack.data {
                        let chatViewController = UserChatViewController(convKey: convKey)
                        
                        let userModel = UserModel()
                        userModel.user = user
                        let chatModel = ChatModel(userModel: userModel)
                        chatModel.messageContentType = MessageContentType.ShareUser
                        
                        chatViewController.forwardChatModel = chatModel
                        pushChat(chatViewController)
                    } else {
                        return
                    }
            }
            )
        }
        
        shareViewController.didSelectSNSHandler = { method in
            ShareManager.sharedManager.shareUser(user, method: method)
            
        }
        getTopViewController().present(shareViewController, animated: false, completion: nil)
    }
    
    //=======================================================
    // MARK: - goToShareWithBrand
    //=======================================================
    func goToShareWithBrandOrMerchant(_ viewKey:String,brand:Brand? = nil,merchant:Merchant? = nil) {
        let shareViewController = ShareViewController ()
        
        shareViewController.viewKey = viewKey
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(userList: [myRole, targetRole], senderMerchantId: myRole.merchantId),
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            if let brand = brand {
                                let brandModel = BrandModel()
                                brandModel.brand = brand
                                let chatModel = ChatModel.init(brandModel: brandModel)
                                chatModel.messageContentType = MessageContentType.ShareBrand
                                viewController.forwardChatModel = chatModel
                            } else if let merchant = merchant {
                                let merchantModel = MerchantModel()
                                merchantModel.merchant = merchant
                                let chatModel = ChatModel.init(merchantModel: merchantModel)
                                chatModel.messageContentType = MessageContentType.ShareMerchant
                                viewController.forwardChatModel = chatModel
                            }
                        strongSelf.getTopViewController().navigationController?.pushViewController(viewController, animated: true)
                        }
                }, failure: {
                    return
                   }
                )
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            if let brand = brand {
                ShareManager.sharedManager.shareBrand(brand, method: method)
            }else if let merchant = merchant {
                ShareManager.sharedManager.shareMerchant(merchant, method: method)
            }
        }
        getTopViewController().present(shareViewController, animated: false, completion: nil)
    }
    
    //=======================================================
    // MARK: - goToProfile
    //=======================================================
    func goToProfile(_ user: User, hideTabBar: Bool) {
        guard LoginManager.getLoginState() == .validUser else {
            LoginManager.goToLogin()
            return
        }
        
        Navigator.shared.dopen(Navigator.mymm.deeplink_u_userName + (user.userName.isEmpty ? user.userKey : user.userName))
    }
    
    //=======================================================
    // MARK: - GoToProfile
    //=======================================================
    func gotoPhotoCollage(selectStyleType:PostSelectStyleType,selectedHashTag:String?){
        let photoCollageViewController = CreatePostSelectImageViewController()
        photoCollageViewController.selectStyleType = selectStyleType
        if let selectedHashTag = selectedHashTag {
            photoCollageViewController.selectedHashTag = selectedHashTag
        }
        let navController = UINavigationController()
        navController.viewControllers = [photoCollageViewController]
        self.getTopViewController().present(navController, animated: true, completion: nil)
        self.getTopViewController().view.recordAction(.Tap, sourceRef: "CreatePost", sourceType: .Button, targetRef: "Editor-Image-Album", targetType: .View)
    }
    
    //=======================================================
    // MARK: - GotoBrandList
    //=======================================================
    func gotoBrandList(brandCallback: @escaping (_ brand:Brand)->())  {
        let brandContainerController = BrandListViewController()
        brandContainerController.fromePost = true
        brandContainerController.didSelectBrandHandler = {[weak self] brand in
            if let strongSelf = self {
                brandCallback(brand)
                strongSelf.getTopViewController().navigationController?.popViewController(animated: true)
            }
            
            
        }
        self.getTopViewController().push(brandContainerController, animated: true)
    }
    
    //=======================================================
    // MARK: - goToPLP
    //=======================================================
    func goToPLP(_ brandId:Int? = nil,merchantId:Int? = nil, brand:Brand? = nil,isSearch:Bool? = nil,noNeedBrandFeed:Bool? = nil,styleFilter: StyleFilter? = nil,animated: Bool)  {
        let productListViewController = ProductListViewController()
        
        if let brandModel = brand {
            productListViewController.brand = brandModel
        }
        if let brandModelId = brandId {
            productListViewController.brandId = brandModelId
        }
        if let merchantModelId = merchantId {
            productListViewController.merchantId = merchantModelId
        }
        if let search = isSearch {
            productListViewController.isSearch = search
        }
        if let brandFeed = noNeedBrandFeed {
            productListViewController.noNeedBrandFeed = brandFeed
        }
        if let filter = styleFilter {
            productListViewController.setStyleFilter(filter, isNeedSnapshot: true)
        }
        self.getTopViewController().push(productListViewController, animated: animated)
    }
    
    //=======================================================
    // MARK: - goToMerchantConversation
    //=======================================================
    func goToMerchantConversation(_ merchantId:Int,viewController:UIViewController)  {
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartToCSMessage(
                userList: [myRole],
                queue: .Presales,
                senderMerchantId: myRole.merchantId,
                merchantId: merchantId
            ),
            checkNetwork: true,
            viewController: viewController,
            completion: { [weak self] (ack) in
                if let strongSelf = self {
                    if let convKey = ack.data {
                        let viewController = UserChatViewController(convKey: convKey)
                        strongSelf.getTopViewController().push(viewController, animated: true)
                    }
                }
            }
        )
    }
    
    
    //=======================================================
    // MARK: - goToSingleRecommend
    //=======================================================
    func goToSingleRecommend() {
        guard (LoginManager.getLoginState() == .validUser) else {
            return
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy.MM.dd"
//        dateFormat.dateFormat = "yyyy.MM.dd HH:mm"
        
        let todayTime = dateFormat.string(from: Date())
        
        let defaults = UserDefaults()
        
        if defaults.object(forKey: "popWindowOnceADay") == nil  {
            UserDefaults().set(todayTime , forKey: "popWindowOnceADay")
        }
        
        let dateStr = defaults.object(forKey: "popWindowOnceADay") as? String
        
        if dateStr != todayTime {
            defaults.set(todayTime , forKey: "popWindowOnceADay")
            
            let navigationController = MmNavigationController(rootViewController: SingleRecommendViewController())
            self.getTopViewController().present(navigationController, animated: true, completion: nil)
        } else {
            defaults.set(todayTime , forKey: "popWindowOnceADay")
        }
    }
}

