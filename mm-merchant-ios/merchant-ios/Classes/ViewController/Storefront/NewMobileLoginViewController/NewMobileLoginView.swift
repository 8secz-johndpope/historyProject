//
//  NewMobileLoginView.swift
//  merchant-ios
//
//  Created by LongTa on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class NewMobileLoginView: MobileLoginView {
    
    let buttonPaddingTop = CGFloat(15)
    let buttonHeight = CGFloat(42)

    let cornerButtonHeight = CGFloat(23)
    let cornerButtonTopPadding = CGFloat(10)
    
    let labelOr = UILabel()
    let labelOrPaddingTop = CGFloat(5)
    let labelOrHeight = CGFloat(23)

    let seperatorView = UIView()
    let seperatorViewWidth = CGFloat(40)
    let seperatorViewHeight = CGFloat(1)

    

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        button.formatDisable(UIColor.white)
        seperatorView.backgroundColor = UIColor.secondary1()
        addSubview(seperatorView)
        
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout(_ isTall: Bool){
        super.layout(isTall)
        
        var frameButton = button.frame
        frameButton.origin.y = imageView.frame.maxY + buttonPaddingTop
        frameButton.sizeHeight = buttonHeight
        button.frame = frameButton
        
        var cornerButtonFrame = cornerButton.frame
        var buttonContentWidth:CGFloat = 0
        if let titleOfCornerButton = cornerButton.currentTitle, let font = cornerButton.titleLabel?.font{
            buttonContentWidth = StringHelper.getTextWidth(titleOfCornerButton, height: cornerButtonFrame.sizeHeight, font: font)
        }
        cornerButtonFrame.sizeWidth = buttonContentWidth
        cornerButtonFrame.origin.x = button.frame.maxX - cornerButtonFrame.sizeWidth
        cornerButtonFrame.originY = button.frame.maxY + cornerButtonTopPadding
        cornerButtonFrame.size.height = cornerButtonHeight
        cornerButton.frame = cornerButtonFrame
        
        let labelOrWidth = labelOr.optimumWidth()
        labelOr.frame = CGRect(x: (self.frame.sizeWidth - labelOrWidth)/2, y: cornerButton.frame.maxY + labelOrPaddingTop, width: labelOrWidth, height: labelOrHeight)
        
        let seperatorViewWidthTwoSide = labelOrWidth + 2*seperatorViewWidth
        seperatorView.frame = CGRect(x: (self.frame.sizeWidth - seperatorViewWidthTwoSide)/2, y: labelOr.frame.midY, width: seperatorViewWidthTwoSide, height: seperatorViewHeight)
        
    }
}
