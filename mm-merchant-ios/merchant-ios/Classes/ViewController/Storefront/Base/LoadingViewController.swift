//
//  LoadingViewController.swift
//  storefront-ios
//
//  Created by Alan Team on 16/1/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation
import MBProgressHUD

class LoadingViewController: UIViewController,MMUIControllerInitProtocol {
    
    var loadingView: UIView!
    
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func showLoading() {
        if self.loadingView == nil {
            self.loadingView = UIView(frame: (self.view.bounds))
        }
        
        self.view.addSubview(self.loadingView)
        MBProgressHUD.showAdded(to: self.loadingView, animated: true)
    }
    
    func stopLoading() {
        main_async  { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadingView?.removeFromSuperview()
            
            if let loadingView = strongSelf.loadingView {
                MBProgressHUD.hide(for: loadingView, animated: true)
            }
        }
    }
    
    func showLoadingInScreenCenter(){
        if let window = UIApplication.shared.delegate?.window{
            if self.loadingView == nil {
                self.loadingView = UIView(frame: (window?.bounds) ?? CGRect.zero)
            }
            
            window?.addSubview(self.loadingView)
            MBProgressHUD.showAdded(to: self.loadingView, animated: true)
        }
    }
    
    func showFailPopupWithText(_ text: String, delegate: MmViewController? = nil) {
        if let view = self.navigationController?.view ?? self.view {
            dispatch_async_safely_to_main_queue({
                MBProgressHUD.hideAllHUDs(for: view, animated: false)
                if let hud = MBProgressHUD.showAdded(to: view, animated: true) {
                    if let dlgate = delegate {
                        hud.delegate = dlgate
                    }
                    hud.isUserInteractionEnabled = false
                    hud.mode = .customView
                    hud.opacity = 0.7
                    hud.labelText = text
                    hud.margin = 10
                    hud.hide(true, afterDelay: 1.5)
                }
            })
        }
    }
}
