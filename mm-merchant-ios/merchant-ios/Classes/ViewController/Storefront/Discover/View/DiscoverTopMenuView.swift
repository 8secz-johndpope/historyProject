//
//  DiscoverTopMenuView.swift
//  merchant-ios
//
//  Created by Alan YU on 6/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class DiscoverTopMenuView: UIView {
    
    private final var underlineHeight = CGFloat(1)
    private final var underlineBottomPadding = CGFloat(5)
    var underline = UIView()
    private var button = UIButton()
    

    
    var titleLabel = UILabel()
    
    var selected: Bool {
        set {
            if newValue {
                titleLabel.textColor = UIColor.primary1()
                underline.isHidden = false
            } else {
                titleLabel.textColor = UIColor.secondary2()
                underline.isHidden = true
            }
        }
        
        get {
            return !underline.isHidden
        }
    }
    
    var touchUpClosure: UIButtonActionClosure? {
        didSet {
            button.touchUpClosure = { (button) in
                if let closure = self.touchUpClosure {
                    closure(button)
                }
            }
        }
    }
    
    init(frame: CGRect, title: String) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        titleLabel.formatSmall()
        titleLabel.textAlignment = .center
        //titleLabel.font = UIFont.boldsystemFont(ofSize: 14.0)
        titleLabel .text = title
        addSubview(titleLabel)
        
        underline.backgroundColor = UIColor.primary1()
        addSubview(underline)
        
        addSubview(button)
        
        self.selected = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = bounds
        titleLabel.frame = bounds
        underline.frame = CGRect(x: 0, y: bounds.maxY - underlineHeight - underlineBottomPadding, width: bounds.width, height: underlineHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
