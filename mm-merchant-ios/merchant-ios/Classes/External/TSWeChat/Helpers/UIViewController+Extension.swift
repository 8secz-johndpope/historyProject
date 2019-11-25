//
//  UIViewController+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 11/6/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    /**
     直接加载 xib，创建 ViewController
     
     - returns: UIViewController
     */
    class func ts_initFromNib() -> UIViewController {
        let hasNib: Bool = Bundle.main.path(forResource: self.nameOfClass, ofType: "nib") != nil
        guard hasNib else {
            assert(!hasNib, "Invalid parameter") // here
            return UIViewController()
        }
        return self.init(nibName: self.nameOfClass, bundle: nil)
    }
    
    public static var ts_topViewController: UIViewController? {
        var presentedVC = UIApplication.shared.keyWindow?.rootViewController
        while let pVC = presentedVC?.presentedViewController {
            presentedVC = pVC
        }
        
        if presentedVC == nil {
            print("Error: You don't have any views set. You may be calling them in viewDidLoad. Try viewDidAppear instead.")
        }
        return presentedVC
    }
    
    /**
     present
     */
    public func ts_presentViewController(_ viewController: UIViewController, completion:(() -> Void)?) {
        let navigationController = UINavigationController(rootViewController: viewController)
        self.present(navigationController, animated: true, completion: completion)
    }
    
}




