//
//  SwipeMenu.swift
//  merchant-ios
//
//  Created by HungPM on 4/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SwipeMenu: UIView {
    
    static let SwipeMenuHeight = CGFloat(44)
    
    private static let RedBorderImage = UIImage(named: "bar_swiping_1")
    private static let RedBackgroundImage = UIImage(named: "bar_swiping_on")
    private static let GrayBorderImage = UIImage(named: "bar_swiping_off")
    private static let SwipeButtonNormalImage = UIImage(named: "swipe_btn")
    private static let SwipeButtonHighlightedImage = UIImage(named: "swipe_btn_on")
    private static let SwipeArrowImage = UIImage(named: "icon_swipeArrow")
    
    private final let BuyButtonWidth = CGFloat(44)
    private final let PaddingTopInactiveBorder = CGFloat(2)
    private final let ExpectPercent: CGFloat = 0.7
    private final let ExtendWidth = CGFloat(20)
    private final let ImageEffectMargin = CGFloat(7)
    
    private let swipeButton = UIButton()
    private let idleLabel = SwipeAnimatingView(frame: CGRect.zero)
    private let swipingView = UIView()
    private let idleView = UIView()
    
    private let swipingBackgroundView = UIImageView()
    
    private var swipeDistance: CGFloat {
        get {
            return bounds.width - BuyButtonWidth
        }
    }
    private var isAnimating = false
    private var centerText = false
    
    private var swiping = false {
        didSet {
            if swiping {
                swipeButton.isSelected = true
                UIView.animate(withDuration: 0.2, animations: {
                    self.swipingView.alpha = 1
                    self.idleView.alpha = 0
                })
            } else {
                swipeButton.isSelected = false
                UIView.animate(withDuration: 0.2, animations: {
                    self.swipingView.alpha = 0
                    self.idleView.alpha = 1
                })
            }
        }
    }
    
    var price: String? {
        //Display single price (it means don't display retail price and sale price
        didSet {
            if let value = price {
                idleLabel.fadingText = formateAttributedPriceString(value)
            } else {
                idleLabel.fadingText = nil
            }
        }
    }
    
    @available(*, deprecated, message : "renamed to triggerHandler")
    var doBuy: ((_ bySwipe: Bool?) -> ())? {
        didSet {
            triggerHandler = doBuy
        }
    }
    
    var doBuyBolock: ((_ bySwipe: Bool?) -> ())? {
        didSet {
            triggerHandler = doBuyBolock
        }
    }
    
    var triggerHandler: ((_ bySwipe: Bool?) -> ())?
    
    var staticText: NSAttributedString? {
        get {
            return idleLabel.staticText
        }
        set {
            idleLabel.staticText = newValue
        }
    }
    
    private func layoutSwipeToBuyButton() {
        swipeButton.frame = CGRect(x: 0, y: 0, width: BuyButtonWidth, height: BuyButtonWidth)
        swipeButton.setBackgroundImage(SwipeMenu.SwipeButtonNormalImage, for: UIControlState())
        swipeButton.setBackgroundImage(SwipeMenu.SwipeButtonHighlightedImage, for: .highlighted)
        swipeButton.setBackgroundImage(SwipeMenu.SwipeButtonHighlightedImage, for: .selected)
        swipeButton.addTarget(self, action: #selector(SwipeMenu.trigger), for: .touchUpInside)
        swipeButton.accessibilityIdentifier = "UIBT_SWIPE_PAY"
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeMenu.handlePan))
        swipeButton.addGestureRecognizer(recognizer)
    }
    
    private func layoutSwipingView() {
        swipingView.frame = bounds
        swipingView.backgroundColor = UIColor.clear
        swipingView.alpha = 0
        
        // red border
        let borderView = UIImageView(frame: bounds)
        borderView.image = SwipeMenu.RedBorderImage
        swipingView.addSubview(borderView)
        
        // red background
        swipingBackgroundView.frame = bounds
        swipingBackgroundView.image = SwipeMenu.RedBackgroundImage
        swipingView.addSubview(swipingBackgroundView)
        
        // Label: 滑动购买
        let swipeLabel = UILabel(frame: bounds)
        if centerText {
            swipeLabel.formatSize(12)
        } else {
            swipeLabel.format()
        }
        swipeLabel.text = String.localize("LB_CA_SWIPE_TO_BUY")
        swipeLabel.textColor = UIColor(hexString: "#ea274b")
        swipeLabel.textAlignment = .center
        swipingView.addSubview(swipeLabel)
        
        // Arrow image view
        let MarginRight = CGFloat(10)
        let ArrowSizeWidth = CGFloat(15)
        let arrowImageView = UIImageView(frame: CGRect(x: swipingView.frame.width - ArrowSizeWidth - MarginRight, y: (swipingView.frame.height - ArrowSizeWidth) / 2, width: ArrowSizeWidth, height: ArrowSizeWidth))
        arrowImageView.image = SwipeMenu.SwipeArrowImage
        arrowImageView.contentMode = .scaleAspectFit
        swipingView.addSubview(arrowImageView)
    }
    
    private func layoutIdleView() {
        idleView.frame = bounds
        idleView.backgroundColor = UIColor.clear
        
        // gray border
        let borderView = UIImageView(frame: UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: PaddingTopInactiveBorder, left: 0, bottom: PaddingTopInactiveBorder, right: 0)))
        borderView.image = SwipeMenu.GrayBorderImage
        idleView.addSubview(borderView)
        
        //price label
        let leftPadding = CGFloat(2)
        let rightPadding = CGFloat(11)
        let topPadding = CGFloat(3)
        let bottomPadding = CGFloat(3)
        
        idleLabel.frame = UIEdgeInsetsInsetRect(borderView.bounds, UIEdgeInsets(top: topPadding, left: swipeButton.frame.width + leftPadding, bottom: bottomPadding, right: rightPadding))
        idleLabel.maskingText = formateAttributedDescriptionString(String.localize("LB_CA_SWIPE_TO_BUY") + ">")
        
        borderView.addSubview(idleLabel)
        
    }
    
    init(price: String?, width: CGFloat = 180, centerText: Bool = false) {
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: SwipeMenu.SwipeMenuHeight))
        
        //      |                 |               |
        //  swipingView       idleView        swipeButton     <---  ( Eye )
        //      |                 |               |
        //
        
        self.centerText = centerText
        
        layoutSwipeToBuyButton()
        layoutSwipingView()
        layoutIdleView()
        
        addSubview(swipingView)
        addSubview(idleView)
        addSubview(swipeButton)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutReleasePan() {
        if (swipeButton.frame.maxX) > swipeDistance * ExpectPercent {
            snapToEnd()
        } else {
            snapToBegin()
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            swiping = true
        } else if recognizer.state == .changed {
            
            let translation = recognizer.translation(in: self)
            let maxDistance = swipeDistance // only calcualte once
            let xPos = min(max(translation.x, 0), maxDistance) // limited to 0 < x < maxDistance
            
            swipingBackgroundView.alpha = xPos / maxDistance
            
            var frame = swipeButton.frame
            frame.origin.x = xPos
            swipeButton.frame = frame
            
        } else if recognizer.state == .ended {
            layoutReleasePan()
        } else if recognizer.state == .cancelled {
            layoutReleasePan()
        } else {
            layoutReleasePan()
        }
    }
    
    private func snapToEnd() {
        let trigger = {
            self.trigger(bySwipe: true)
            
            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                self.snapToBegin()
            }
        }
        
        var frame = swipeButton.frame
        if(frame.maxX < bounds.maxX) {
            frame.origin.x = bounds.maxX - frame.width
            UIView.animate(
                withDuration: 0.3,
                animations: { () -> Void in
                    self.swipeButton.frame = frame
                    self.swipingBackgroundView.alpha = 1
                },
                completion: { (success) in
                    trigger()
                }
            )
        } else {
            trigger()
        }
    }
    
    private func snapToBegin() {
        var frame = swipeButton.frame
        if(frame.origin.x > 0) {
            frame.origin.x = 0
            UIView.animate(
                withDuration: 0.3,
                animations: { () -> Void in
                    self.swipeButton.frame = frame
                    self.swipingBackgroundView.alpha = 0
                },
                completion: { success in
                    self.swiping = false
                }
            )
        } else {
            swiping = false
        }
    }
    
    private func formateAttributedPriceString(_ string: String?) -> NSAttributedString? {
        
        guard let value = string else {
            return nil
        }
        
        return NSAttributedString(string: value, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)])
        
    }
    
    private func formateAttributedDescriptionString(_ string: String?) -> NSAttributedString? {
        
        guard let value = string else {
            return nil
        }
        
        return NSMutableAttributedString(string: value, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)])
        
    }
    
    @objc func trigger(bySwipe: Bool = false) {
        if let callback = triggerHandler {
            callback(bySwipe)
        }
    }
    
    deinit {
        Log.debug("SwipeMenu deinit")
    }
    
}
