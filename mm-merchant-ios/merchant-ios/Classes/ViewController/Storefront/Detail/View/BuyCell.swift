//
//  BuyCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
protocol BuyDelegate: NSObjectProtocol{
    func doBuy(swipe isSwipe: Bool?)
}
class BuyCell : UICollectionViewCell, UIGestureRecognizerDelegate{
    var buyImageView = UIImageView()
    var barImageView = UIImageView()
    var priceLabel = UILabel()
    var textLabel = UILabel()
    var imImageView = UIImageView()
    var moreImageView = UIImageView()
    var borderView = UIView()
    weak var buyDelegate: BuyDelegate?
    var isHideMore: Bool = false
    var barImageWidth: CGFloat?
    var isHidePriceWhenSwipe = false
    
    private final let BuyImageStartX: CGFloat = 15
    private final let BuyImageWidth: CGFloat = 55
    private final let BarImageStartX: CGFloat = 20
    private final let BarImageHeight: CGFloat = 45
    private final let ExpectPercent: CGFloat = 0.7
    private final let PriceMarginLeft: CGFloat = 70
    private final let BarImageMarginTop: CGFloat = 15
    private final let BuyImageMarginTop: CGFloat = 10
    private final let RightIconWidth: CGFloat = 35
    private final let LabelWidth: CGFloat = 100
    private final let CartBeforeSwipe: String = "cart_beforeSwipe"
    private final let BarRest: String = "bar_rest"
    
    
    private var buyImageMaxX: CGFloat?
    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(BuyCell.handlePan(_:)))
        recognizer.delegate = self
        return recognizer
        
    } ()
    
    var moreButtonHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buyImageMaxX = bounds.maxX - (BuyImageStartX * 2 + BuyImageWidth / 2)
        backgroundColor = UIColor.clearColor()
        imImageView.frame = CGRect(x: bounds.maxX - 80, y: bounds.minY + 20, width: RightIconWidth, height: RightIconWidth)
        imImageView.image = UIImage(named: "icon_IM")
        addSubview(imImageView)
        moreImageView.frame = CGRect(x: bounds.maxX - 40, y: bounds.minY + 20, width: RightIconWidth, height: RightIconWidth)
        moreImageView.image = UIImage(named: "icon_more")
        addSubview(moreImageView)
        barImageView.frame = CGRect(x: bounds.minX + 20, y: bounds.minY + BarImageMarginTop, width: barImageWidth ?? bounds.width / 2 - 30, height: 45)
        barImageView.image = UIImage(named: BarRest)
        addSubview(barImageView)
        priceLabel.frame =  CGRect(x: bounds.minX + PriceMarginLeft , y: bounds.minY, width: LabelWidth, height: bounds.height)
        priceLabel.formatSmall()
        priceLabel.font = UIFont.boldSystemFontOfSize(16.0)
        addSubview(priceLabel)
        textLabel.frame =  CGRect(x: bounds.minX + 100, y: bounds.minY, width: LabelWidth, height: bounds.height)
        textLabel.textColor = UIColor.whiteColor()
        textLabel.font = UIFont(name: textLabel.font.fontName, size: 14)
        textLabel.text = String.localize("LB_CA_SWIPE_TO_BUY")
        textLabel.isHidden = true
        addSubview(textLabel)
        buyImageView.frame = CGRect(x: bounds.minX + BuyImageStartX , y: bounds.minY + BuyImageMarginTop, width: BuyImageWidth, height: BuyImageWidth)
        buyImageView.image = UIImage(named: CartBeforeSwipe)
        buyImageView.userInteractionEnabled = true
        buyImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BuyCell.tapToBuy)))
        
        buyImageView.isAccessibilityElement = true
        buyImageView.accessibilityIdentifier = "buy_imageview"
        
        addSubview(buyImageView)
        borderView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)

        self.commonInit()
    }
    func moveBack() {
        var frame = buyImageView.frame
        if(frame.origin.x > BuyImageStartX) {
            frame.origin.x = BuyImageStartX
            UIView.animateWithDuration(
                0.2,
                animations: { () -> Void in
                    self.buyImageView.frame = frame
                },
                completion: { (success) in
                    self.reset()
                }
            )
        }
        else {
            self.reset()
        }
    }
    func moveNext() {
        var frame = buyImageView.frame
        if(frame.origin.x < buyImageMaxX) {
            frame.origin.x = buyImageMaxX!
            UIView.animateWithDuration(
                0.2,
                animations: { () -> Void in
                    self.buyImageView.frame = frame
                },
                completion: { (success) in
                    self.doBuy(swipe: true)
                }
            )
        }
        else {
            self.doBuy(swipe: true)
        }
    }
    
    func tapToBuy() {
        doBuy()
    }
    
    func doBuy(swipe isSwipe: Bool? = false) {
        self.buyDelegate?.doBuy(swipe: isSwipe)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(BuyCell.reset), userInfo: nil, repeats: false)
    }
    func reset() {
        barImageView.frame = CGRect(x: BarImageStartX, y: bounds.minY + BarImageMarginTop, width: barImageWidth ?? bounds.width / 2 - 30, height: BarImageHeight)
        buyImageView.frame = CGRect(x: BuyImageStartX , y: bounds.minY + BuyImageMarginTop, width: BuyImageWidth, height: BuyImageWidth)
        buyImageView.image = UIImage(named: CartBeforeSwipe)
        barImageView.image = UIImage(named: BarRest)
        moreImageView.isHidden = isHideMore
        textLabel.isHidden = true
        var frame =  priceLabel.frame
        frame.origin.x = bounds.minX + PriceMarginLeft
        priceLabel.frame = frame;
        priceLabel.textColor = UIColor.secondary2()
        priceLabel.isHidden = false
    }
    func beginBuy() {
        barImageView.frame = CGRect(x: BarImageStartX, y: bounds.minY + BarImageMarginTop, width: bounds.width - BarImageStartX * 2, height: BarImageHeight)
        buyImageView.image = UIImage(named: "cart_swiping")
        barImageView.image = UIImage(named: "bar_swiping")
        moreImageView.isHidden = true
        textLabel.isHidden = false
        priceLabel.center.x = self.frame.width - 100
        priceLabel.textColor = UIColor.whiteColor()
        priceLabel.isHidden = isHidePriceWhenSwipe
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Began {
            self.beginBuy()
        }
        else if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            if(translation.x < BuyImageStartX || translation.x > buyImageMaxX) {
                return;
            }
            var frame = self.buyImageView.frame
            frame.origin.x = translation.x
            self.buyImageView.frame = frame
        }
        else if recognizer.state == .Ended {
            if (self.buyImageView.frame.maxX - BuyImageStartX) > buyImageMaxX! * ExpectPercent {
                self.moveNext()
            }
            else {
                self.moveBack()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.panRecognizer {
            let translation = self.panRecognizer.translationInView(self.superview)
            // Check for horizontal gesture
            if (fabsf(Float(translation.x)) > fabsf(Float(translation.y))) {
                return true
            }
            return false
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    func moreTapped() {
        if let callback = self.moreButtonHandler {
            callback()
        }
    }
    
    private func commonInit() {
        self.buyImageView.addGestureRecognizer(self.panRecognizer)
        self.moreImageView.userInteractionEnabled = true
        self.moreImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BuyCell.moreTapped)))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
