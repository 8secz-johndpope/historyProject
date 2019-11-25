//
//  ProfilePopupViewController.swift
//  merchant-ios
//
//  Created by LongTa on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

class ProfilePopupViewController: MmViewController, ProfilePopupViewDelegate{

    var profilePopupView: ProfilePopupView!
    var deeplinkPath: String?
    var popupType: ProfilePopupView.PopupType = .Campaign
    var handleDismiss: (() -> ())?
    var viewOrderPressed: (() -> ())?
    
    weak var presentViewController: UIViewController?
    private var user: User?
    private var shareData: Banner?
    
    //By default not full screen, if modalPresentationStyle = .None means FULL SCREEN
    convenience init(presenttationStyle: UIModalPresentationStyle = .overFullScreen) {
        self.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = presenttationStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if modalPresentationStyle != .none {
            navigationController?.isNavigationBarHidden = true
        }
        
        setupLayout()
        
    }
    
    @objc func doneButtonPressed(sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
        if let action = self.handleDismiss {
            action()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let promises = [getUser(), fetchBanners()]
        
        when(fulfilled: promises).then { _ -> Void in
            self.prepareProfilePopupView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    // MARK: Methods
    
    func setupLayout() {
        
        if self.modalPresentationStyle == .none {
            profilePopupView = ProfilePopupView(frame: self.view.bounds, isFullScreen: true)
        } else {
            profilePopupView = ProfilePopupView(frame: self.view.bounds)
        }
        profilePopupView.isHidden = true
        profilePopupView.popupType = self.popupType
        profilePopupView.delegate = self
        profilePopupView.closeButton.addTarget(
            self,
            action: #selector(dismiss as (() -> Void)),
            for: .touchUpInside
        )
        profilePopupView.refereeTNCPressed = { [weak self] in
            self?.showTNCPage()
        }
        
        profilePopupView.viewOrderPressed = {[weak self] in
            if let strongSelf = self {
                strongSelf.viewOrderPressed?()
            }
        }
        
        self.view.addSubview(profilePopupView)
        
        if self.popupType == ProfilePopupView.PopupType.OrderSuccess {
            self.title = String.localize("LB_CA_PAYMENT_SUCCESSFUL")
            self.createRightButton(String.localize("LB_DONE"), action: #selector(ProfilePopupViewController.doneButtonPressed))
            self.navigationItem.hidesBackButton = true
            self.view.backgroundColor = UIColor.white
        } else {
            self.view.backgroundColor = UIColor.clear
            self.title = String.localize("LB_CA_INCENTIVE_REF_SHARE")
            if self.modalPresentationStyle == .none {
                self.createBackButton()
            }
        }
    }
    
    func showTNCPage() {
        if let url = ContentURLFactory.urlForContentType(.mmRefereeTNC), let topViewController = ShareManager.sharedManager.getTopViewController() {
            
            topViewController.push(AboutDetailViewController(title: String.localize("LB_CA_REFERRAL_TNC"), urlGetContentPage: url), animated: true)
        }
    }
    
   @objc func dismiss() {
        self.dismissController()
    }
    
    func dismissController(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.profilePopupView.hideContentView()
        }) { (completed) in
            self.dismiss(animated: false, completion: {
                
            })
        }
    }
    
    /* Remove because of useless
    private func viewMoreInfo(_ sender: UIButton) {
        dismissController(true)
        
        if let user = user {
            // Record button action
            
            var targetRef = "1+1+1T&C"
            var targetType: AnalyticsActionRecord.ActionElement = .Page
            
            if user.isFullyInvitation() {
                targetRef = "Newsfeed-User"
                targetType = .View
            }
            
            sender.recordAction(
                .Tap,
                sourceRef: "LearnMore",
                sourceType: .Link,
                targetRef: targetRef,
                targetType: targetType
            )
        }
    }*/
    
    // MARK: ProfilePopupViewDelegate
    
    func selectedShareMethod(_ method: ShareMethod) {
        if let user = user, let data = shareData {
            let imageURL = ImageURLFactory.URLSize256(data.bannerImage, category: .banner)
            ShareManager.sharedManager.shareReferralCampagin(
                method,
                title: data.bannerName,
                sharePath: data.link,
                shareImageURL: imageURL,
                referralUserKey: user.userKey,
                displayName: user.displayName
            )
        } else {
            // Missing share info
        }
        Log.debug(method)
    }
    
    func getUser() -> Promise<Any> {
        return Promise { fulfill, _ in
            user = Context.getUserProfile()
            
            if let user = user, user.userKey != "" {
                fulfill("ok")
            } else {
                firstly {
                    return fetchUser()
                    }.always {
                        fulfill("ok")
                    }.catch { _ -> Void in
                        Log.error("error")
                        self.dismiss()
                }
            }
        }
    }

    private func prepareProfilePopupView() {
//        profilePopupView.user = user
        if modalPresentationStyle != .none {
            profilePopupView.showContentView(true)
            profilePopupView.tranparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss as () -> Void)))
        }
        initAnalyticLog()
        
        if let banner = shareData {
            let impressionKey = recordImpression(impressionRef: banner.bannerKey, impressionType: "Banner", impressionDisplayName: banner.bannerName, positionComponent: "PopupBanner", positionLocation: "Referral")
            profilePopupView.initAnalytics(withViewKey: analyticsViewRecord.viewKey, impressionKey: impressionKey)
        }
    }
    
    private func fetchUser() -> Promise<Any>{
        return Promise{ fulfill, reject in
            UserService.viewUserByUserKey(Context.getUserKey()) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)
                            fulfill("OK")
                        } else {
                            strongSelf.handleError(response, animated: true, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }

    func fetchBanners() -> Promise<Any> {
        return Promise { fulfill, _ in
            firstly {
                return BannerService.fetchBanners([.referralCouponPage, .referralCouponSNS])
                }.then { (banners) -> Void in
                    if let page = banners.filter({ $0.collectionType == .referralCouponPage }).first , let share = banners.filter({ $0.collectionType == .referralCouponSNS }).first {
                    self.profilePopupView.isHidden = false
                        self.shareData = share
                        self.profilePopupView.labelCampaginDesc.text = page.bannerName.replacingOccurrences(of: "\\n", with: "\n")
                        self.deeplinkPath = page.link
                        
                        ImageCacheManager.loadImage(self.profilePopupView.bannerImageView, URL: ImageURLFactory.URLSize1000(page.bannerImage, category: .banner), placeholderImage: UIImage(named: "tile_placeholder"), completion: { [weak self] (image, error) in
                            if let strongSelf = self {
                                if error == nil {
                                    strongSelf.profilePopupView.bannerImageView.contentMode = .scaleAspectFill
                                    strongSelf.profilePopupView.imageSize = image?.size
                                    strongSelf.profilePopupView.setupLayouts()
                                    strongSelf.profilePopupView.bannerImageView.image = image
                                }
                            }
                            })
                    }
                }.always {
                    fulfill("ok")
            }
        }
    }
    
    // MARK: Logging
    
    private func initAnalyticLog() {
        if let user = user {
            var viewLocation = "1+1+1Details"
            
            if user.isFullyInvitation() {
                viewLocation = "1+1+1Thanks"
            }
            
            initAnalyticsViewRecord(
                nil,
                authorType: nil,
                brandCode: nil,
                merchantCode: nil,
                referrerRef: nil,
                referrerType: nil,
                viewDisplayName: "User: \(Context.getUserProfile().userName)",
                viewParameters: nil,
                viewLocation: viewLocation,
                viewRef: nil,
                viewType: "Campaign"
            )
        }
    }
}
