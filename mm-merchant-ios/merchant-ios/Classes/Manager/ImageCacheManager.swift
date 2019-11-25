//
//  ImageCacheManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Kingfisher

@objc class ImageCacheManager : NSObject{
    static func configCache(){
        let cache = KingfisherManager.shared.cache
        
        // Set max memory cache. Default is no limit.
        cache.maxMemoryCost = 40 * 1024 * 1024 //40 mb ~ 10 1024 x 1024 images
        
        // Set max disk cache. Default is no limit.
        cache.maxDiskCacheSize = 200 * 1024 * 1024
        
        // Set max disk cache to duration, Default is 1 week.
        cache.maxCachePeriodInSecond = 60 * 60 * 24 * 7
        
        // Get the disk size taken by the cache.
        cache.calculateDiskCacheSize { (size) -> () in
            print("disk size in bytes: \(size)")
        }
    }
    
    static func clearCache(){
        
        let cache = KingfisherManager.shared.cache

        // Clear memory cache right away.
        cache.clearMemoryCache()
        
        // Clear disk cache. This is an async operation.
        cache.clearDiskCache()
        
        // Clean expired or size exceeded disk cache. This is an async operation.
        cache.cleanExpiredDiskCache()
    }
    
    static func clearMemoryCache(){
        
        // Clear memory cache right away.
        KingfisherManager.shared.cache.clearMemoryCache()
    }
    static func loadImage(_ imageView: UIImageView){
        print("loaded")
    }
    
    @objc static func loadImage(_ imageView: UIImageView,
                          URL: Foundation.URL,
                          placeholderImage: Image?,
                          contentMode: UIViewContentMode = .scaleAspectFit,
                          completion: ((_ image: Image?, _ error: NSError?) -> ())?) {
        
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.kf.setImage(with: URL, placeholder: placeholderImage, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
            if completion != nil {
                completion!(image, error)
            }
        })
    }

    
}
