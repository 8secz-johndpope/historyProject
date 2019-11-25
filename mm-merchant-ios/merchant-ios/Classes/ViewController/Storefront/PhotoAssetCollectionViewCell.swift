//
//  PhotoAssetCollectionViewCell.swift
//  merchant-ios
//
//  Created by Alan YU on 10/3/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import Photos

class PhotoAssetCollectionViewCell: UICollectionViewCell {
    
    private var requestID: PHImageRequestID?
    
    var asset: PHAsset? {
        didSet {
            if let ID = requestID {
                Photo.imageManager.cancelImageRequest(ID)
                requestID = nil
            }
            
            if let strongAsset = asset {
                
                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                
                requestID = Photo.imageManager.requestImage(
                    for: strongAsset,
                    targetSize: self.bounds.size,
                    contentMode: .aspectFill,
                    options: options,
                    resultHandler: { [weak self] (image, info) -> Void in
                        // requestID maybe nil because the first response synchronously
                        if let strongSelf = self, let key = info?[PHImageResultRequestIDKey] as? Int, strongSelf.requestID == nil || key == Int(strongSelf.requestID!) {
                            autoreleasepool {
                                strongSelf.didAssetReady(image)
                            }
                        }
                    }
                )
            } else {
                autoreleasepool {
                    didAssetReady(nil)
                }
            }
        }
    }
    
    func didAssetReady(_ image: UIImage?) {
        // override by subclasses
    }
    
}
