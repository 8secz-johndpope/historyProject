//
//  GroupChatImageView.swift
//  GroupChatIcon
//
//  Created by Kam on 17/6/2016.
//  Copyright © 2016 Kam. All rights reserved.
//

import UIKit

enum MergeType: Int {
    case unknown = 0
    case singleImage = 1
    case twoImages = 2
    case mulitpleImages = 3
}

enum AlignType: Int {
    case leftRight = 0
    case topBottom = 1
}

enum PhotoType: Int {
    case unknown = 0
    case landscape = 1
    case portrait = 2
}

class GroupChatImageView: UIImageView {
    
    var placeHolder: UIImage?
    
    func setCombineImages(_ images: [UIImage]?) {
        if let imgs = images {
            let imgType: MergeType = MergeType(rawValue: imgs.count) ?? .mulitpleImages
            switch imgType {
            case .unknown:
                break;
            case .singleImage:
                self.image = imgs[0]
                break;
            case .twoImages:
                self.mergeHorizontalImage(imgs[0], secondImage: imgs[1])
                break;
            case .mulitpleImages:
                self.mergeMultipleImage(imgs[0], secondImage: imgs[1], thirdImage: imgs[2])
                break;
                
            }
        }
    }
    
    func mergeHorizontalImage(_ firstImage: UIImage?, secondImage: UIImage?) {
        if let firstImage = firstImage, let secondImage = secondImage {
            let containerSize = self.frame
            let drawArea = CGSize(width: containerSize.width/2, height: containerSize.height)
            
            UIGraphicsBeginImageContextWithOptions(
                containerSize.size,
                false,
                UIScreen.main.scale
            )
            
			if let context = UIGraphicsGetCurrentContext() {
				let strokeWidth = CGFloat(1)
				context.setFillColor(UIColor.clear.cgColor)
				context.setStrokeColor(UIColor.white.cgColor)
				context.setLineWidth(strokeWidth)
				
				let firstImageRef: CGImage = firstImage.cgImage!.cropping(to: self.getCropRect(CGRect(x: 0, y: 0, width: containerSize.width/2, height: containerSize.height), source: firstImage, alignType: .leftRight))!
				let firstCroppedImage : UIImage = UIImage(cgImage: firstImageRef)
				firstCroppedImage.draw(in: CGRect(x: 0, y: 0, width: drawArea.width, height: drawArea.height))
				
				let resizedSecImg = secondImage.scaleToSize(firstImage.size)
				let secondImageRef: CGImage = resizedSecImg.cgImage!.cropping(to: self.getCropRect(CGRect(x: 0, y: 0, width: containerSize.width/2, height: containerSize.height), source: resizedSecImg, alignType: .leftRight))!
				let secondCroppedImage : UIImage = UIImage(cgImage: secondImageRef)
				secondCroppedImage.draw(in: CGRect(x: drawArea.width, y: 0, width: drawArea.width, height: drawArea.height))
				
				context.addRect(CGRect(x: containerSize.width/2, y: 0, width: strokeWidth, height: containerSize.height))
				context.drawPath(using: .fillStroke)
			}
			
            let image = UIGraphicsGetImageFromCurrentImageContext()
			
            self.image = image
            
            UIGraphicsEndImageContext()
        }
    }
    
    func mergeMultipleImage(_ firstImage: UIImage?, secondImage: UIImage?, thirdImage: UIImage?) {
        if let firstImage = firstImage, let secondImage = secondImage, let thirdImage = thirdImage {
            let containerSize = CGSize(width: self.frame.width, height: self.frame.height)
            let drawArea = CGSize(width: containerSize.width/2, height: containerSize.height/2)
            
            UIGraphicsBeginImageContextWithOptions(
                containerSize,
                false,
                UIScreen.main.scale
            )
            
			if let context = UIGraphicsGetCurrentContext() {
				let strokeWidth = CGFloat(1)
				context.setFillColor(UIColor.clear.cgColor)
				context.setStrokeColor(UIColor.white.cgColor)
				context.setLineWidth(strokeWidth)
				
				let firstImageRef: CGImage = firstImage.cgImage!.cropping(to: self.getCropRect(
																				CGRect(x: 0, y: 0,
																					width: containerSize.width/2, height: containerSize.height),
																				source: firstImage,
																				alignType: .leftRight))!
				let firstCroppedImage : UIImage = UIImage(cgImage: firstImageRef)
				firstCroppedImage.draw(in: CGRect(x: 0, y: 0, width: containerSize.width/2, height: containerSize.height))
				
				let secondImageRef: CGImage = secondImage.cgImage!.cropping(to: self.getCropRect(                                      CGRect(x: 0, y: 0,
																				width: containerSize.width/2, height: containerSize.height/2),
																				source: secondImage,
																				alignType: .topBottom))!
				let secondCroppedImage : UIImage = UIImage(cgImage: secondImageRef)
				secondCroppedImage.draw(in: CGRect(x: drawArea.width, y: 0, width: drawArea.width, height: drawArea.height))
				
				let resizedThirdImg = thirdImage.scaleToSize(secondImage.size)
				let thirdImageRef: CGImage = resizedThirdImg.cgImage!.cropping(to: self.getCropRect(CGRect(x: 0, y: 0,
																				width: containerSize.width/2, height: containerSize.height/2),
																				source: resizedThirdImg,
																				alignType: .topBottom))!
				let thirdCroppedImage : UIImage = UIImage(cgImage: thirdImageRef)
				thirdCroppedImage.draw(in: CGRect(x: drawArea.width, y: drawArea.height, width: drawArea.width, height: drawArea.height))
				
				context.addRect(CGRect(x: containerSize.width/2, y: 0, width: strokeWidth, height: containerSize.height))
				context.drawPath(using: .fillStroke)
				
				context.addRect(CGRect(x: containerSize.width/2, y: drawArea.height, width: drawArea.width, height: strokeWidth))
				context.drawPath(using: .fillStroke)
			}
			
            let image = UIGraphicsGetImageFromCurrentImageContext()
			
            self.image = image
			
            UIGraphicsEndImageContext()
        }
    }
	
    func getCropRect(_ container: CGRect, source: UIImage, alignType: AlignType) -> CGRect {
        var imageType: PhotoType = PhotoType.unknown
		
        let containerWidth = container.width
        let containerHeight = container.height
        let sourceWidth = source.size.width
        let sourceHeight = source.size.height
        var adjustedContainerWidth = containerWidth
        var adjustedContainerHeight = containerHeight
        var ratio = CGFloat(1)
		
        if sourceWidth >= sourceHeight {
            imageType = .landscape
            ratio = sourceHeight/containerHeight
        } else {
            imageType = .portrait
            ratio = sourceWidth/containerWidth
        }
        
        adjustedContainerWidth *= ratio
        adjustedContainerHeight *= ratio
        
        //let centerX = sourceWidth/2
        let centerY = sourceHeight/2
        var rect: CGRect?
        var diff = CGFloat(0)
        
        switch alignType {
        case .leftRight:
            if (imageType == .landscape) {
                diff = sourceWidth - adjustedContainerWidth
                rect = CGRect(x: (diff/2), y: 0, width: sourceWidth - diff, height: sourceHeight)
            } else if (imageType == .portrait) {
                if (adjustedContainerWidth == sourceWidth) {
                    diff = adjustedContainerHeight - sourceHeight
                    rect = CGRect(x: (diff/2)/2, y: 0, width: adjustedContainerWidth - (diff/2), height: sourceHeight)
                } else {
                    diff = adjustedContainerWidth - sourceWidth
                    rect = CGRect(x: 0, y: (diff/2)/2, width: sourceWidth, height: adjustedContainerHeight - (diff/2)) /* need check */
                    
                }
            }
            break;
        case .topBottom:
            if (imageType == .landscape) {
                diff = sourceWidth - adjustedContainerWidth
                rect = CGRect(x: (diff/2), y: 0, width: sourceWidth - diff, height: sourceHeight)
            } else if (imageType == .portrait) {
                diff = sourceHeight - adjustedContainerHeight
                rect = CGRect(x: 0, y: (diff/2), width: sourceWidth, height: centerY + (diff/2))
            }
            break;
        }
        
        if let resultRect = rect {
            return resultRect
        }
        
        return CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight)
    }
    
    
}
