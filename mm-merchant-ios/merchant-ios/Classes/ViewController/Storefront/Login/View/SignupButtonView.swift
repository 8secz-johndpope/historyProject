//
//  SignUpButtonView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class SignupButtonView : UIView{
    struct Padding{
        static let Width : CGFloat = 47
        static let Top : CGFloat = 14
    }
    struct Size{
        static let Height: CGFloat = 50
        static let Width : CGFloat = 50
        static let LabelHeight : CGFloat = 20
        static let LabelWidth :CGFloat = 85
    }
    
    var leftButton = UIButton()
    var rightButton = UIButton()
    var leftLabel = UILabel()
    var rightLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftButton)
        addSubview(rightButton)
        leftButton.setImage(UIImage(named: "wechat"), for: UIControlState())
        rightButton.setImage(UIImage(named: "mobile"), for: UIControlState())
        addSubview(leftLabel)
        addSubview(rightLabel)
        rightLabel.formatSize(14)
        leftLabel.formatSize(14)
        leftLabel.textColor = UIColor.secondary3()
        rightLabel.textColor = UIColor.secondary3()
        layout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout(){
        leftButton.frame = CGRect(x: bounds.midX - (Padding.Width / 2 + Size.Width), y: bounds.minY, width: Size.Width, height: Size.Height)
        rightButton.frame = CGRect(x: bounds.midX + Padding.Width / 2, y: bounds.minY, width: Size.Width, height:  Size.Height)
        leftLabel.frame = CGRect(x: leftButton.frame.minX, y: bounds.minY + Size.Height + Padding.Top, width: Size.LabelWidth, height: Size.LabelHeight)
        rightLabel.frame = CGRect(x: rightButton.frame.minX, y: bounds.minY + Size.Height + Padding.Top, width: Size.LabelWidth, height: Size.LabelHeight)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
