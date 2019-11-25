//
//  String+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 1/19/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation

extension String {
    func stringHeightWithMaxWidth(_ maxWidth: CGFloat, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font: font,
        ]
        let size: CGSize = self.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
            ).size
        return size.height
    }
    
    func stringSizeWithMaxWidth(_ maxWidth: CGFloat, font: UIFont) -> CGSize {
        let attributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font: font,
            ]
        let size: CGSize = self.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
            ).size
        return size
    }
    
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    func getTextWidth(height hgt: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: hgt)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.width
    }
}


