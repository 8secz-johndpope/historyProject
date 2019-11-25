//
//  LoginBar.swift
//  merchant-ios
//
//  Created by LongTa on 8/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class LoginBar: UIView {

    private var viewLogin = UIView()
    private final let ButtonHeight : CGFloat = 46
//    private var viewLoginOverlay = UIView()
    var buttonLogin = UIButton()
    private var seperator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewLogin.backgroundColor = UIColor.clear
        buttonLogin.titleLabel?.formatSmall()
        buttonLogin.setTitleColor(UIColor.secondary2(), for: UIControlState())
        let buttonLoginTitle = String.localize("LB_CA_GUEST_LOGIN")
        buttonLogin.setTitle(buttonLoginTitle, for: UIControlState())
        viewLogin.addSubview(buttonLogin)
        seperator.backgroundColor = UIColor.secondary1()
        viewLogin.addSubview(seperator)
        self.addSubview(viewLogin)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var frame = self.frame
        frame.originY = frame.sizeHeight - ButtonHeight
        self.frame = frame
        
        self.viewLogin.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: ButtonHeight)
        self.buttonLogin.frame = self.viewLogin.bounds
        self.seperator.frame = CGRect(x: 0, y: 0, width: self.viewLogin.frame.sizeWidth, height: 1.0)
    }
}
