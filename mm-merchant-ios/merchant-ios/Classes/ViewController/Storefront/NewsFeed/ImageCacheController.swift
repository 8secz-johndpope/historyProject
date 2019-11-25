//
//  ImageCacheController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//
import Foundation
import Photos

class ImageCacheController {
    
    private var cachedIndices = IndexSet()
    var cachePreheatSize: Int
    var imageCache: PHCachingImageManager
    var images: PHFetchResult<PHAsset>
    var targetSize = CGSize(width: 320, height: 320)
    var contentMode = PHImageContentMode.aspectFill
    
    init(imageManager: PHCachingImageManager, images: PHFetchResult<PHAsset>, preheatSize: Int = 1) {
        self.cachePreheatSize = preheatSize
        self.imageCache = imageManager
        self.images = images
    }
    
    /***********
 
    // Temporary removed for migration  
 
     ***********/
    
    func updateVisibleCells(_ visibleCells: [IndexPath]) {
//        let updatedCache = NSMutableIndexSet()
//        for path in visibleCells {
//            updatedCache.add(path.item)
//        }
//        let minCache = max(0, updatedCache.first - cachePreheatSize)
//        let maxCache = min(images.count - 1, updatedCache.last + cachePreheatSize)
//        updatedCache.add(in: NSRange(location: minCache, length: maxCache - minCache + 1))
//
//        // Which indices can be chucked?
//        (self.cachedIndices as NSIndexSet).enumerate {
//            index, _ in
//            if !updatedCache.contains(index) {
//                let asset: PHAsset! = self.images[index]
//                self.imageCache.stopCachingImages(for: [asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
//
//            }
//        }
//
//        // And which are new?
//        updatedCache.enumerate {
//            index, _ in
//            if !self.cachedIndices.contains(index) {
//                let asset: PHAsset! = self.images[index]
//                self.imageCache.startCachingImages(for: [asset], targetSize: self.targetSize, contentMode: self.contentMode, options: nil)
//
//            }
//        }
//        cachedIndices = IndexSet(updatedCache)
    }
    
}
