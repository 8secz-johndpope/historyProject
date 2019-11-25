//
//  ShipmentTextReusableView.swift
//  merchant-ios
//
//  Created by LongTa on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


class ShipmentTextReusableView: UICollectionReusableView {
    
    static let HeaderIdentifier = "ShipmentHeaderTextReusableView"
    static let FooterIdentifier = "ShipmentFooterTextReusableView"
    static let PaddingLeftRight = CGFloat(10)
    static let SmallTextHeight = CGFloat(22)
    static let ContentFont: UIFont = {
        let size = CGFloat(14)
        var name = Constants.iOS8Font.Bold
        if #available(iOS 9.0, *) {
            name = Constants.Font.Bold
        }
        if let font = UIFont(name: name, size: size) {
            return font
        }
        return UIFont.boldSystemFont(ofSize: size)
    } ()
    
    static let ContentSmallFont: UIFont = {
        let size = CGFloat(12)
        var name = Constants.iOS8Font.Bold
        if #available(iOS 9.0, *) {
            name = Constants.Font.Bold
        }
        if let font = UIFont(name: name, size: size) {
            return font
        }
        return UIFont.boldSystemFont(ofSize: size)
    } ()

    var labelContent:UILabel?
    var smallContent:UILabel?
    
    override init(frame: CGRect){
        super.init(frame: frame)
        labelContent = UILabel()
        if let labelContent = self.labelContent{
            labelContent.textColor = UIColor.secondary4()
            labelContent.lineBreakMode = .byWordWrapping
            labelContent.numberOfLines = 0 //multi lines
            labelContent.sizeToFit()
            addSubview(labelContent)
        }
        
        smallContent = UILabel()
        if let smallContent = self.smallContent{
            smallContent.textColor = UIColor.secondary3()
            smallContent.lineBreakMode = .byWordWrapping
            smallContent.numberOfLines = 1
            smallContent.font = UIFont.systemFont(ofSize: 12)
            smallContent.isHidden = true
            addSubview(smallContent)
        }
    }
    
    func setText(_ text: String?, isUsingSmallFont: Bool){
        if let text = text{
            if let labelContent = self.labelContent{
                if isUsingSmallFont{
                    labelContent.font = ShipmentTextReusableView.ContentSmallFont
                }
                else{
                    labelContent.font = ShipmentTextReusableView.ContentFont
                }
                let stringHeight = CGFloat(text.stringHeightWithMaxWidth(frame.size.width - 2*ShipmentTextReusableView.PaddingLeftRight, font: labelContent.font))
                let frameLabel = CGRect(x: ShipmentTextReusableView.PaddingLeftRight, y: 0, width: frame.size.width - 2*ShipmentTextReusableView.PaddingLeftRight, height: stringHeight)
                labelContent.frame = frameLabel
                labelContent.text = text
                frame.size.height = labelContent.frame.size.height
            }
        }
        smallContent?.isHidden = true
    }

    func setSmallText(_ text: String?) {
        if let smallContent = self.smallContent {
            smallContent.isHidden = false
            let frameLabel = CGRect(x: ShipmentTextReusableView.PaddingLeftRight, y: labelContent?.frame.maxY ?? 0, width: frame.size.width - 2 * ShipmentTextReusableView.PaddingLeftRight, height: ShipmentTextReusableView.SmallTextHeight)
            smallContent.frame = frameLabel
            smallContent.text = text
            
            var height = CGFloat(0)
            if let labelContent = self.labelContent {
                height = labelContent.frame.size.height
            }
            frame.size.height = height + smallContent.frame.size.height
        }
    }
    
    func viewSize() -> CGSize{
        return frame.size
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
