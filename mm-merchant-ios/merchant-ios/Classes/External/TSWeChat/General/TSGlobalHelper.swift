//
//  TSGlobalHelper.swift
//  TSWeChat
//
//  Created by Hilen on 3/2/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation


// stolen from Kingfisher: https://github.com/onevcat/Kingfisher/blob/master/Sources/ThreadHelper.swift

func dispatch_async_safely_to_main_queue(_ block: @escaping ()->()) {
    dispatch_async_safely_to_queue(DispatchQueue.main, block)
}

// This methd will dispatch the `block` to a specified `queue`.
// If the `queue` is the main queue, and current thread is main thread, the block
// will be invoked immediately instead of being dispatched.
func dispatch_async_safely_to_queue(_ queue: DispatchQueue, _ block: @escaping ()->()) {
    if queue === DispatchQueue.main && Thread.isMainThread {
        block()
    } else {
        queue.async {
            block()
        }
    }
}

func TSAlertView_show(_ title: String, message: String? = nil, labelCancel: String? = String.localize("LB_CANCEL")) {
    
    dispatch_async_safely_to_queue(DispatchQueue.main) { 
        var theMessage = ""
        if message != nil {
            theMessage = message!
        }
        
        let alertView = UIAlertView(title: title , message: theMessage, delegate: nil, cancelButtonTitle: labelCancel, otherButtonTitles:String.localize("LB_OK"))
        alertView.show()
    }
}
