//
//  Alert.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit

class Alert {
    class func alert(_ viewController: UIViewController, title: String, message: String, okTitle: String? = nil, boldOkButton: Bool = false, okActionComplete: (() -> Void)? = nil, cancelTitle: String? = nil, cancelActionComplete: (() -> Void)? = nil, tintColor: UIColor? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: okTitle ?? String.localize("LB_CA_CONFIRM"), style: .default) { UIAlertAction in
            if let ok = okActionComplete {
                ok()
            }
            
            Log.debug("OK Pressed")
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle ?? String.localize("LB_CA_CANCEL"), style: .cancel) { UIAlertAction in
            if let cancel = cancelActionComplete {
                cancel()
            }

            Log.debug("Cancel Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        if boldOkButton {
            if #available(iOS 9.0, *) {
                alertController.preferredAction = okAction
            }
        }
        
        // set tint color for Buttons
        if let color = tintColor {
            alertController.view.tintColor = color
        } else {
            alertController.view.tintColor = UIColor.alertTintColor()
        }
        
        // Present the controller
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    class func alertWithSingleButton(_ viewController: UIViewController, title: String, message: String, buttonString: String? = nil, actionComplete: (() -> Void)? = nil) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        // Create the actions
        
        var buttonTitle: String!
        
        if buttonString == nil {
            buttonTitle = String.localize("LB_CA_CONFIRM")
        } else {
            buttonTitle = buttonString
        }

        let alertAction = UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.default) {
            UIAlertAction in
            
            if let action = actionComplete {
                action()
            }
        }
        
        alertController.view.tintColor = UIColor.alertTintColor()
        
        // Add the actions
        alertController.addAction(alertAction)
        
        // Present the controller
        viewController.present(alertController, animated: true, completion: nil)
    }

}
