//
//  AddCommentView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class AddCommentView: UIView {

    static let ViewHeight = CGFloat(50)
    var textField = UITextField()
    var shareButton = UIButton()
    var countLabel = UILabel()
    var heartButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        self.backgroundColor = UIColor.white
        
        shareButton.setImage(UIImage(named: "share"), for: UIControlState())
        self.addSubview(shareButton)
        
        textField.placeholder = String.localize("LB_CA_ALL_COMMENTS")
        textField.font = UIFont.fontWithSize(14, isBold: false)
        textField.backgroundColor = UIColor.init(hexString: "#F8F8F8")
        let paddingView : UIView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: (self.bounds.height - size.height) / 2))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.returnKeyType = .done
        self.addSubview(textField)
        
        countLabel.textAlignment = .center
        countLabel.numberOfLines = 1
        countLabel.text = "100"
        countLabel.font = UIFont.fontWithSize(14, isBold: false)
        self.addSubview(countLabel)
        
        heartButton.setImage(UIImage(named: "heart_red"), for: .selected)
        heartButton.setImage(UIImage(named: "heart_grey"), for: UIControlState())
        self.addSubview(heartButton)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginLeft: CGFloat = 10
        var size = CGSize(width: 50, height: self.bounds.sizeHeight)
        
        shareButton.frame = CGRect(x: self.bounds.sizeWidth - size.width, y: 0, width: size.width, height: size.height)
        
        let width = StringHelper.getTextWidth(countLabel.text ?? "", height: 20, font: countLabel.font)
        countLabel.frame = CGRect(x: shareButton.frame.minX - width - 8, y: 0, width: width, height: size.height)
        
        size = CGSize(width: 40, height: self.bounds.sizeHeight)
        
        heartButton.frame = CGRect(x: countLabel.frame.minX - size.width, y: 0, width: size.width, height: size.height)
        
        size = CGSize(width: heartButton.frame.minX - Margin.left, height: 30)
        textField.frame = CGRect(x: marginLeft , y: (self.bounds.height - size.height) / 2, width: size.width, height: size.height)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
