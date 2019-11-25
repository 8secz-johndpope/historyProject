//
//  TSChatParentView.swift
//  storefront-ios
//
//  Created by Kam on 26/12/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class TSChatParentView: UIView {

    /*
    // Library Dollar will be removed, all related function migrated to here
    */
    
    func chunk<T>(_ array: [T], size: Int = 1) -> [[T]] {
        var result = [[T]]()
        var chunk = -1
        for (index, elem) in array.enumerated() {
            if index % size == 0 {
                result.append([T]())
                chunk += 1
            }
            result[chunk].append(elem)
        }
        return result
    }

}
