//
//  MasterCouponsContainerViewController.swift
//  merchant-ios
//
//  Created by HungPM on 7/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MasterCouponsContainerViewController: MMPageViewController {

    var merchantId: Int?
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //支持取参数
        if merchantId == nil || merchantId! <= 0 {
            merchantId = self.ssn_Arguments["merchantId"]?.int
        }
 
        title = String.localize("LB_CA_CART_COUPON_CLAIM")
        backgroundColor = UIColor.primary2()
        createBackButton()
        createShareButton()
        
        let height = self.view.frame.maxY - (SEGMENT_Y + SEGMENT_HEIGHT) - tabBarHeight
        
        if let merchantId = self.merchantId, merchantId != Constants.MMMerchantId {
            self.navigateToTabIndex = 1
        } else if let entity = self.ssn_Arguments["entity"]?.string, entity == "merchant" {//切换到商户券
            self.navigateToTabIndex = 1
        }
        
        let merchantCoupon = MasterCouponsViewController()
        merchantCoupon.viewControllerType = .merchantCouponViewController
        merchantCoupon.viewHeight = height
        merchantCoupon.merchantId = merchantId
        merchantCoupon.headerTapHandler = { [weak self] merchant in
            if let strongSelf = self {
                let merchantDetailVC = MerchantProfileViewController()
                merchantDetailVC.merchant = merchant
                merchantDetailVC.hideTabbar = true
                strongSelf.navigationController?.push(merchantDetailVC, animated: true)
            }
        }
        
        let mmCoupon = MasterCouponsViewController()
        mmCoupon.viewControllerType = .mmCouponViewController
        mmCoupon.viewHeight = height
        
        viewControllers = [mmCoupon, merchantCoupon]
        segmentedTitles = [String.localize("LB_CA_PROFILE_MY_COUPON_MYMM"), String.localize("LB_CA_PROFILE_MY_COUPON_MERC")]
    }
    
    //MARK:- Config view
    override func shouldHideTabBar() -> Bool {
        return true
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    
    func createShareButton() {
        
        let ButtonHeight = CGFloat(25)
        let ButtonWidth = CGFloat(30)
        
        let shareButton = UIButton(type: .custom)
        shareButton.frame = CGRect(x: 0, y: 0, width: ButtonWidth, height: ButtonHeight)
        shareButton.setImage(UIImage(named: "ic_share_black"), for: UIControlState())
        shareButton.addTarget(self, action: #selector(MasterCouponsContainerViewController.shareCoupons), for: UIControlEvents.touchUpInside)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -14)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)
    }
    
    //MARK: - View Action
    @objc func shareCoupons() {
        let shareViewController = ShareViewController(screenCapSharing: false)
        
        shareViewController.viewKey = self.analyticsViewRecord.viewKey
        
        shareViewController.didUserSelectedHandler = { (data) in
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            let targetRole: UserRole = UserRole(userKey: data.userKey)
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartMessage(
                    userList: [myRole, targetRole],
                    senderMerchantId: myRole.merchantId
                ),
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        if let convKey = ack.data {
                            let viewController = UserChatViewController(convKey: convKey)
                            let chatModel = ChatModel.init(couponType: MessageContentType.MasterCoupon, merchantId: strongSelf.merchantId ?? 0)
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }, failure: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_1009"))
                    }
                }
            )
        }
        
        shareViewController.didSelectSNSHandler = { [weak self] method in
            if let strongSelf = self {
                var masterCoupon: MasterCouponType = .myMMCoupon //Default is MyMM Coupon Tag
                if strongSelf.currentPageIndex == 1 { //Master Coupon Tab
                    masterCoupon = .merchantCoupon
                }
                ShareManager.sharedManager.shareMasterCoupons(type: masterCoupon, method: method)
            }
        }
        
        
        self.present(shareViewController, animated: false, completion: nil)
    }

}
