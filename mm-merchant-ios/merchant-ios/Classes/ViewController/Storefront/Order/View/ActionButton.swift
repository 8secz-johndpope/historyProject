//
//  ActionButton.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 28/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ActionButton: UIButton {
    
    enum TitleStyle: Int {
        case normal = 0
        case highlighted
        case unpaid
    }
    
    init(frame: CGRect, titleStyle: TitleStyle = .normal) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = Constants.ActionButton.Radius
        self.layer.borderWidth = Constants.ActionButton.BorderWidth
        self.layer.borderColor = UIColor.secondary3().cgColor
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
        self.backgroundColor = UIColor.white
        
        switch titleStyle {
        case .normal:
            self.setTitleColor(UIColor.secondary2(), for: UIControlState())
        case .highlighted:
            self.setTitleColor(UIColor.primary1(), for: UIControlState())
        case .unpaid:
            self.backgroundColor = UIColor.primary1()
            self.layer.borderColor = UIColor.primary1().cgColor
            self.setTitleColor(UIColor.white, for: UIControlState())
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let tapEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: -15, right: 0)
        let tapFrame = UIEdgeInsetsInsetRect(self.bounds, tapEdgeInsets)
        return tapFrame.contains(point)
    }
    
    func updateStyle(_ titleStyle: TitleStyle = .normal){
        switch titleStyle {
        case .normal:
            self.setTitleColor(UIColor.secondary2(), for: UIControlState())
        case .highlighted:
            self.setTitleColor(UIColor.primary1(), for: UIControlState())
        case .unpaid:
            self.backgroundColor = UIColor.primary1()
            self.layer.borderColor = UIColor.primary1().cgColor
            self.setTitleColor(UIColor.white, for: UIControlState())
        }
    }
    
    
    
}
