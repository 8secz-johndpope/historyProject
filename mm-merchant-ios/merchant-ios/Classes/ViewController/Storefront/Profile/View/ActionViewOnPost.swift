//
//  ActionViewOnPost.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ActionViewOnPost: UIView {
    
    private final let SwipeViewHeight: CGFloat = 66
    private final let iconButtonSize = CGSize(width: 30, height: 30)

    var price = ""
    
    var buttonShare = UIButton()
    var likeCountLabel = UILabel()
    var commentCountLabel = UILabel()
    
    var buttonComment = UIButton()
    
    var buttonLike = UIButton()
    
    convenience init(price: String) {
        self.init(frame: CGRect.zero)
        self.frame = CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: ViewDefaultHeight.HeightActionView)
     
        layoutSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        buttonShare.setImage(UIImage(named: "share_post"), for: UIControlState())
        buttonShare.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        self.addSubview(buttonShare)

        buttonComment.setImage(UIImage(named: "comment_post"), for: UIControlState())
        buttonComment.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        self.addSubview(buttonComment)
        
        buttonLike.setImage(UIImage(named: "heart_grey_post"), for: UIControlState())
        buttonLike.setImage(UIImage(named: "heart_red_post"), for: .selected)
        buttonLike.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        self.addSubview(buttonLike)
        
        
        likeCountLabel.applyFontSize(14, isBold: false)
        likeCountLabel.textColor = UIColor.secondary2()
        self.addSubview(likeCountLabel)
        
        
        commentCountLabel.applyFontSize(14, isBold: false)
        commentCountLabel.textColor = UIColor.secondary2()
        self.addSubview(commentCountLabel)
        
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonLike.frame = CGRect(x: Margin.left / 2, y: (self.bounds.height - iconButtonSize.height) / 2, width: iconButtonSize.width, height: iconButtonSize.height)
        let labelHeight = CGFloat(20)
        var width = CGFloat(34)
        
        likeCountLabel.frame = CGRect(x: buttonLike.frame.maxX , y: (self.bounds.height - labelHeight) / 2 , width: width, height: labelHeight)
        
        
        buttonComment.frame = CGRect(x: likeCountLabel.frame.maxX , y: (self.bounds.height - iconButtonSize.height) / 2, width: iconButtonSize.width, height: iconButtonSize.height)
        
        
        width = StringHelper.getTextWidth(self.commentCountLabel.text ?? "", height: labelHeight, font: commentCountLabel.font)
        commentCountLabel.frame = CGRect(x: buttonComment.frame.maxX , y: (self.bounds.height - labelHeight) / 2, width: width, height: labelHeight)
        
        
        buttonShare.frame = CGRect(x: self.bounds.sizeWidth - Margin.left / 2  - iconButtonSize.width, y: (self.bounds.height - iconButtonSize.height) / 2, width: iconButtonSize.width, height: iconButtonSize.height)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
