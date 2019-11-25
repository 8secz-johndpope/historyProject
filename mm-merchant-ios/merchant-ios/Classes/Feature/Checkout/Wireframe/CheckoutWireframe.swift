//
//  CheckoutWireframe.swift
//  merchant-ios
//
//  Created by Jerry Chong on 19/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


final class CheckoutWireframe {
    
    
    static var mainViewController: FCheckoutViewController?
    
    class func presentOrderDetailPage(_ sectionData: OrderSectionData, fromViewController vc: UIViewController) {
        if let navigationController = vc.navigationController {
            navigationController.modalPresentationStyle = .overFullScreen
            let orderDetailViewController = OrderDetailViewController()
            orderDetailViewController.originalViewMode = .toBeShipped
            orderDetailViewController.orderSectionData = sectionData
            navigationController.push(orderDetailViewController, animated: true)
        }
    }
    
    
    class func presentFapiaoPage(_ fapiao: String, fromViewController vc: UIViewController, completion: ((_ fapiao: String) -> ())?) {
        if let navigationController = vc.navigationController {
            let fapiaoViewController = FapiaoViewController()
            fapiaoViewController.fapiaoText = fapiao
            fapiaoViewController.fapiaoHandler = { (fapiaoText) in
                fapiaoViewController.navigationController?.popViewController(animated: true)
                completion?(fapiaoText)
            }
            navigationController.push(fapiaoViewController, animated: true)
        }
    }
    
    class func presentAddressPage(_ address: Address?, mode: SignupMode, fromViewController vc: UIViewController, completion: ((_ address: Address?) -> ())?) {
        if let navigationController = vc.navigationController {
            if (address != nil && address?.userAddressKey.length > 0){
                let addressSelectionViewController = AddressSelectionViewController()
                addressSelectionViewController.viewMode = mode
                addressSelectionViewController.selectedAddress = address
                addressSelectionViewController.didSelectAddress = { (address) -> Void in
                    completion?(address)
                }
                if (mode == .checkoutSwipeToPay){
                    navigationController.isNavigationBarHidden = false
                }
                navigationController.push(addressSelectionViewController, animated: true)
            }else{
                let addressAdditionViewController = AddressAdditionViewController()
                addressAdditionViewController.signupMode = .checkoutSwipeToPay
                addressAdditionViewController.disableBackButton = false
                addressAdditionViewController.didAddAddress = {  (address)  in
                    completion?(address)
                }
                if (mode == .checkoutSwipeToPay){
                    addressAdditionViewController.continueCheckoutProcess = true
                    navigationController.isNavigationBarHidden = false
                }
                navigationController.push(addressAdditionViewController, animated: true)
            }

        }
    }
    
    class func presentDismiss(fromViewController vc: UIViewController) {
        if let navigationController = vc.navigationController {
            navigationController.dismiss(animated: true, completion: nil)
        }
    }
    
    class func presentConfimationPage(fromViewController vc: UIViewController, checkoutMode: CheckoutMode, skus: [Sku], styles: [Style], referrerUserKeys: [String : String], targetRef: String, checkoutFromSource: CheckoutFromSource = .unknown) {
        if let navigationController = vc.navigationController {
            let checkoutViewController = FCheckoutViewController(checkoutMode: checkoutMode, skus: skus, styles: styles, referrerUserKeys: referrerUserKeys, targetRef: targetRef)
            checkoutViewController.isCart = false
            checkoutViewController.checkoutFromSource = checkoutFromSource
            if let vc = vc as? FCheckoutViewController {
                mainViewController = vc
                checkoutViewController.styleViewController = vc.styleViewController
            }
            navigationController.push(checkoutViewController, animated: true)
        }

    }

}
