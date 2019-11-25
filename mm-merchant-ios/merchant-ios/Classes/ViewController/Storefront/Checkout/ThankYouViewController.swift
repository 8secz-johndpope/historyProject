//
//  ThankYouViewController.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 4/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ThankYouViewController: MmViewController {
    
    let thankYouView = ThankYouView()
    var handleGotoProduct: (() -> Void)?
    var handleDismiss: (() -> Void)?
    var handleContinueShopping: (() -> Void)?
    var didSelectProduct: ((Style)->())?
    
    var parentOrder: ParentOrder?
    
    var fromViewController: UIViewController?
    
    private final let FeatureCellWidth: CGFloat = 140
    private final let FeatureCellHeight: CGFloat = 154
    private final let LineSpacing: CGFloat = 4
    
    var timer: Timer?
    var isSecondaryFormat = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAnalyticLog()
        self.createSubview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        
        if !isSecondaryFormat {
            timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(ThankYouViewController.autoDismiss), userInfo: nil, repeats: false)
        }else{
            thankYouView.secondaryFormat()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.thankYouView.continueButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
    }
    
    func createSubview() {
        self.view.backgroundColor = UIColor.clear
        
        // Setup Thank You View
        self.view.addSubview(thankYouView)
        
        let viewDidTapGesture = UITapGestureRecognizer(target: self, action:#selector(self.actionTapBackGround))
        viewDidTapGesture.delegate = self
        self.view.addGestureRecognizer(viewDidTapGesture)
        
        if let totalPrice = parentOrder?.grandTotal.formatPrice() {
            thankYouView.labelPayment.text = String.localize("LB_CA_PAYMENT_SUCCESSFUL") + " " + totalPrice
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let orderKey = parentOrder?.parentOrderKey {
            thankYouView.labelTaxNum.text = String.localize("LB_CA_TX_NUM") + " : " + orderKey
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        self.collectionView.backgroundColor = UIColor.clear
        self.thankYouView.buttonLink.addTarget(self, action: #selector(self.actionOrder), for: .touchUpInside)
        self.thankYouView.continueButton.addTarget(self, action: #selector(self.actionContinue), for: .touchUpInside)
        self.thankYouView.didSelectProduct = { [weak self] style in
            if let strongSelf = self{
                strongSelf.handleSelectProduct(style)
            }
            else{
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }

        self.thankYouView.didSelectProduct = { [weak self] style in
            if let strongSelf = self{
                strongSelf.handleSelectProduct(style)
            }
            else{
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.8)
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(transparentView, belowSubview: thankYouView)
    }
    
    
    func handleSelectProduct(_ style: Style){
        if let timer = self.timer {
            timer.invalidate()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        self.dismiss(animated: true) { [weak self] in
            if let strongSelf = self {
                
                let pushProductDetailPage: (UINavigationController?)->() = { navigationViewController in
                    Navigator.shared.dopen(Navigator.mymm.website_product_skuId + String(style.defaultSkuId()))
                }
                
                if let _ = strongSelf.fromViewController?.navigationController?.viewControllers.first as? FCheckoutViewController {
                    strongSelf.fromViewController?.dismiss(animated: false, completion: {
                        pushProductDetailPage(nil)
                    })
                }
                else if let _ = strongSelf.fromViewController?.navigationController?.viewControllers.last as? FCheckoutViewController{
                    strongSelf.fromViewController?.navigationController?.popViewController(animated: true)
                    pushProductDetailPage(strongSelf.fromViewController?.navigationController)
                }
                else{
                    pushProductDetailPage(strongSelf.fromViewController?.navigationController)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }


    @objc func autoDismiss() {
        dismissThankYou()
    }
    
    @objc func actionTapBackGround() {
        dismissThankYou()
    }
    
    @objc func actionOrder(_ sender: Any) {
        dismissThankYou()
    }
    
    @objc func actionContinue(_ sender: UIButton) {
        sender.recordAction(
            .Tap,
            sourceRef: "ContinueShopping",
            sourceType: .Button,
            targetRef: "Cart",
            targetType: .View
        )
        
        dismissThankYou()
        
        self.ssn_home()
    }
    
    func dismissThankYou() {
        if let timer = self.timer {
            timer.invalidate()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        self.dismiss(animated: true) { [weak self] in
            if let strongSelf = self {
                if strongSelf.isSecondaryFormat{
                    if let action = strongSelf.handleContinueShopping {
                        action()
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }else{
                    if let action = strongSelf.handleDismiss {
                        action()
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
                
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    
    // MARK: - Gesture delegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else{
            return false
        }
        
        if touchView.isDescendant(of: self.thankYouView.suggestedProductsCollectionView){
            return false
        }
        
        return true
    }
    
    // MARK: - Timer
    

    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            viewLocation: "ThankYou",
            viewRef: parentOrder?.parentOrderKey,
            viewType: "Checkout"
        )
    }
}
