//
//  UIImageViewExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 6/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Kingfisher
import Alamofire

extension UIImageView {
    
    @discardableResult
    func mm_setImageWithURL(_ URL: URL?,
                            placeholderImage: Image?,
                            clipsToBounds: Bool = true,
                            contentMode: UIViewContentMode = .scaleAspectFill,
                            progress: DownloadProgressBlock? = nil,
                            optionsInfo: KingfisherOptionsInfo? = nil,
                            completion: ((_ image: Image?,_ error: NSError?,_ cacheType: CacheType,_ imageURL: URL?) -> ())? = nil
        ) -> RetrieveImageTask? {
		
		guard URL != nil else { return nil }
		
        self.contentMode = contentMode
        self.clipsToBounds = clipsToBounds
		
        return self.kf.setImage(with: URL, placeholder: placeholderImage, options: optionsInfo, progressBlock: progress, completionHandler: {
            (_ image: Image?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: URL?) in
            completion?(image, error, cacheType, imageURL)
        })
    }
    
    @discardableResult
    func mm_setImageWithURLString(_ URLString: String?,
                                  placeholderImage: Image? = nil,
                                  clipsToBounds: Bool = true,
                                  contentMode: UIViewContentMode = .scaleAspectFit,
                                  progress: DownloadProgressBlock? = nil,
                                  optionsInfo: KingfisherOptionsInfo? = nil,
                                  completion: ((_ image: Image?,_ error: NSError?,_ cacheType: CacheType,_ imageURL: URL?) -> ())? = nil
        ) -> RetrieveImageTask? {
        
        guard let URLString = URLString, let URL = URL(string: URLString) else {
            return nil
        }
        
        return self.mm_setImageWithURL(
            URL,
            placeholderImage: placeholderImage,
            clipsToBounds: clipsToBounds,
            contentMode: contentMode,
            progress: progress,
            optionsInfo: optionsInfo,
            completion: completion
        )
    }
    
    var pixel: CGSize {
        get {
            let scale = UIScreen.main.scale
            return CGSize(width: size.width * scale, height: size.height * scale)
        }
    }
    
    func fadeIn(duration:CFTimeInterval) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        self.layer.add(transition, forKey: nil)
    }
    
    func setImageColor(color: UIColor) {
        guard let maskImage = self.image?.cgImage else { return }
        
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            self.image = UIImage(cgImage: cgImage)
        }
    }
}
