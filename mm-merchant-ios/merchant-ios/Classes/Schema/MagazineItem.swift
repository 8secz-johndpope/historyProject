//
//  MagazineItem.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/17/16.
//  Copyright © 2016 Quang Truong Dinh. All rights reserved.
//

import Foundation

import UIKit

class MagazineItem {
    
    var title: String
    var category: String
    var backgroungImageKey: String
    var backgroundImage: UIImage?
    
    init(title: String, category: String, backgroungImageKey: String) {
        self.title = title
        self.category = category
        self.backgroungImageKey = backgroungImageKey
    }
    
//    convenience init(dictionary: NSDictionary) {
//        let title = dictionary["Title"] as? String
//        let category = dictionary["Category"] as? String
//        let backgroundName = dictionary["Background"] as? String
//        let backgroundImage = UIImage(named: backgroundName!)
//        self.init(title: title!, category: category!, backgroundImage: backgroundImage!.decompressedImage)
//    }
    
}
