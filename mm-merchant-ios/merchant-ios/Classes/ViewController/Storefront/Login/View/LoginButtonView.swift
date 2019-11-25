//
//  LoginButtonView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 28/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class LoginButtonView : UIView {
    
    struct ButtonSize{
        static let width : CGFloat = 151
        static let height : CGFloat = 26
    }
    
    var upperButton = UIButton()
    var lowerButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        upperButton.formatTransparent()
        upperButton.setTitle(String.localize("LB_CA_LOGIN"), for: UIControlState())
        addSubview(upperButton)
        lowerButton.formatTransparent()
        lowerButton.setTitle(String.localize("LB_CA_GUEST_LOGIN"), for: UIControlState())
        lowerButton.accessibilityIdentifier = "guest_login_button"
        addSubview(lowerButton)
        layoutButtons()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutButtons()
    }
    
    func layoutButtons(){
        lowerButton.frame = CGRect(x: bounds.midX - ButtonSize.width / 2, y: bounds.maxY - ButtonSize.height, width: ButtonSize.width, height: ButtonSize.height)
        upperButton.frame = CGRect(x: bounds.midX - ButtonSize.width / 2, y: bounds.minY, width: ButtonSize.width, height: ButtonSize.height)
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
