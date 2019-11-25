//
//  CheckoutFooterView.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CheckoutFooterView: UICollectionReusableView {
    
    enum SeparatorStyle: Int {
        case none = 0
        case full
        case singleItem
        case multipleItem
    }
    
    static let ViewIdentifier = "CheckoutFooterViewID"
    
    var separatorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        separatorView.backgroundColor = UIColor.clear
        addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSeparatorStyle(_ separatorStyle: SeparatorStyle, withColor color: UIColor = UIColor.backgroundGray()) {
        var marginLeft: CGFloat = 0
        var marginRight: CGFloat = 0
        
        separatorView.backgroundColor = color
        
        switch separatorStyle {
        case .none:
            separatorView.isHidden = true
        case .full:
            separatorView.isHidden = false
        case .singleItem:
            marginLeft = Margin.left
            marginRight = Margin.left
            separatorView.isHidden = false
        case .multipleItem:
            marginLeft = FCheckoutViewController.MultipleMerchantSizeEdgeInsets.left
            marginRight = Margin.left
            separatorView.isHidden = false
        }
        
        separatorView.frame = CGRect(x: marginLeft, y: frame.height - 1, width: frame.width - marginLeft - marginRight, height: Constants.Separator.DefaultThickness)
        
        layoutSubviews()
    }
}
