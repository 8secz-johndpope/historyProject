//
//  DropDownBanner.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

let shoutView = ShoutView()

public struct DropDownBanner {
    public static var backgroundColor = UIColor.white
    public static var dragIndicatorColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1)
    public static var titleColor = UIColor.black
    public static var subtitleColor = UIColor.black
    public static var titleFont = UIFont.boldSystemFont(ofSize: 15)
    public static var subtitleFont = UIFont.systemFont(ofSize: 13)
    public static var subtitleNumberOfLines = 1
}

public struct Announcement {
    
    public var title: String
    public var subtitle: String?
    public var image: UIImage?
    public var duration: TimeInterval
    public var action: (() -> Void)?
    public var swipeToDismiss: (() -> Void)?

    public init(title: String, subtitle: String? = nil, image: UIImage? = nil, duration: TimeInterval = 2, action: (() -> Void)? = nil, swipeToDismiss: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.duration = duration
        self.action = action
        self.swipeToDismiss = swipeToDismiss
    }
}

open class ShoutView: UIView {
    
    class func topWindow() -> UIWindow? {
        
        for window in UIApplication.shared.windows.reversed() {
            if window.windowLevel == UIWindowLevelStatusBar + 1 {
                return window
            }
            
            if window.windowLevel == UIWindowLevelNormal && !window.isHidden && window.frame != CGRect.zero {
                window.windowLevel = UIWindowLevelStatusBar + 1
                return window
            }
        }
        return nil
    }

    public struct Dimensions {
        public static let indicatorHeight: CGFloat = 6
        public static let indicatorWidth: CGFloat = 50
        public static let imageSize: CGFloat = 48
        public static let imageOffset: CGFloat = 18
        public static var height: CGFloat = UIApplication.shared.isStatusBarHidden ? 55 : 55 + App.screenStatusBarHeight
        public static var textOffset: CGFloat = 75
    }
    
    open fileprivate(set) lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = DropDownBanner.backgroundColor
        view.alpha = 0.98
        view.clipsToBounds = true
        
        return view
    }()
    
    open fileprivate(set) lazy var gestureContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    open fileprivate(set) lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = DropDownBanner.dragIndicatorColor
        view.layer.cornerRadius = Dimensions.indicatorHeight / 2
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    open fileprivate(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Dimensions.imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.white
        return imageView
    }()
    
    open fileprivate(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DropDownBanner.titleFont
        label.textColor = DropDownBanner.titleColor
        label.numberOfLines = 1
        
        return label
    }()
    
    open fileprivate(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = DropDownBanner.subtitleFont
        label.textColor = DropDownBanner.subtitleColor
        label.numberOfLines = DropDownBanner.subtitleNumberOfLines
        label.lineBreakMode = .byTruncatingTail
        
        return label
    }()
    
    open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))
        
        return gesture
        }()
    
    open fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))
        
        return gesture
        }()
    
    open fileprivate(set) var announcement: Announcement?
    open fileprivate(set) var displayTimer = Timer()
    open fileprivate(set) var panGestureActive = false
    open fileprivate(set) var completion: (() -> Void)?
    
    private var subtitleLabelOriginalHeight: CGFloat = 0
    private var duration: TimeInterval = 0

    // MARK: - Initializers
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundView)
        [indicatorView, imageView, titleLabel, subtitleLabel, gestureContainer].forEach {
            backgroundView.addSubview($0) }
        
        clipsToBounds = false
        isUserInteractionEnabled = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 0.5
        
        addGestureRecognizer(tapGestureRecognizer)
        gestureContainer.addGestureRecognizer(panGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // MARK: - Configuration
    
    open func show(_ announcement: Announcement, completion: (() -> Void)?) {
        Dimensions.height = UIApplication.shared.isStatusBarHidden ? 70 : 70 + App.screenStatusBarHeight
        
        panGestureActive = false
        configureView(announcement)
        shout()
        
        self.completion = completion
    }
    
    open func configureView(_ announcement: Announcement) {
        self.announcement = announcement
        imageView.image = announcement.image
        titleLabel.text = announcement.title
        subtitleLabel.text = announcement.subtitle
        duration = announcement.duration

        startTimerIfNeeded()
        
        setupFrames()
    }
    
    func startTimerIfNeeded() {
        displayTimer.invalidate()
        if duration > 0 {
            displayTimer = Timer.scheduledTimer(timeInterval: duration,
                                                                  target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)
        }
    }
    
    open func shout() {
        if let view = ShoutView.topWindow() {
            let width = UIScreen.main.bounds.width

            view.addSubview(self)

            frame = CGRect(x: 0, y: -Dimensions.height, width: width, height: Dimensions.height)
            backgroundView.frame = CGRect(x: 0, y: 0, width: width, height: Dimensions.height)
            
            UIView.animate(withDuration: 0.35, animations: {
                self.frame.origin.y = 0
                self.backgroundView.frame.size.height = self.frame.height
            })
        }
    }
    
    // MARK: - Setup
    
    open func setupFrames() {
        Dimensions.height = UIApplication.shared.isStatusBarHidden ? 55 : 55 + App.screenStatusBarHeight
        
        let totalWidth = UIScreen.main.bounds.width
        let offset: CGFloat = UIApplication.shared.isStatusBarHidden ? 2.5 : 5
        let imageSize: CGFloat = imageView.image != nil ? Dimensions.imageSize : 0
        
        [titleLabel, subtitleLabel].forEach {
            $0.frame.size.width = totalWidth - imageSize - (Dimensions.imageOffset * 2)
            $0.frame.size.height = 20
        }
        
        Dimensions.height += subtitleLabel.frame.height
        
        backgroundView.frame.size = CGSize(width: totalWidth, height: Dimensions.height)
        gestureContainer.frame = backgroundView.frame
        indicatorView.frame = CGRect(x: (totalWidth - Dimensions.indicatorWidth) / 2,
                                     y: Dimensions.height - Dimensions.indicatorHeight - 5, width: Dimensions.indicatorWidth, height: Dimensions.indicatorHeight)
        
        imageView.frame = CGRect(x: Dimensions.imageOffset, y: (Dimensions.height - imageSize) / 2 + offset,
                                 width: imageSize, height: imageSize)
        
        let textOffsetX: CGFloat = imageView.image != nil ? imageView.frame.maxX + 10 : 18
        let textOffsetY = imageView.image != nil ? imageView.frame.origin.y + 2 : textOffsetX + 5
        
        titleLabel.frame.origin = CGPoint(x: textOffsetX, y: textOffsetY)
        subtitleLabel.frame.origin = CGPoint(x: textOffsetX, y: titleLabel.frame.maxY + 2.5)
        
        if subtitleLabel.text?.isEmpty ?? true {
            titleLabel.center.y = imageView.center.y - 2.5
        }
    }
    
    // MARK: - Actions
    
    open func dismiss() {
        UIView.animate(withDuration: 0.35, animations: {
            self.frame.origin.y = -self.frame.size.height
            }, completion: { finished in
                self.completion?()
                self.displayTimer.invalidate()
                if let window = ShoutView.topWindow() {
                    window.windowLevel = UIWindowLevelNormal
                }
                self.removeFromSuperview()
        })
    }
    
    // MARK: - Timer methods
    
    @objc open func displayTimerDidFire() {
        if panGestureActive { return }
        dismiss()
    }
    
    // MARK: - Gesture methods
    
    @objc private func handleTapGestureRecognizer() {
        guard let announcement = announcement else { return }
        announcement.action?()
        dismiss()
    }
    
    @objc private func handlePanGestureRecognizer() {
        let translation = panGestureRecognizer.translation(in: self)
        var duration: TimeInterval = 0
        
        if panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began {
            displayTimer.invalidate()

            panGestureActive = true
            let maxHeight = Dimensions.height + 10
            if translation.y > 0 {
                frame.size.height = Dimensions.height + translation.y > maxHeight ? maxHeight : Dimensions.height + translation.y
            }
            else {
                frame.origin.y = translation.y
            }
        } else {
            panGestureActive = false
            
            duration = 0.2
            if translation.y < 0 {
                UIView.animate(withDuration: duration, animations: {
                    self.frame.origin.y = -self.frame.size.height
                    }, completion: { _ in
                        self.completion?()
                        
                        if let announcement = self.announcement {
                            announcement.swipeToDismiss?()
                        }

                        if let window = ShoutView.topWindow() {
                            window.windowLevel = UIWindowLevelNormal
                        }
                        self.removeFromSuperview()
                })
            }
            else {
                UIView.animate(withDuration: duration, animations: {
                    self.frame.size.height = Dimensions.height
                    self.frame.origin.y = 0
                    }, completion: nil)
            }
            startTimerIfNeeded()
        }
        
        UIView.animate(withDuration: duration, animations: {
            self.backgroundView.frame.size.height = self.frame.height
            self.indicatorView.frame.origin.y = self.frame.height - Dimensions.indicatorHeight - 5
        })
    }
}
