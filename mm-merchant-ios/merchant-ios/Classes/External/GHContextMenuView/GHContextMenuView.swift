//
//  GHContextMenuView.swift
//  merchant-ios
//
//  Created by Tapasya on 27/01/14.
//  Copyright (c) 2014 Tapasya. All rights reserved.
//
//  Pod by Hang Yuen on 16/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit

enum GHContextMenuActionType {
    // Default
    case pan,
    // Allows tap action in order to trigger an action
    tap
}

class GHMenuItemLocation: NSObject {
    var position: CGPoint = CGPoint.zero
    var angle: CGFloat = 0
}

struct GHConfig {
    struct Size {
        static let mainItem : CGFloat = 44
        static let menuItem : CGFloat = 50
        static let borderWidth : CGFloat = 0
    }
    
    struct Animation {
        static let duration = 0.2
        static let delay = 0.2 / 5
    }
    
    static let GHShowAnimationID = "GHContextMenuViewRriseAnimationID"
    static let GHDismissAnimationID = "GHContextMenuViewDismissAnimationID"
}

protocol GHContextOverlayViewDataSource: NSObjectProtocol  {
    
    func numberOfMenuItems() -> Int
    func imageForItemAtIndex(_ index : Int) -> UIImage!
    func textForItemAtIndex(_ index : Int) -> String
    func shouldShowMenuAtPoint(_ point : CGPoint) -> Bool
    
}

protocol GHContextOverlayViewDelegate: NSObjectProtocol {
    
    func didSelectItemAtIndex(_ selectedIndex: Int, forMenuAtPoint: CGPoint)
    
}

class GHContextMenuView : UIView, CAAnimationDelegate {
    
    private weak var _dataSource: GHContextOverlayViewDataSource!
    var dataSource: GHContextOverlayViewDataSource! {
        get {
            return self._dataSource
        }
        set {
            self._dataSource = newValue
//            reloadData()
        }
    }
    
    weak var delegate: GHContextOverlayViewDelegate!
    var menuActionType: GHContextMenuActionType!
    
    
    
    // private
    var longPressRecognizer: UILongPressGestureRecognizer?
    var isShowing: Bool = false
    var isPaning: Bool = false
    var longPressLocation: CGPoint = CGPoint.zero
    var curretnLocation: CGPoint = CGPoint.zero
    var menuItems: [CALayer?] = []
    var textItems: [CALayer?] = []
    
    var radius: CGFloat = 0
    var arcAngle: Double = 0
    var angleBetweenItems: CGFloat = 0
    var itemLocations: [GHMenuItemLocation?] = []
    var prevIndex: Int = 0
    var itemBGHighlightedColor: CGColor?
    var itemBGColor: CGColor?
    var displayLink: CADisplayLink! = nil
    
    required init() {
        super.init(frame: UIScreen.main.bounds)
        
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        self.menuActionType = GHContextMenuActionType.pan
        displayLink = CADisplayLink(target: self, selector: #selector(GHContextMenuView.highlightMenuItemForPoint))
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        self.arcAngle = Double.pi / 2
        self.radius = 90
        self.itemBGColor = UIColor.gray.cgColor
        self.itemBGHighlightedColor = UIColor.red.cgColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(frame: UIScreen.main.bounds)
        
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.clear
        self.menuActionType = GHContextMenuActionType.pan
        displayLink = CADisplayLink(target: self, selector: #selector(GHContextMenuView.highlightMenuItemForPoint))
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        self.arcAngle = Double.pi / 2
        self.radius = 90
        self.itemBGColor = UIColor.gray.cgColor
        self.itemBGHighlightedColor = UIColor.red.cgColor
    }
    
    // MARK: Layer Touch Tracking
    
    func indexOfClosestMatchAtPoint(_ point: CGPoint) -> Int {
        var i: Int = 0
        for menuItemLayer in menuItems {
            if (menuItemLayer?.frame.contains(point))! {
                return i
            }
            i += 1
        }
        return -1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var menuAtPoint: CGPoint = CGPoint.zero
        if touches.count == 1 {
            if let touch =  touches.first {
                let touchPoint: CGPoint = touch.location(in: self)
                let menuItemIndex: Int = indexOfClosestMatchAtPoint(touchPoint)
                if menuItemIndex > -1 {
                    menuAtPoint = (menuItems[menuItemIndex]?.position)!
                }
                if (prevIndex >= 0 && prevIndex != menuItemIndex) {
                    resetPreviousSelection()
                }
                self.prevIndex = menuItemIndex
            }
        }
        self.dismissWithSelectedIndexForMenuAtPoint(menuAtPoint)
        super.touchesBegan(touches , with:event)
    }
    
    // MARK: LongPress handler
    
    // Split this out of the longPressDetected so that we can reuse it with touchesBegan (above)
    func dismissWithSelectedIndexForMenuAtPoint(_ point: CGPoint) {
//        if delegate && delegate.respondsToSelector("didSelectItemAtIndex:forMenuAtPoint:") && prevIndex >= 0 {
        if delegate != nil && prevIndex >= 0 {
            delegate!.didSelectItemAtIndex(prevIndex, forMenuAtPoint: point)
            self.prevIndex = -1
        }
        hideMenu()
    }
    
    @objc func longPressDetected(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            self.prevIndex = -1
            let pointInView: CGPoint = gestureRecognizer.location(in: gestureRecognizer.view)
//            if dataSource != nil && dataSource.respondsToSelector("shouldShowMenuAtPoint:") && !dataSource.shouldShowMenuAtPoint(pointInView) {
            if dataSource != nil && dataSource?.shouldShowMenuAtPoint(pointInView) == false {
                return
            }else {
                reloadData()
            }
            UIApplication.shared.keyWindow?.addSubview(self)
            self.longPressLocation = gestureRecognizer.location(in: self)
            self.layer.backgroundColor = UIColor(white: 0.1, alpha: 0.8).cgColor
            self.isShowing = true
            animateMenu(true)
            setNeedsDisplay()
            
        }
        
        if gestureRecognizer.state == UIGestureRecognizerState.changed {
            if isShowing == true && menuActionType == GHContextMenuActionType.pan {
                self.isPaning = true
                self.curretnLocation = gestureRecognizer.location(in: self)
            }
        }
        if gestureRecognizer.state == UIGestureRecognizerState.ended && menuActionType == GHContextMenuActionType.pan {
            let menuAtPoint: CGPoint = convert(longPressLocation, to: gestureRecognizer.view)
            self.dismissWithSelectedIndexForMenuAtPoint(menuAtPoint)
        }
    }
    
    func showMenu() {
    }
    
    func hideMenu() {
        if isShowing == true {
            self.layer.backgroundColor = UIColor.clear.cgColor
            self.isShowing = false
            self.isPaning = false
            animateMenu(false)
            setNeedsDisplay()
            removeFromSuperview()
        }
    }
    
    func layerWithImage(_ image: UIImage) -> CALayer {
        let layer: CALayer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: GHConfig.Size.menuItem, height: GHConfig.Size.menuItem)
        layer.cornerRadius = GHConfig.Size.menuItem / 2
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = GHConfig.Size.borderWidth
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.backgroundColor = itemBGColor
        let imageLayer: CALayer = CALayer()
        imageLayer.contents = image.cgImage
        imageLayer.bounds = CGRect(x: 0, y: 0, width: GHConfig.Size.menuItem * 2 / 3, height: GHConfig.Size.menuItem * 2 / 3)
        imageLayer.position = CGPoint(x: GHConfig.Size.menuItem / 2, y: GHConfig.Size.menuItem / 2)
        layer.addSublayer(imageLayer)
        

        
        return layer
    }
    
    
    func layerWithText(_ text: String) -> CALayer {
        let textBackgroundLayer = CALayer()
        textBackgroundLayer.bounds = CGRect(x: 0, y: 0, width: 50, height: 20)
        textBackgroundLayer.cornerRadius = 5
        textBackgroundLayer.backgroundColor = UIColor(white: 0, alpha: 0.5).cgColor
        
        let textLayer: CATextLayer = CATextLayer()
        textLayer.fontSize = 10
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.string = text
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.bounds = textBackgroundLayer.bounds
        textLayer.position = CGPoint(x: 25, y: 12)
        textLayer.alignmentMode = "center"
        textBackgroundLayer.addSublayer(textLayer)
        textBackgroundLayer.opacity = 0
        
        return textBackgroundLayer
    }
    
    // MARK: menu item layout
    
    func reloadData() {
        menuItems.removeAll()
        itemLocations.removeAll()

        if dataSource != nil {
            
            if let layers: [CALayer] = layer.sublayers{
                for item in layers {
                    item.removeFromSuperlayer()
                }
            }
            
            textItems = []
            menuItems = []
            
            let count: Int = dataSource!.numberOfMenuItems()
            for i in 0 ..< count {
                let image: UIImage = dataSource!.imageForItemAtIndex(i)
                
                let textLayer = self.layerWithText(dataSource!.textForItemAtIndex(i))
                layer.addSublayer(textLayer)
                
                let imageLayer = self.layerWithImage(image)
                layer.addSublayer(imageLayer)
                
                textItems.append(textLayer)
                menuItems.append(imageLayer)
            }
        }
    }
    
    func layoutMenuItems() {
        itemLocations.removeAll()
        let itemSize: CGSize = CGSize(width: GHConfig.Size.menuItem, height: GHConfig.Size.menuItem)
        let itemRadius: CGFloat = sqrt(pow(itemSize.width, 2) + pow(itemSize.height, 2)) / 2
        self.arcAngle = Double(((itemRadius * CGFloat(menuItems.count)) / radius) * 1.5)
        let count: Int = menuItems.count
        let isFullCircle: Bool = (arcAngle == Double.pi * 2)
        let divisor: Int = (isFullCircle) ? count : count - 1
        self.angleBetweenItems = CGFloat(arcAngle / Double(divisor))
        
        for i in 0 ..< menuItems.count {
            let location: GHMenuItemLocation = locationForItemAtIndex(i)
            itemLocations.append(location)
            let layer: CALayer = menuItems[i]!
            layer.transform = CATransform3DIdentity
            if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
                let angle = (UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft) ? Double.pi / 2 : -Double.pi / 2
                layer.transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(angle), 0, 0, 1)
            }
        }
    }
    
    func locationForItemAtIndex(_ index: Int) -> GHMenuItemLocation {
        let itemAngle: Float = Float(itemAngleAtIndex(index))
        let itemCenter: CGPoint = CGPoint(x: longPressLocation.x + CGFloat(cosf(itemAngle)) * radius, y: longPressLocation.y + CGFloat(sinf(itemAngle)) * radius)
        let location: GHMenuItemLocation = GHMenuItemLocation()
        location.position = itemCenter
        location.angle = CGFloat(itemAngle)
        return location
    }
    
    func itemAngleAtIndex(_ index: Int) -> CGFloat {
        
        var endPoint : CGPoint
        if longPressLocation.x < center.x {
            endPoint = CGPoint(x: bounds.maxX, y: longPressLocation.y - CGFloat(200))
        }else {
            endPoint = CGPoint(x: 0, y: longPressLocation.y - CGFloat(200))
        }
        
        let bearingRadians: CGFloat = angleBeweenStartinPoint(longPressLocation, endingPoint: endPoint)
        let angle: CGFloat = bearingRadians - CGFloat(arcAngle) / 2
        var itemAngle: CGFloat = angle + (CGFloat(index) * angleBetweenItems)
        if itemAngle > CGFloat.pi * 2 {
            itemAngle -= CGFloat.pi * 2
        }
        else {
            if itemAngle < 0 {
                itemAngle += CGFloat.pi * 2
            }
        }
        return itemAngle
    }
    
    // MARK: helper methods
    
    func calculateRadius() -> CGFloat {
        let mainSize: CGSize = CGSize(width: GHConfig.Size.mainItem, height: GHConfig.Size.mainItem)
        let itemSize: CGSize = CGSize(width: GHConfig.Size.menuItem, height: GHConfig.Size.menuItem)
        let mainRadius: CGFloat = sqrt(pow(mainSize.width, 2) + pow(mainSize.height, 2)) / 2
        let itemRadius: CGFloat = sqrt(pow(itemSize.width, 2) + pow(itemSize.height, 2)) / 2
        let minRadius: CGFloat = (mainRadius + itemRadius)
        let maxRadius: CGFloat = ((itemRadius * CGFloat(menuItems.count)) / CGFloat(arcAngle)) * 1.5
        let radius: CGFloat = max(minRadius, maxRadius)
        return radius
    }
    
    func angleBeweenStartinPoint(_ startingPoint: CGPoint, endingPoint: CGPoint) -> CGFloat {
        let originPoint: CGPoint = CGPoint(x: endingPoint.x - startingPoint.x, y: endingPoint.y - startingPoint.y)
        var bearingRadians: CGFloat = CGFloat(atan2f(Float(originPoint.y), Float(originPoint.x)))
        bearingRadians = (bearingRadians > 0.0 ? bearingRadians : (CGFloat.pi * 2 + bearingRadians))
        return bearingRadians
    }
    
    func validaAngle(_ angle: CGFloat) -> CGFloat {
		var tmp = angle
        if tmp > CGFloat.pi * 2 {
            tmp = validaAngle(tmp - CGFloat.pi * 2)
        }
        return tmp
    }
    
    // MARK: animation and selection
	
    @objc func highlightMenuItemForPoint() {
        if isShowing && isPaning {
            let angle: CGFloat = angleBeweenStartinPoint(longPressLocation, endingPoint: curretnLocation)
            var closeToIndex: Int = -1
            for i in 0 ..< menuItems.count {
                let itemLocation: GHMenuItemLocation = itemLocations[i]!
                if fabs(itemLocation.angle - angle) < angleBetweenItems / 2 {
                    closeToIndex = i
                }
            }
            
            if closeToIndex >= 0 && closeToIndex < menuItems.count {
                let itemLocation: GHMenuItemLocation = itemLocations[closeToIndex]!
                let distanceFromCenter: CGFloat = sqrt(pow(curretnLocation.x - longPressLocation.x, 2) + pow(curretnLocation.y - longPressLocation.y, 2))
                let toleranceDistanceSum = radius - GHConfig.Size.mainItem / (2 * sqrt(2))
                let toleranceDistanceReduce = ((GHConfig.Size.menuItem / (2 * sqrt(2))) / 2)
                let toleranceDistance: CGFloat = toleranceDistanceSum - toleranceDistanceReduce
                
                let distanceFromItem: CGFloat = CGFloat(fabsf(Float(distanceFromCenter - (radius))) - Float(GHConfig.Size.menuItem / (2 * sqrt(2))))
                
                if fabs(distanceFromItem) < toleranceDistance {
                    let layer: CALayer = menuItems[closeToIndex]!
                    layer.backgroundColor = itemBGHighlightedColor
                    let distanceFromItemBorder: CGFloat = fabs(distanceFromItem)
                    var scaleFactor: CGFloat = 1 + 0.5 * (1 - distanceFromItemBorder / toleranceDistance)
                    if scaleFactor < 1.0 {
                        scaleFactor = 1.0
                    }
                    let scaleTransForm = CATransform3DScale(CATransform3DIdentity, scaleFactor, scaleFactor, 1.0)
                    
                    let xtrans = CGFloat(cosf(Float(itemLocation.angle)))
                    let ytrans = CGFloat(sinf(Float(itemLocation.angle)))
                    
                    let transLate = CATransform3DTranslate(scaleTransForm, 10*scaleFactor*xtrans, 10*scaleFactor*ytrans, 0);
                    layer.transform = transLate;
                    
                    textItems[closeToIndex]?.opacity = 1
                    textItems[closeToIndex]?.position = layer.frame.center.minusY(60)
                    textItems[closeToIndex]?.zPosition = 10
                    if self.prevIndex >= 0 && self.prevIndex != closeToIndex {
                        resetPreviousSelection()
                    }
                    
                    self.prevIndex = closeToIndex;
                }
                else {
                    if prevIndex >= 0 {
                        resetPreviousSelection()
                    }
                }
            } else {
                resetPreviousSelection()
            }
        }
    }
    
    func resetPreviousSelection() {
        if prevIndex >= 0 {
            let layer: CALayer = menuItems[prevIndex]!
            let itemLocation: GHMenuItemLocation = itemLocations[prevIndex]!
            layer.position = itemLocation.position
            layer.backgroundColor = itemBGColor
            layer.transform = CATransform3DIdentity
            textItems[prevIndex]?.opacity = 0
            self.prevIndex = -1
        }
    }
    
    func animateMenu(_ isShowing: Bool) {
        if isShowing {
            layoutMenuItems()
        }
        for index in 0 ..< menuItems.count {
            let layer: CALayer = menuItems[index]!
            layer.opacity = 0
            
            let fromPosition: CGPoint = longPressLocation
            let location: GHMenuItemLocation = itemLocations[index]!
            let toPosition: CGPoint = location.position
            let delayInSeconds: Double = Double(index) * GHConfig.Animation.delay
            
            var positionAnimation: CABasicAnimation
            positionAnimation = CABasicAnimation(keyPath: "position")
            positionAnimation.fromValue = NSValue(cgPoint: isShowing ? fromPosition : toPosition)
            positionAnimation.toValue = NSValue(cgPoint: isShowing ? toPosition : fromPosition)
            positionAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.45, 1.2, 0.75, 1.0)

            positionAnimation.duration = GHConfig.Animation.duration
            positionAnimation.beginTime = layer.convertTime(CACurrentMediaTime(), from: nil) + delayInSeconds
            positionAnimation.setValue(NSNumber(value: index as Int), forKey: (isShowing ? GHConfig.GHShowAnimationID : GHConfig.GHDismissAnimationID))
            positionAnimation.delegate = self
            layer.add(positionAnimation, forKey: "riseAnimation")
//            text.addAnimation(positionAnimation, forKey: "riseAnimation")
            
        }
    }
    
	func animationDidStart(_ anim: CAAnimation) {
        if anim.value(forKey: GHConfig.GHShowAnimationID) != nil {
            if let inum : NSNumber = anim.value(forKey: GHConfig.GHShowAnimationID) as? NSNumber {
                let index: Int = inum.intValue
                let layer: CALayer = menuItems[index]!
                let location: GHMenuItemLocation = itemLocations[index]!
                layer.position = location.position
                layer.opacity = Float(1.0)
                
                textItems[index]?.position = layer.position.minusY(60)
                
            }
        }
        else if anim.value(forKey: GHConfig.GHDismissAnimationID) != nil {
            if let inum : NSNumber = anim.value(forKey: GHConfig.GHDismissAnimationID) as? NSNumber {
                let index: Int = inum.intValue
                let layer: CALayer = menuItems[index]!
                let toPosition: CGPoint = longPressLocation
                CATransaction.begin()
                CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
                layer.position = toPosition
                layer.backgroundColor = itemBGColor
                layer.opacity = 0.0
                textItems[index]?.opacity = 0
                layer.transform = CATransform3DIdentity
                CATransaction.commit()
            }
        }
    }
    
    func drawCircle(_ locationOfTouch: CGPoint) {
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        ctx.setLineWidth(GHConfig.Size.borderWidth / 2)
        ctx.setStrokeColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        
        let center = CGPoint(x: locationOfTouch.x, y: locationOfTouch.y)
        let radius = GHConfig.Size.menuItem / 2.0
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)
        ctx.strokePath()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        if isShowing {
            drawCircle(longPressLocation)
        }
    }
    
    func destory() {
        displayLink?.invalidate()
    }
    
}
