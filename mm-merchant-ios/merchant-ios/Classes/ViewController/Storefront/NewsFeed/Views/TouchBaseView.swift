//
//  TouchBaseView.swift
//  PhotoFrame
//
//  Created by Markus Chow on 2/5/2016.
//  Copyright © 2016 Markus Chow. All rights reserved.
//

import UIKit

struct Define {
    static let MAXZOOM = 2.0 as CGFloat
    static let MINZOOM = 0.5 as CGFloat
    
    static let HIGHLIGHT_FRAME = "HIGHLIGHT_FRAME"
    
    static let FRAME_OFFSET : CGFloat = 2
    
    static let SWAP_SIZE : CGFloat = 150
    
    static let BUTTON_SIZE : CGFloat = 30
    
    static let CIRCLE_FRAME = 6 as Int
}
protocol TouchBaseViewDelegate: NSObjectProtocol {
    func intersectOnFrameIndex(_ intersectedFrameIndex : Int, selfIndex: Int)
    func didTapOnImage(_ tapPoint: CGPoint, subFrameIndex: Int)
    func didUpdateImage()
    func didFinishDraggingImage(_ subFrameIndex: Int)
}

class TouchBaseView: UIView, UIGestureRecognizerDelegate {
    
    var translation = CGPoint.zero
    
    var panGuesture : UIPanGestureRecognizer!
    var pinchGesture : UIPinchGestureRecognizer!
    
    var singleTap : UITapGestureRecognizer!
    
    var currentTranslation = CGPoint.zero
    var currentScale = CGFloat(0)
    
    var touchImageView : TouchImageView!
    private var activityIndicator : UIActivityIndicatorView!
    var frames : [CGRect]!
    
    var buttonAdd : UIButton!
    
    weak var touchBaseViewDelegate : TouchBaseViewDelegate!
    
    var intersectedFrameIndex : Int!
    
    var dragImageView : TouchImageView!
    
    var movedToOtherRect : Bool = false
    
    var startPoint = CGPoint.zero
    var lastFrame = CGRect.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TouchBaseView.highlightFrame), name: NSNotification.Name(rawValue: Define.HIGHLIGHT_FRAME), object: nil)
        
        self.backgroundColor = UIColor.white //MM-24358 Default image background to #FFFFFF
        
        clipsToBounds = true
        
        setupTouchImageView()
        
        setupGestures()
        
        setupButtonAdd()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Define.HIGHLIGHT_FRAME), object: nil)
    }
    
    //	override class func layerClass() -> AnyClass {
    //		return CATiledLayer.self
    //	}
    
    func highlightLayerView(_ show: Bool = false) {
        show == true ? (self.alpha = 0.5) : (self.alpha = 1.0)
    }
    
    func setupButtonAdd(){
        buttonAdd = UIButton(frame: CGRect(x: (self.bounds.width - Define.BUTTON_SIZE) / 2, y: (self.bounds.height - Define.BUTTON_SIZE) / 2, width: Define.BUTTON_SIZE, height: Define.BUTTON_SIZE))
        buttonAdd.setBackgroundImage(UIImage(named: "icon_add"), for: UIControlState())
        buttonAdd.tag = self.tag
        
        self.addSubview(buttonAdd)
        self.bringSubview(toFront: buttonAdd)
    }
    
    func setupTouchImageView() {
        // add touch image view to frameView
        touchImageView = TouchImageView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        self.addSubview(touchImageView)
        touchImageView.tag = self.tag
        
        touchImageView.transform = CGAffineTransform.identity
        
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.center = self.bounds.center
        activityIndicator.isHidden = true
        self.addSubview(activityIndicator)
        
    }
    
    class func addPaddingOnFrame(_ frameOffset: CGFloat, frame: CGRect) -> CGRect {
        
        var rect = frame
        
        // add padding on each frame
        rect.origin.x = (rect.origin.x == 0.0) ? 0 : (rect.origin.x + (frameOffset/2))
        rect.origin.y = (rect.origin.y == 0.0) ? 0 : (rect.origin.y + (frameOffset/2))
        
        if !((rect.origin.x + rect.size.width) >= UIScreen.main.bounds.size.width) {
            rect.size.width = (rect.origin.x == 0) ? (rect.size.width - (frameOffset/2)) : rect.size.width - frameOffset
        }else {
            rect.size.width = UIScreen.main.bounds.size.width - rect.origin.x
        }
        
//        rect.size.width = (rect.origin.x + rect.size.width == UIScreen.main.bounds.size.width) ? rect.size.width : (rect.size.width - (frameOffset/2))
        rect.size.height = (rect.origin.x + rect.size.height == UIScreen.main.bounds.size.height) ? rect.size.height : (rect.size.height - (frameOffset/2))
        
        if (rect.origin.x + rect.size.width + ((frameOffset/2) * 1.5)) == UIScreen.main.bounds.size.width {
            rect.origin.x += (frameOffset/2)
        }
        
        if (rect.origin.y + rect.size.height + (frameOffset/2)) == UIScreen.main.bounds.size.width {
            rect.size.height += (frameOffset/2)
        }
        
        return rect
    }
    
    class func removePaddingOnFrame(_ frameOffset: CGFloat, frame: CGRect) -> CGRect {
        
        var rect = frame
        
        // remove padding on each frame
        rect.origin.x = (rect.origin.x == 0.0) ? 0 : (rect.origin.x - (frameOffset/2))
        rect.origin.y = (rect.origin.y == 0.0) ? 0 : (rect.origin.y - (frameOffset/2))
        rect.size.width = (rect.origin.x + rect.size.width == UIScreen.main.bounds.size.width) ? rect.size.width : (rect.size.width + (frameOffset/2))
        rect.size.height = (rect.origin.x + rect.size.height == UIScreen.main.bounds.size.height) ? rect.size.height : (rect.size.height + (frameOffset/2))
        
        if (rect.origin.x + rect.size.width + ((frameOffset/2) * 1.5)) == UIScreen.main.bounds.size.width {
            rect.origin.x -= (frameOffset/2)
        }
        
        if (rect.origin.y + rect.size.height + (frameOffset/2)) == UIScreen.main.bounds.size.width {
            rect.size.height -= (frameOffset/2)
        }
        
        return rect
    }
    
    @objc func highlightFrame(_ notification: Notification) {
        if notification.object != nil {
            
            var rect = (notification.object! as AnyObject).cgRectValue as CGRect
            
            rect = TouchBaseView.addPaddingOnFrame(Define.FRAME_OFFSET, frame: rect)
            
            highlightLayerView(rect.equalTo(self.frame))
            
        }
        
    }
    
    func setupGestures() {
        
        panGuesture = UIPanGestureRecognizer(target: self, action: #selector(TouchBaseView.pan))
        panGuesture.maximumNumberOfTouches = 1
        panGuesture.delegate = self
        self.addGestureRecognizer(panGuesture)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(TouchBaseView.pinch))
        pinchGesture.delegate = self
        self.addGestureRecognizer(pinchGesture)
        
        singleTap = UITapGestureRecognizer(target: self, action: #selector(TouchBaseView.tap))
        singleTap.delegate = self
        self.addGestureRecognizer(singleTap)
    }
    
    // MARK: - Pan Gesture
    @objc func pan(_ gesture: UIPanGestureRecognizer) {
        
        guard touchImageView.image != nil else {
            return
        }
        
        //		let point = gesture.location(in: self.superview)
        
        var thisRect = TouchBaseView.removePaddingOnFrame(Define.FRAME_OFFSET, frame: self.frame)
        let translation = gesture.translation(in: self)
        let tx = translation.x;
        let ty = translation.y
        
        let point = CGPoint(x:gesture.view!.center.x + tx, y:gesture.view!.center.y + ty)
        
        switch gesture.state {
        case .began:
            
            currentTranslation = self.touchImageView.center
            currentScale = self.touchImageView.frame.size.width / self.touchImageView.bounds.size.width
            
            // reset intersectedFrameIndex
            intersectedFrameIndex = -1
            
            movedToOtherRect = false
            
            dragImageView = TouchImageView(frame: CGRect(x: 0, y: 0, width: Define.SWAP_SIZE, height: Define.SWAP_SIZE))
            dragImageView.image = self.touchImageView.image
            
            dragImageView.clipsToBounds = true
            
            self.superview?.addSubview(dragImageView)
            
            dragImageView.center = point
            
            dragImageView.isHidden = true
            
            startPoint = point
            lastFrame = touchImageView.frame
            
            break
            
        case .changed:
            
            //			let translation = gesture.translationInView(self)
            
            let offsetX = point.x - startPoint.x
            let offsetY = point.y - startPoint.y
            
            var rect = CGRect(x: lastFrame.origin.x + offsetX, y: lastFrame.origin.y + offsetY, width: lastFrame.size.width, height: lastFrame.size.height)
            
            if rect.origin.x > 0 {
                rect.origin.x = 0
            }
            if rect.origin.y > 0 {
                rect.origin.y = 0
            }
            if rect.maxX < self.bounds.width {
                rect.origin.x = self.bounds.width - rect.size.width
                if rect.size.width < self.bounds.width {
                    rect.origin.x = (self.bounds.width - rect.size.width) / 2
                }
            }
            if rect.maxY < self.bounds.height {
                rect.origin.y = self.bounds.height - rect.size.height
                if rect.size.height < self.bounds.height {
                    rect.origin.y = (self.bounds.height - rect.size.height) / 2
                }
            }
            
            
            touchImageView.frame = rect
            
            if dragImageView != nil {
                
                dragImageView.center = point
                
                for i in 0 ..< frames.count {
                    
                    let rect = frames[i]
                    
                    // thisRect
                    
                    var shouldAllowSwap = !thisRect.contains(point)
                    
                    if thisRect.size.width == UIScreen.main.bounds.size.width && thisRect.size.width == thisRect.size.height {
                        shouldAllowSwap = true
                    }
                    
                    if (thisRect.size.width == UIScreen.main.bounds.size.width && (thisRect.size.height - Define.FRAME_OFFSET/2) == UIScreen.main.bounds.size.width) {
                        thisRect.size.height = thisRect.size.height - Define.FRAME_OFFSET/2
                    }
                    
                    if rect.contains(point) && (!thisRect.equalTo(rect) && shouldAllowSwap || movedToOtherRect) {
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Define.HIGHLIGHT_FRAME), object: NSValue(cgRect: rect))
                        
                        intersectedFrameIndex = i
                        
                        self.touchImageView.isHidden = true
                        
                        dragImageView.isHidden = false
                        
                        movedToOtherRect = true
                    }
                }
            }
            
            break
            
        case .ended, .cancelled:
            if (dragImageView == nil){ //Fix bug crash when dragImageView is nil
                return
            }
            
            if dragImageView != nil {
                dragImageView.removeFromSuperview()
            }
            
            if !dragImageView.isHidden {
                
                touchImageView.transform = CGAffineTransform.identity
                touchImageView.isHidden = false
                touchImageView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
                
                if let index = intersectedFrameIndex {
                    if index != self.tag && index >= 0 {
                        // Send To Delegate
                        if let delegate_ = self.touchBaseViewDelegate {
                            delegate_.intersectOnFrameIndex(intersectedFrameIndex, selfIndex: self.tag)
                        }
                    } else {
                        self.bringSubview(toFront: self.buttonAdd)
                        buttonAdd.isEnabled = true
                    }
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: Define.HIGHLIGHT_FRAME), object: NSValue(cgRect: CGRect.zero))
            }
            self.touchBaseViewDelegate?.didFinishDraggingImage(self.tag)
            self.touchBaseViewDelegate?.didUpdateImage()
            break
        default:
            break
        }
        
    }
    
    // MARK: - Pinch Gesture
    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
        
        guard touchImageView.image != nil else {
            return
        }
        
        switch gesture.state {
        case .began:
            lastFrame = self.touchImageView.frame
        case .changed:
            
            let currentRatio = self.touchImageView.frame.sizeWidth / self.touchImageView.initialFrame.sizeWidth
            if gesture.scale >= 1 {
                if currentRatio >= Define.MAXZOOM {
                    return
                }
            }
            if gesture.scale < 1 {
                if currentRatio < Define.MINZOOM {
                    return
                }
            }
            
            let currentFrame = self.touchImageView.frame
            let newScale = gesture.scale
            
            self.touchImageView.transform = self.touchImageView.transform.scaledBy(x: newScale, y: newScale)
            if newScale < 1 { //adjust touch image frame when zoom in
                var rect = self.touchImageView.frame
                if rect.origin.x > 0 {
                    rect.origin.x = 0
                    if rect.size.width < self.bounds.width {
                        rect.origin.x = (self.bounds.width - rect.size.width) / 2
                    }
                }else {
                    if rect.maxX < self.bounds.width {
                        var offsetX = self.touchImageView.frame.size.width - currentFrame.size.width
                        offsetX *= CGFloat(-1)
                        rect.origin.x += (offsetX  / 2)
                        if rect.origin.x > (self.bounds.width - rect.size.width) / 2 {
                            rect.origin.x = (self.bounds.width - rect.size.width) / 2
                        }
                    }
                }
                if rect.origin.y > 0 {
                    rect.origin.y = 0
                    if rect.size.height < self.bounds.height {
                        rect.origin.y = (self.bounds.height - rect.size.height) / 2
                    }
                }else {
                    if rect.maxY < self.bounds.height {
                        var offsetY = self.touchImageView.frame.size.height - currentFrame.size.height
                        offsetY *= CGFloat(-1)
                        rect.origin.y += (offsetY / 2)
                        if rect.origin.y > (self.bounds.height - rect.size.height) / 2 {
                            rect.origin.y = (self.bounds.height - rect.size.height) / 2
                        }
                    }
                }
                
                self.touchImageView.frame = rect
            }
            gesture.scale = 1.0
        case .ended:
            self.touchBaseViewDelegate?.didUpdateImage()
        default:
            break
        }
    }
    
    // MARK: - Tap Gesture
    @objc func tap(_ gesture: UITapGestureRecognizer) {
        
        self.recordAction(.Tap, sourceRef: "Add-ProductTag", sourceType: .Button, targetRef: "Editor-ProductTag-Wishlist", targetType: .View)
        
        if (self.touchImageView.image != nil) {
            let point = gesture.location(in: self)
            self.touchBaseViewDelegate?.didTapOnImage(CGPoint(x: point.x + self.frame.minX, y: point.y + self.frame.minY), subFrameIndex: self.buttonAdd.tag)
        }
    }
    
    // MARK: UIGesture Delegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func showLoading(){
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func hideLoading(){
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    func setBaseFrame(_ frame: CGRect){
        self.frame = frame
        self.activityIndicator.center = self.bounds.center
    }
    
    func setBaseImage(_ image: UIImage?){
        self.touchImageView.image = image
        self.buttonAdd.isHidden = (image != nil)
    }
}
