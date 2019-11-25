//
//  UIViewExtension.swift
//  merchant-ios
//
//  Created by Alan YU on 6/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

var blockActionDict: [String : (() -> ())] = [:]

extension UIView {
    
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
    
    func initAnalytics(withViewKey viewKey: String, impressionKey: String? = nil) {
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
    
    class func viewWithScreenSize() -> Self {
        return self.init(frame: UIScreen.main.bounds)
    }
    
    func imageValue() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale);
        
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!;
    }
    
    func round(_ radius: CGFloat) {
        self.layoutIfNeeded()
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
    
    func round() {
        self.layoutIfNeeded()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
    }
    
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let boundView = self.bounds
        let path = UIBezierPath(roundedRect: boundView, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
    func viewBorder(_ color: UIColor = UIColor.black, width: CGFloat = 1) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
    
    func disableScrollToTop(){
        for subView in self.subviews{
            if let subView = subView as? UIScrollView{
                subView.scrollsToTop = false
            }
            
            subView.disableScrollToTop()
        }
    }
    
    func shouldHighlightView(_ isHighlight:Bool, cornerRadius:CGFloat? = nil) {
        
        if isHighlight {
            
            self.layer.borderColor = UIColor.primary1().cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = cornerRadius ?? CGFloat(0)
            
            
        } else {
            
            self.layer.borderColor = UIColor.secondary1().cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = cornerRadius ?? 0

        }
        

    }
    
    func setStyleNoNormal(_ cornerRadius:CGFloat? = nil) {
        
        self.layer.borderColor = UIColor.secondary1().cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = cornerRadius ?? 0
        
    }
    
    class func viewFromNib<T: UIView>(_ named: String) -> T? {
        return Bundle.main.loadNibNamed(named, owner: nil, options: nil)?.first as? T
    }
    //TouchEvent
    private func whenTouch(NumberOfTouche touchNumbers: Int,NumberOfTaps tapNumbers: Int) -> Void {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.numberOfTouchesRequired = touchNumbers
        tapGesture.numberOfTapsRequired = tapNumbers
        tapGesture.addTarget(self, action: #selector(tapActions))
        self.addGestureRecognizer(tapGesture)
    }
    
    func whenTapped(action :@escaping (() -> Void)) {
        _addBlock(NewAction: action)
        whenTouch(NumberOfTouche: 1, NumberOfTaps: 1)
    }
    
    
     @objc func tapActions() {
        _excuteCurrentBlock()
    }
    
    
    private func _addBlock(NewAction newAction:@escaping ()->()) {
        let key = String(describing: NSValue(nonretainedObject: self))
        blockActionDict[key] = newAction
    }
    
    private func _excuteCurrentBlock(){
        let key = String(describing: NSValue(nonretainedObject: self))
        let block = blockActionDict[key]
        block!()
    }

}
