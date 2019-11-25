//
//  UIImageExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 29/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

extension UIImage {
    func normalizedImage() -> UIImage {
        
        if (self.imageOrientation == UIImageOrientation.up) {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect)
        
        let normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        
        if let data = UIImageJPEGRepresentation(normalizedImage, 1), let image = UIImage(data: data) {
            return image
        }
        
        return normalizedImage;
    }
    
    var decompressedImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        draw(at: CGPoint.zero)
        let decompressedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return decompressedImage!
    }
    
    func getCropImage(_ newSize: CGSize) -> UIImage {
        if (self.size.width > newSize.width || self.size.height > newSize.height) {
            return self.resize(CGSize(width: ImageSizeCrop.width_max, height: ImageSizeCrop.height_max), contentMode: UIImage.UIImageContentMode.scaleToFill, quality: CGInterpolationQuality.high)!

        } else {
            return self
        }
    }
    
    func scaleImage(_ width: CGFloat) -> UIImage {
        var ratio  = CGFloat(1)
        var newSize: CGSize
        
        ratio = width/self.size.width
        
        newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func scaleToSize(_ newSize: CGSize) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func resizeWithPercentage(_ percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func resizeWithWidth(_ width: CGFloat) -> UIImage? {
        let width = width / scale
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(width/size.width * size.height))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    func fillBackgroundWithColor(_ color: UIColor) -> UIImage
    {
        let width = self.size.width
        let height = self.size.height
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        var rectImage = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > height {
            bounds = CGRect(x: 0, y: 0, width: width, height: width)
        }else {
            bounds = CGRect(x: 0, y: 0, width: height, height: height)
        }
        rectImage.origin.x = (bounds.size.width - rectImage.size.width) / 2
        rectImage.origin.y = (bounds.size.height - rectImage.size.height) / 2
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        color.setFill()
        UIRectFill(bounds)
        
        self.draw(in: rectImage)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    /**
     Applies gradient color overlay to an image.
     
     :param: gradientColors :[UIColor] The colors to use for the gradient.
     :param: blendMode :CGBlendMode The blending type to use.
     
     :returns: A new UIImage
     */
    func apply(gradientColors: [UIColor], locations: [Float] = [], blendMode: CGBlendMode = CGBlendMode.normal) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(blendMode)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        context?.draw(self.cgImage!, in: rect)
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = gradientColors.map {(color: UIColor) -> Any? in return color.cgColor as Any? } as NSArray
        let gradient: CGGradient
        if locations.count > 0 {
            let cgLocations = locations.map { CGFloat($0) }
            gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: cgLocations)!
        } else {
            gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
        }
        // Apply gradient
        context?.clip(to: rect, mask: self.cgImage!)
        context?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: CGGradientDrawingOptions(rawValue: 0))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image!;
    }
    // MARK: Crop
    
    /**
     Creates a cropped copy of an image.
     
     :param: bounds :CGRect The bounds of the rectangle inside the image.
     
     :returns: UIImage?
     */
    func crop(bounds: CGRect) -> UIImage?
    {
        let imageRef = self.cgImage!.cropping(to: bounds)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
    // MARK: Image From URL
    
    /**
     Creates a new image from a URL with optional caching.
     
     :param: url :String The image URL.
     :param: placeholder :UIImage The placeholder image.
     :param: shouldCacheImage :Bool Weather or not we should cache the NSURL response (default: true)
     :param: closure :(image: UIImage?) The image from the web the first time is fetched.
     
     :returns: UIImage?
     :discussion: If cached, the cached image is returned. Otherwise, a place holder is used until the image from web is returned by the closure.
     */
    
    class func image(fromURL url: String, placeholder: UIImage, shouldCacheImage: Bool = true, closure: @escaping (_ image: UIImage?) -> ()) {
        // From Cache
        if shouldCacheImage {
            if let imageURL = URL(string: url), let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
                closure(image)
            }
        }
        // Fetch Image
        let session = URLSession(configuration: URLSessionConfiguration.default)
        if let nsURL = URL(string: url) {
            session.dataTask(with: nsURL, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    DispatchQueue.main.async {
                        closure(nil)
                    }
                }else {
                    DispatchQueue.main.async {
                        closure(placeholder)
                    }
                    
                }
                if let data = data, let image = UIImage(data: data) {
                    if shouldCacheImage {
                        UIImage.shared.setObject(image as AnyObject, forKey: url as AnyObject)
                    }
                    DispatchQueue.main.async {
                        closure(image)
                    }
                }
                session.finishTasksAndInvalidate()
            }).resume()
        }
    }
    /**
     A singleton shared NSURL cache used for images from URL
     */
    static var shared: NSCache<AnyObject, AnyObject> {
        struct StaticSharedCache {
            static var shared = NSCache<AnyObject, AnyObject>()
        }
        
        return StaticSharedCache.shared
    }
    
    public func imageHasAlpha() -> Bool {
        let alphaInfo:CGImageAlphaInfo = self.cgImage!.alphaInfo
        return (alphaInfo == CGImageAlphaInfo.first ||
            alphaInfo == CGImageAlphaInfo.last  ||
            alphaInfo == CGImageAlphaInfo.premultipliedFirst ||
            alphaInfo == CGImageAlphaInfo.premultipliedLast)
    }
    
    func croppedImageWithFrame(frame:CGRect) -> UIImage {
        var croppedImage:UIImage = UIImage()
        UIGraphicsBeginImageContextWithOptions(frame.size, !imageHasAlpha(), self.scale)
        let content = UIGraphicsGetCurrentContext()
        content!.translateBy(x: -frame.origin.x, y: -frame.origin.y)
        draw(at: CGPoint.zero)
        croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return UIImage(cgImage: croppedImage.cgImage!, scale: UIScreen.main.scale, orientation: .up)
    }

}
