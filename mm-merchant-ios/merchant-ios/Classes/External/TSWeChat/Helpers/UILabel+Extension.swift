//
//  UILabel+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 1/19/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

extension UILabel {
    func contentSize() -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = self.lineBreakMode
        paragraphStyle.alignment = self.textAlignment
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: self.font, NSAttributedStringKey.paragraphStyle: paragraphStyle]
        let contentSize: CGSize = self.text!.boundingRect(
            with: self.frame.size,
            options: ([.usesLineFragmentOrigin, .usesFontLeading]),
            attributes: attributes,
            context: nil
        ).size
        return contentSize
    }
    
    func setFrameWithString(_ string: String, width: CGFloat, minWidth: CGFloat) {
        self.numberOfLines = 0
        let attributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font: self.font,
        ]
        let resultSize: CGSize = string.boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        ).size
        let resultHeight: CGFloat = resultSize.height
        var resultWidth: CGFloat = resultSize.width
        var frame: CGRect = self.frame
        if resultWidth < minWidth {
            resultWidth = minWidth //Min width
        }
        frame.size.height = resultHeight
        frame.size.width = resultWidth
        self.frame = frame
    }
}
