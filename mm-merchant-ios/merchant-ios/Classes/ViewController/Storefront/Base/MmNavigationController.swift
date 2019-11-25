//
//  MmNavigationController.swift
//  storefront-ios
//
//  Created by Kam on 27/2/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

protocol MMNavigationControllerDelegate: NSObjectProtocol {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility?
}

enum MmFadeNavigationControllerNavigationBarVisibility: Int {
    case undefined = 0, // Initial value, don't set this
    system = 1, // Use System navigation bar
    hidden = 2, // Use custom navigation bar and hide it
    visible = 3 // Use custom navigation bar and show it
}

class MmNavigationController: UINavigationController {
    
    var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .undefined
    var preferredNavigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .undefined
    private var backgroundColorView: UIView?
    
    var volatileContainers: Bool = true
    
    //表示这个控制器支持router压栈,
    override func volatileContainer() -> Bool {
        return volatileContainers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.setBackgroundColor(.white) //requested by Kami on 20180320, all navigation bar background color set to white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshNavigationBar() {
        self.setNavigationBarVisibility(navigationBarVisibility: navigationBarVisibility)
    }
    
    func setNavigationBarVisibility(navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility) {
        guard navigationBarVisibility != .undefined else {
            return
        }
        
        var alpha: CGFloat = 1.0
        if navigationBarVisibility == .hidden {
            alpha = 0.0
            self.navigationBar.shadowImage = UIImage()
        } else {
            alpha = 1.0
            self.navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
        }
        if navigationBarVisibility != .visible {
            self.setBackgroundColor(.white) //default nav bar color
        }
        self.applyNavigationBarAlpha(alpha)
    }
    
    func setBackgroundColor(_ color: UIColor) {
        if backgroundColorView == nil {
            backgroundColorView = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.navigationBar.bounds.width), height: Int(StartYPos)))
            backgroundColorView?.autoresizingMask = .flexibleWidth
            self.navigationBar.subviews.first?.insertSubview(backgroundColorView ?? UIView(), at: 0)
        }
        backgroundColorView?.backgroundColor = color
    }
    
    open func setNavigationBarVisibility(offset: CGFloat) {
        var offset = offset / 100
        if offset > 1 {
            offset = 1
        }
        self.applyNavigationBarAlpha(offset)
        self.navigationBar.shadowImage = offset > 0.95 ? UINavigationBar.appearance().shadowImage : UIImage()
    }
    
    func preferredStatusBarStyle() -> UIStatusBarStyle {
        if self.navigationBarVisibility == .hidden {
            return .lightContent;
        } else {
            return .default;
        }
    }
    
    func updateNavigationBarVisibilityForController(viewController: UIViewController, animated: Bool) {
        self.navigationBarVisibility  = .system

        if let navigationBarVisibility = (viewController as? MMNavigationControllerDelegate)?.preferredNavigationBarVisibility() {
            self.navigationBarVisibility = navigationBarVisibility
        }
        
        self.setNavigationBarVisibility(navigationBarVisibility: self.navigationBarVisibility)
        UIApplication.shared.statusBarStyle = self.preferredStatusBarStyle()
    }
    
    private func applyNavigationBarAlpha(_ alpha: CGFloat) {
        let subviews = self.navigationBar.subviews
        if let barBackgroundView = subviews.first {
            if #available(iOS 11.0, *) {
                barBackgroundView.alpha = alpha
                for view in barBackgroundView.subviews {
                    view.alpha = alpha
                }
            } else {
                barBackgroundView.alpha = alpha
            }
        }
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
    
}

extension MmNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard !navigationController.isNavigationBarHidden else {
            return
        }
        self.updateNavigationBarVisibilityForController(viewController: viewController, animated: false)
    }
}
