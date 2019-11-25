//
//  ImageHelper.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ImageHelper {
    
    class func resizeImageLocal(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
        
        var ratio  = CGFloat(1)
        var newSize: CGSize
        if(image.size.width > image.size.height) {
            if image.size.width > maxWidth {
                ratio = maxWidth / image.size.width
            }
            
        } else {
            if image.size.height > maxWidth {
                ratio = maxWidth / image.size.height
            }
        }
        
        newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    class func resizeCoverImage(_ image: UIImage) -> UIImage {
        
        let maxWidth = ImageSizeCrop.width_max
        var ratio = CGFloat(1)
        if maxWidth < image.size.width {
            ratio = maxWidth / image.size.width
        }
        
        var newSize: CGSize
        
        newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
	
	class func getServerAcceptedImageSize(_ image: UIImage) -> UIImage {
		var resizedImage = image
		
		if let data = UIImageJPEGRepresentation(image, 1) {
			let imageSize: Int = data.count
			if imageSize >= Constants.MaxImageSize {
				
				let compressionRatio = (CGFloat(Constants.MaxImageSize) / CGFloat(imageSize))
				if let compressedImage = image.resizeWithPercentage(compressionRatio){
					if let compressedData = UIImageJPEGRepresentation(compressedImage, 1){
						let compressedImageSize: Int = compressedData.count
						Log.debug("The compressed image size is" + String(compressedImageSize))
					}
					resizedImage = compressedImage
				}
			}
		}
		return resizedImage
	}
	
}
