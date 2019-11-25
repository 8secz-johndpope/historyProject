//
//  UIBarButtonItemExtension.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    
    // MMAnalytics
    
    private struct AssociatedKeys {
        static var analyticsViewKey: String?
        static var analyticsImpressionKey: String?
    }
    
    var analyticsViewKey: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.analyticsViewKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.analyticsViewKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var analyticsImpressionKey: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.analyticsImpressionKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.analyticsImpressionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func initAnalytics(withViewKey viewKey: String?, impressionKey: String? = nil) {
        self.analyticsViewKey = viewKey
        self.analyticsImpressionKey = impressionKey
    }
    
    func recordAction(_ actionTrigger: AnalyticsActionRecord.ActionTriggerType = .Unknown, sourceRef: String? = nil, sourceType: AnalyticsActionRecord.ActionElement = .Unknown, targetRef: String? = nil, targetType: AnalyticsActionRecord.ActionElement = .Unknown) {
        let analyticsActionRecord = AnalyticsActionRecord()
        
        analyticsActionRecord.viewKey = analyticsViewKey ?? ""
        analyticsActionRecord.impressionKey = analyticsImpressionKey ?? ""
        analyticsActionRecord.actionKey = Utils.UUID()
        
        analyticsActionRecord.actionTrigger = actionTrigger
        analyticsActionRecord.sourceRef = sourceRef ?? ""
        analyticsActionRecord.sourceType = sourceType
        analyticsActionRecord.targetRef = targetRef ?? ""
        analyticsActionRecord.targetType = targetType
        
        AnalyticsManager.sharedManager.recordAction(analyticsActionRecord)
    }
    
    class func createSearchBarButton(_ imageName: String, selectorName: String, target: Any?, size:CGSize,left: CGFloat, right: CGFloat) -> UIBarButtonItem {
        let buttonSearch = UIButton()
        buttonSearch.setImage(UIImage(named: imageName), for: UIControlState())
        buttonSearch.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        buttonSearch.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: left, bottom: 0, right: right)
        buttonSearch.addTarget(target, action:Selector(selectorName), for: .touchUpInside)
        
        let temp: UIBarButtonItem = UIBarButtonItem()
        temp.customView = buttonSearch
        
        return temp
    }
    
    class func createBackItem(compy: @escaping ((_ button:UIButton) -> Void)) -> UIBarButtonItem {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "back_wht"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
        let temp: UIBarButtonItem = UIBarButtonItem()
        temp.customView = backButton
        compy(backButton)
        return temp
    }
    
    class func createShareItem(compy: @escaping ((_ button:UIButton) -> Void)) -> UIBarButtonItem {
        let shareButton = UIButton(type: .custom)
        shareButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        shareButton.setImage(UIImage(named: "fan_share"), for: .normal)
        shareButton.frame = CGRect(x:0,y:0,width: 40,height:40)
        shareButton.tintColor = UIColor.white
        shareButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, Constants.Value.NavigationButtonMargin)
        let temp: UIBarButtonItem = UIBarButtonItem()
        temp.customView = shareButton
        compy(shareButton)
        return temp
    }
    
    class func createSearchItem(compy: @escaping ((_ customView:UIView) -> Void)) -> UIBarButtonItem {
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenWidth * 0.6, height: 35 ))
        customView.layer.cornerRadius = 4
        customView.layer.masksToBounds = true
        customView.backgroundColor = UIColor.imagePlaceholder()
        
        let searchButton = UIButton()
        searchButton.isUserInteractionEnabled = false
        searchButton.setTitle(String.localize("LB_CA_SEARCH_IN_BRAND"), for: UIControlState.normal)
        searchButton.setImage(UIImage(named: "search"), for: UIControlState.normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        searchButton.setTitleColor(UIColor(hexString: "#BCBCBC"), for: UIControlState.normal)
        searchButton.setIconInLeftWithSpacing(6)
        searchButton.sizeToFit()
        searchButton.frame =  CGRect(x: (customView.width - searchButton.width) / 2, y: (35 - searchButton.height) / 2, width: searchButton.width, height:searchButton.height)
        customView.addSubview(searchButton)
        
        let temp: UIBarButtonItem = UIBarButtonItem()
        temp.customView = customView
        compy(customView)
        return temp
    }
    
    class func createServiceItem(compy: @escaping ((_ button:UIButton) -> Void)) -> UIBarButtonItem {
        let serviceButton = UIButton(type: .custom)
        serviceButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        serviceButton.setImage(UIImage(named: "service_ic"), for: .normal)
        serviceButton.frame = CGRect(x:0,y:0,width: 40,height:40)
        serviceButton.tintColor = UIColor.white
        serviceButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, Constants.Value.NavigationButtonMargin)
        
        let temp: UIBarButtonItem = UIBarButtonItem()
        temp.customView = serviceButton
        compy(serviceButton)
        return temp
    }
}
