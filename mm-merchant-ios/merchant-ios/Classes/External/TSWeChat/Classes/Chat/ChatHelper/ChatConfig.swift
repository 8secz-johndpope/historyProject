//
//  ChatConfig.swift
//  TSWeChat
//
//  Created by Hilen on 2/25/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation


open class ChatConfig {
    
    /**
     获取缩略图的尺寸
     
     - parameter originalSize: 原始图的尺寸 size
     
     - returns: 返回的缩略图尺寸
     */
    class func getSendImageSize(_ originalSize: CGSize, inboundSize: CGSize?=nil) -> CGSize {
        
        let imageRealHeight = originalSize.height
        let imageRealWidth = originalSize.width
        
        var resizeThumbWidth: CGFloat
        var resizeThumbHeight: CGFloat
        /**
         *  1）如果图片的高度 >= 图片的宽度 , 高度就是最大的高度，宽度等比
         *  2）如果图片的高度 < 图片的宽度 , 以宽度来做等比，算出高度
         */
        var boundSize = inboundSize
        if boundSize == nil {
            boundSize = CGSize(width: kChatImageMaxWidth, height: kChatImageMaxHeight)
        }
        
        if imageRealHeight >= imageRealWidth {
            let scaleWidth = imageRealWidth * boundSize!.height / imageRealHeight
            resizeThumbWidth = (scaleWidth > kChatImageMinWidth) ? scaleWidth : kChatImageMinWidth
            resizeThumbHeight = boundSize!.height
        } else {
            let scaleHeight = imageRealHeight * boundSize!.width / imageRealWidth
            resizeThumbHeight = (scaleHeight > kChatImageMinHeight) ? scaleHeight : kChatImageMinHeight
            resizeThumbWidth = boundSize!.width
        }
        
        return CGSize(width: resizeThumbWidth, height: resizeThumbHeight)
    }
    
    class func getThumbImageSize(_ originalSize: CGSize) -> CGSize {
        
        /**
         *  1）如果图片的高度 >= 图片的宽度 , 高度就是最大的高度，宽度等比
         *  2）如果图片的高度 < 图片的宽度 , 以宽度来做等比，算出高度
         */
        
        if originalSize.height >= originalSize.width {
            return CGSize(width: kChatImageMaxWidth,height: kChatImageMaxHeight)
        } else {
            return CGSize(width: kChatImageMaxHeight , height: kChatImageMaxWidth)
        }
    }
}



