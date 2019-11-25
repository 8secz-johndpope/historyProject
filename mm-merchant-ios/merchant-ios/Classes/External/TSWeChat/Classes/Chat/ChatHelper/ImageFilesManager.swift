//
//  ImageFilesManager.swift
//  TSWeChat
//
//  Created by Hilen on 2/24/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation
import Kingfisher

/*
    围绕 Kingfisher 构建的缓存器，先预存图片名称，等待上传完毕后改成 URL 的名字。
    https://github.com/onevcat/Kingfisher/blob/master/Sources%2FImageCache.swift#l625
*/

class ImageFilesManager {
    let imageCacheFolder = KingfisherManager.shared.cache
    
    class func cachePathForKey(_ key: String) -> String? {
        let fileName = key.md5()
        return ((KingfisherManager.shared.cache.diskCachePath as NSString).appendingPathComponent(fileName) as String)
    }
    
    class func storeImage(_ image: UIImage, key: String, completionHandler: (() -> Void)?) {
        KingfisherManager.shared.cache.removeImage(forKey: key)
        KingfisherManager.shared.cache.store(
            image,
            original: UIImageJPEGRepresentation(image, 0.9),
            forKey: key,
            toDisk: true,
            completionHandler: completionHandler
        )
    }
    
    class func cachedImageForKey(_ key: String, completion: @escaping CompletionHandler) {
        if let url = self.cachePathForKey(key) {
            KingfisherManager.shared.retrieveImage(
                with: ImageResource(downloadURL: URL(fileURLWithPath: url)),
                options: nil,
                progressBlock: nil,
                completionHandler: completion
            )
        }
    }
    
    /**
     修改文件名称
     
     - parameter originPath:      原路径
     - parameter destinationPath: 目标路径
     
     - returns: 目标路径
     */
    class func renameFile(_ originPath: URL, destinationPath: URL) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: originPath.path, toPath: destinationPath.path)
            return true
        } catch let error as NSError {
            log.error("error:\(error)")
            return false
        }
    }
}





