//
//  PhotoCollageViewController.swift
//  PhotoFrame
//
//  Created by Markus Chow on 2/5/2016.
//  Copyright © 2016 Markus Chow. All rights reserved.
//

import UIKit
import Foundation
import Kingfisher
import Photos

class PhotoFrame: NSObject {
    var image: UIImage!
    var skue : Sku!
    var from: ModeTagProduct!
    var photoId = ""
    var index = 0
    var lastFrame = CGRect.zero 	
	init(photo: UIImage, sku: Sku, from: ModeTagProduct){
        super.init()
        self.image = photo
        self.skue = sku
        self.from = from
    }
}
