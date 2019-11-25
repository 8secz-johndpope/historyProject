//
//  SwipeSMSView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
protocol SwipeSMSDelegate : NSObjectProtocol{ //Prevent memory leak
    
    func invalidSwipe()
    func startSMS()
    func resetSMS()
    func beginSwipe()
    
}
class SwipeSMSView : UICollectionViewCell, UIGestureRecognizerDelegate{
    
    var circleView = UIView()
    var overlayView = UIView()
    var greenOverlayView = UIView()
    var barView = UIView()
    var greenView = UIView()
    var textLabel = UILabel()
    var overlayLabel = UILabel()
    weak var swipeSMSDelegate: SwipeSMSDelegate? //Prevent memory leak
    var timeCountdown : CGFloat = 60 //Default value is 60
    var isEnableSwipe : Bool = true
    private final let CircleStartX: CGFloat = 0
    private final let CircleWidth: CGFloat = 45
    private final let BarStartX: CGFloat = 0
    private final let BarHeight: CGFloat = 45
    private final let ExpectPercent: CGFloat = 0.7
    private final let PriceMarginLeft: CGFloat = 70
    private final let BarMarginTop: CGFloat = 0
    private final let BarColor = "#F2F2F2"
    private final let BarColorHighlight = "#8BD739"
    private var circleMaxX: CGFloat = 0
    private var isCountingDown = false
    private var dateTime = Date()
    private var timer : Timer?
    
    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeSMSView.handlePan))
        recognizer.delegate = self
        return recognizer
        
    } ()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        barView.frame = CGRect(x: BarStartX, y: bounds.minY + BarMarginTop, width: bounds.width, height: BarHeight)
        barView.backgroundColor = UIColor(hexString: BarColor)
        barView.layer.cornerRadius = BarHeight / 2
        barView.layer.borderColor = UIColor.secondary1().cgColor
        barView.layer.borderWidth = 1
        barView.clipsToBounds = true
        greenView.frame = barView.bounds;
        greenView.alpha = 0.0
        greenView.backgroundColor = UIColor(hexString: BarColorHighlight)
        barView.addSubview(greenView)
        
        textLabel.frame =  barView.bounds
        textLabel.formatSize(16)
        textLabel.textAlignment = .center
        textLabel.text = String.localize("LB_CA_SR_REQUEST_VERCODE")
        barView.addSubview(textLabel)
        
        overlayView.frame = CGRect(x: BarStartX, y: bounds.minY + BarMarginTop, width: CircleWidth / 2, height: BarHeight)
        overlayView.backgroundColor = UIColor(hexString: BarColor)
        overlayView.clipsToBounds = true
        greenOverlayView.frame = barView.bounds;
        greenOverlayView.alpha = 0.0
        greenOverlayView.backgroundColor = UIColor(hexString: BarColorHighlight)
        overlayView.addSubview(greenOverlayView)
        overlayLabel.frame =  barView.bounds
        overlayLabel.formatSize(16)
        overlayLabel.alpha = 0.0
        overlayLabel.textColor = UIColor.white
        overlayLabel.textAlignment = .center
        overlayLabel.text = self.getSMSText(Int(timeCountdown))
        overlayView.addSubview(overlayLabel)
        
        barView.addSubview(overlayView)
        
       
        addSubview(barView)
        
        circleView.frame = CGRect(x: bounds.minX + CircleStartX , y: bounds.minY, width: CircleWidth, height: CircleWidth)
        circleView.backgroundColor = UIColor.white
        circleView.layer.borderColor = UIColor.secondary1().cgColor
        circleView.layer.borderWidth = 1
        circleView.layer.cornerRadius = CircleWidth / 2
        circleView.isUserInteractionEnabled = true
        circleMaxX = bounds.maxX - CircleWidth
        circleView.addGestureRecognizer(self.panRecognizer)
        addSubview(circleView)
    }
    
    func moveBack() {
        var frame = circleView.frame
        var frameOverlay = self.overlayView.frame;
        frameOverlay.size.width = CircleWidth / 2
        if(frame.origin.x > CircleStartX) {
            frame.origin.x = CircleStartX
            UIView.animate(
                withDuration: 0.2,
                animations: { () -> Void in
                    self.circleView.frame = frame
                    self.overlayView.frame = frameOverlay;
                },
                completion: { (success) in
                    self.reset()
                }
            )
        }
        else {
            self.reset()
        }
        isCountingDown = false
    }
    func moveNext() {
        var frame = circleView.frame
        var frame2 = self.overlayView.frame;
        frame2.size.width = circleMaxX -  CircleWidth / 2
        textLabel.alpha = 0.0
        if(frame.origin.x < circleMaxX) {
            frame.origin.x = circleMaxX
            UIView.animate(
                withDuration: 0.2,
                animations: { () -> Void in
                    self.circleView.frame = frame
                    self.overlayView.frame = frame2
                },
                completion: { (success) in
                    self.startSMS()
                }
            )
        }
        else {
            self.startSMS()
        }
        isCountingDown = false
    }
    func startSMS() {
        self.swipeSMSDelegate?.startSMS()
        dateTime = Date()
        textLabel.text = self.getSMSText(Int(timeCountdown))
        textLabel.textColor = UIColor.white
        var frame = self.overlayView.frame;
        frame.size.width = 0;
        overlayView.frame = frame;
        UIView.animate(withDuration: 0.2, delay: 0.2, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.textLabel.alpha = 1.0
            }, completion: nil)
        
        greenView.alpha = 1.0
        greenOverlayView.alpha = 1.0
        overlayLabel.alpha = 0.0
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SwipeSMSView.update), userInfo: nil, repeats: true)
        isCountingDown = true
    }
    func reset() {
        self.resetWithoutCallback()
        self.swipeSMSDelegate?.resetSMS()
    }
    
    func resetWithoutCallback() {
        var frame = self.overlayView.frame;
        frame.size.width = CircleWidth / 2;
        overlayView.frame = frame;
        greenView.alpha = 0.0
        greenOverlayView.alpha = 0.0
        overlayLabel.alpha = 0.0
        circleView.frame = CGRect(x: CircleStartX , y: bounds.minY, width: CircleWidth, height: CircleWidth)
        textLabel.textColor = UIColor.secondary2()
        textLabel.text = String.localize("LB_CA_SR_REQUEST_VERCODE")
        if let timer = self.timer {
            timer.invalidate()
        }
        timer = nil
        isCountingDown = false
    }
    func beginSwipe() {
        barView.frame = CGRect(x: BarStartX, y: bounds.minY + BarMarginTop, width: bounds.width - BarStartX * 2, height: BarHeight)
        if let delegate = self.swipeSMSDelegate {
             delegate.beginSwipe()
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        
        if isCountingDown {
            return
        }
        if !isEnableSwipe  {
            self.swipeSMSDelegate?.invalidSwipe()
            return
        }
        if recognizer.state == .began {
            self.beginSwipe()
        }
        else if recognizer.state == .changed {
            let translation = recognizer.translation(in: self)
            if(translation.x < CircleStartX || translation.x > circleMaxX) {
                return;
            }
            var frame = self.circleView.frame
            frame.origin.x = translation.x
            self.circleView.frame = frame
            frame = self.overlayView.frame;
            frame.size.width = translation.x + CircleWidth / 2
            overlayView.frame = frame;
            
            let alpha =  translation.x / circleMaxX
            self.greenView.alpha = alpha
            greenOverlayView.alpha = alpha
            self.textLabel.alpha = 1.0 - alpha
            self.overlayLabel.alpha = alpha
        }
        else if recognizer.state == .ended {
            if (self.circleView.frame.maxX - CircleStartX) > circleMaxX * ExpectPercent {
                self.moveNext()
            }
            else {
                self.moveBack()
            }
        }
    }
    
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.panRecognizer {
            let translation = self.panRecognizer.translation(in: self.superview)
            // Check for horizontal gesture
            if (fabsf(Float(translation.x)) > fabsf(Float(translation.y))) {
                return true
            }
            return false
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    //MARK: Timer function update
    @objc func update() {
        let time = CGFloat(dateTime.timeIntervalSinceNow)
        let remainingTime = timeCountdown + time
        if remainingTime <= 0 {
            self.moveBack()
            if let timer = self.timer {
                timer.invalidate()
            }
            timer = nil
        }
        else {
            textLabel.text = self.getSMSText(Int(remainingTime))
            
        }
    }
    
    func getSMSText(_ remainingTime: Int) -> String {
        return "(\(remainingTime))" + String.localize("LB_CA_SR_REQUEST_VERCODE_SENT_2")
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
