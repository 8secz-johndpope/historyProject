//
//  SwipeActionMenuCell.swift
//  merchant-ios
//
//  Created by Alan YU on 5/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


enum MenuOptionPosition: Int {
    case left
    case right
}

class SwipeActionMenuCellData {
    
    var text: String
    var icon: UIImage?
    var backgroundColor: UIColor
    var textColor: UIColor
    var action: (() -> Void)?
    var defaultAction: Bool
    
    init(text: String = "", icon: UIImage? = nil, backgroundColor: UIColor = UIColor.gray, textColor: UIColor = UIColor.white, defaultAction: Bool = false, action: (() -> Void)? = nil) {
        self.text = text
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.action = action
        self.defaultAction = defaultAction
    }
}

class SwipeActionMenuCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var defaultLeftData: SwipeActionMenuCellData?
    var defaultRightData: SwipeActionMenuCellData?
    
    var leftMenuItems: [SwipeActionMenuCellData]? {
        didSet {
            self.removeFromSuperview(self.leftViewPool)
            self.leftViewPool = nil
        }
    }
    
    var rightMenuItems: [SwipeActionMenuCellData]? {
        didSet {
            self.removeFromSuperview(self.rightViewPool)
            self.rightViewPool = nil
        }
    }
    
    
    private var leftViewPool: [SwipeMenuOptionView]?
    private var rightViewPool: [SwipeMenuOptionView]?
    
    private lazy var panRecognizer: UIPanGestureRecognizer = {
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeActionMenuCell.handlePan))
        recognizer.delegate = self
        return recognizer
        
    } ()
    
    var optionWidth = CGFloat(88)
    var factorOfSwipe = CGFloat(0.7)
    
    
    var disableSwipeLeft = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    private func commonInit() {
        self.backgroundColor = UIColor.white
        self.addGestureRecognizer(self.panRecognizer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SwipeActionMenuCell.swipeActionMenuCellDismissNotification),
            name: NSNotification.Name(rawValue: "SwipeActionMenuCellDismissNotification"),
            object: nil
        )
    }
    
    @objc func swipeActionMenuCellDismissNotification(_ notification: Notification) {
        if let cell = notification.object as? SwipeActionMenuCell, ObjectIdentifier(cell) != ObjectIdentifier(self) {
            self.dismissMenu()
        }
    }
    
    func removeFromSuperview(_ viewPool: [SwipeMenuOptionView]?) {
        if let pool = viewPool {
            for v in pool {
                v.removeFromSuperview()
            }
        }
    }
    
    func prepareAtionMenu() {
        
        let size = self.bounds.size
        
        let prepareOptionView = { (menuItems: [SwipeActionMenuCellData], position: MenuOptionPosition) -> [SwipeMenuOptionView] in
            var viewPool = [SwipeMenuOptionView]()
            for item in menuItems {
                
                var xPos = size.width
                
                if position == .left {
                    
                    xPos = -size.width
                    if item.defaultAction {
                        self.defaultLeftData = item
                    }
                    
                } else {
                    
                    if item.defaultAction {
                        self.defaultRightData = item
                    }
                    
                }
                
                let option = SwipeMenuOptionView(frame: CGRect(x: xPos, y: 0, width: size.width, height: size.height), position: position)
                option.data = item
                option.optionWidth = self.optionWidth
                
                option.actionHander = {
                    self.dismissMenu()
                }
                
                viewPool.append(option)
                self.addSubview(option)
                
            }
            
            return viewPool
            
        }
        
        if let leftMenuItems = self.leftMenuItems, self.leftViewPool == nil && leftMenuItems.count > 0 {
                self.leftViewPool = prepareOptionView(leftMenuItems, .left)
        }
        
        if let rightMenuItems = self.rightMenuItems, self.rightViewPool == nil && rightMenuItems.count > 0 {
                self.rightViewPool = prepareOptionView(rightMenuItems, .right)
        }
        
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer === self.panRecognizer {
            let translation = self.panRecognizer.translation(in: self.superview)
            // Check for horizontal gesture
            if (fabsf(Float(translation.x)) > fabsf(Float(translation.y))) {
                return true
            }
            
            dismissMenu()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwipeActionMenuCellDismissNotification"), object: self)
            
            return false
        }
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    var originalCenter = CGPoint.zero
    var rightCompleteOnDragRelease = false
    var leftCompleteOnDragRelease = false
    var defaultRightActionCompleteOnDrag = false
    var defaultLeftActionCompleteOnDrag = false
    
    func layoutMenuViews(_ referenceView: UIView, viewPool: [SwipeMenuOptionView], position: MenuOptionPosition, animated: Bool = false) {
        
        let spacing = (self.bounds.size.width - referenceView.frame.maxX) / CGFloat(viewPool.count)
        for i in 0 ..< viewPool.count {
            let view = viewPool[i]
            var delta = spacing * CGFloat(i)
            if position == .left {
                
                if self.defaultLeftActionCompleteOnDrag {
                    delta = 0
                }
                
                UIView.animate(
                    withDuration: animated ? 0.2 : 0.0,
                    animations: { () -> Void in
                        view.frame = CGRect(x: referenceView.frame.minX - view.bounds.size.width + delta, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
                    }
                )
                
            } else {
                
                if self.defaultRightActionCompleteOnDrag {
                    delta = 0
                }
                
                UIView.animate(
                    withDuration: animated ? 0.2 : 0.0,
                    animations: { () -> Void in
                        view.frame = CGRect(x: referenceView.frame.maxX + delta, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
                    }
                )
                
            }
        }
        
    }
    
    func dismissMenu() {
        
        let referenceView = self.contentView
        
        let originalFrame = CGRect(
            x: 0,
            y: referenceView.frame.origin.y,
            width: referenceView.bounds.size.width,
            height: referenceView.bounds.size.height
        )
        
        UIView.animate(
            withDuration: 0.2,
            animations: { () -> Void in
                
                referenceView.frame = originalFrame
                
                if let viewPool = self.rightViewPool {
                    for view in viewPool {
                        let width = referenceView.bounds.size.width
                        view.frame = CGRect(x: width, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
                    }
                }
                
                if let viewPool = self.leftViewPool {
                    for view in viewPool {
                        view.frame = CGRect(x: -view.bounds.size.width, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
                    }
                }
                
                
               
            },
            completion: nil
        )
        
    }
    
    

    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        
        let defaultActionPercentage = CGFloat(0.7)
        let referenceView = self.contentView
        
        if recognizer.state == .began {
            self.originalCenter = referenceView.center
            self.prepareAtionMenu()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SwipeActionMenuCellDismissNotification"), object: self)
        }
        
        if recognizer.state == .changed {
            
            let translation = recognizer.translation(in: self)
            
            referenceView.center = CGPoint(x: originalCenter.x + translation.x, y: originalCenter.y)

            // Disable swipe to left if no right menu
            if referenceView.x < 0 && (self.rightMenuItems == nil || self.rightMenuItems?.count < 0) {
                referenceView.x = 0
            }
            
            // Disable swipe to right if no left menu
            if referenceView.x > 0 && (self.leftMenuItems == nil || self.leftMenuItems?.count < 0) {
                referenceView.x = 0
            }
            
            // Limit swipe to left
            if referenceView.x < -self.bounds.size.width {
                referenceView.x = CGFloat(-self.bounds.size.width)
            }

            // Limit swipe to right
            if referenceView.x > self.bounds.size.width {
                referenceView.x = CGFloat(self.bounds.size.width)
            }
            
            if let viewPool = self.leftViewPool {
                
                if !disableSwipeLeft {
                    let delta = referenceView.frame.origin.x
                    self.leftCompleteOnDragRelease = delta > (factorOfSwipe * self.optionWidth * CGFloat(viewPool.count))
                    
                    let defaultLeftCompleteOnDrag = delta > self.bounds.size.width * defaultActionPercentage
                    let animated = defaultLeftCompleteOnDrag != self.defaultLeftActionCompleteOnDrag
                    self.defaultLeftActionCompleteOnDrag = defaultLeftCompleteOnDrag
                    
                    self.layoutMenuViews(referenceView, viewPool: viewPool, position: .left, animated: animated)
                }
                
            }
            
            if let viewPool = self.rightViewPool {
                let delta = self.bounds.size.width - referenceView.frame.maxX
                self.rightCompleteOnDragRelease = delta > (factorOfSwipe * self.optionWidth * CGFloat(viewPool.count))
                
                let defaultRightCompleteOnDrag = delta > self.bounds.size.width * defaultActionPercentage
                let animated = defaultRightCompleteOnDrag != self.defaultRightActionCompleteOnDrag
                self.defaultRightActionCompleteOnDrag = defaultRightCompleteOnDrag
                
                self.layoutMenuViews(referenceView, viewPool: viewPool, position: .right, animated: animated)
            }

        }
        
        if recognizer.state == .ended {
            
            if self.defaultRightActionCompleteOnDrag {
                if let data = self.defaultRightData, let action = data.action {
                    action()
                }
                self.dismissMenu()
                
            } else if self.defaultLeftActionCompleteOnDrag {
                if let data = self.defaultLeftData, let action = data.action {
                    action()
                }
                self.dismissMenu()
                
            } else if self.rightCompleteOnDragRelease {
                
                UIView.animate(
                    withDuration: 0.2,
                    animations: { () -> Void in
                        if let viewPool = self.rightViewPool {
                            referenceView.frame = CGRect(x: -(self.optionWidth * CGFloat(viewPool.count)), y: 0, width: referenceView.bounds.size.width, height: referenceView.bounds.size.height)
                            self.layoutMenuViews(referenceView, viewPool: viewPool, position: .right)
                        }
                    },
                    completion: { (success) in

                    }
                )
                
            } else if self.leftCompleteOnDragRelease {
                
                UIView.animate(
                    withDuration: 0.2,
                    animations: { () -> Void in
                        if let viewPool = self.leftViewPool {
                            referenceView.frame = CGRect(x: self.optionWidth * CGFloat(viewPool.count), y: 0, width: referenceView.bounds.size.width, height: referenceView.bounds.size.height)
                            self.layoutMenuViews(referenceView, viewPool: viewPool, position: .left)
                        }
                    },
                    completion: { (success) in
                    }
                )

            } else {
                
                self.dismissMenu()
                
            }
            
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }
}
