//
//  FriendMenuViewCell.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class FriendMenuViewCell: UICollectionViewCell {
    var imageView = UIImageView()
    var textLabel = UILabel()
    var lowerLabel = UILabel()
    var borderView = UIView()
    var upperBorderView = UIView()
    var borderReferralView = UIView()
    var upperReferralView = UIView()
    var incentiveLabel = UILabel()
    var incentiveFlagLabel = UILabel()
    var viewReferralContain = UIView()
    
    
    private final let MarginRight : CGFloat = 20
    private final let MarginLeft : CGFloat = 10
    private final let LabelMarginTop : CGFloat = 11
    private final let LabelMarginRight : CGFloat = 30
    final var ImageWidth : CGFloat = 30
    private final let LabelRightWidth : CGFloat = 100
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let ViewMargintop : CGFloat = 9
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        textLabel.formatSize(15)
        addSubview(textLabel)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        upperBorderView.backgroundColor = UIColor.secondary1()
        addSubview(upperBorderView)
        
        textLabel.textColor = UIColor.secondary2()
        lowerLabel.textColor = UIColor.secondary3()
        lowerLabel.font = UIFont(name: lowerLabel.font.fontName, size: 11)
        lowerLabel.lineBreakMode = .byWordWrapping
        lowerLabel.numberOfLines = 0
        addSubview(lowerLabel)

        textLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 15)
        
        upperReferralView.backgroundColor = UIColor.primary1()
        viewReferralContain.addSubview(upperReferralView)
        borderReferralView.backgroundColor = UIColor.primary1()
        viewReferralContain.addSubview(borderReferralView)
        incentiveLabel.text = String.localize("LB_CA_INCENTIVE_REFERRAL")
        incentiveLabel.textColor = UIColor.primary1()
        incentiveLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 15)
        incentiveLabel.textAlignment = .justified
        viewReferralContain.addSubview(incentiveLabel)
        incentiveFlagLabel.text = String.localize("LB_CA_INCENTIVE_REF_FLAG_CAPTION").replacingOccurrences(of: "{0}", with: "200") //Hardcode because API not support yet.
        incentiveFlagLabel.textColor = UIColor.primary1()
        incentiveFlagLabel.font = UIFont(name:lowerLabel.font.fontName, size: 11)
        incentiveFlagLabel.textAlignment = .justified
        viewReferralContain.addSubview(incentiveFlagLabel)

        addSubview(viewReferralContain)
        
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 0.5, width: bounds.width, height: 0.5)
        upperBorderView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 0.5)
        
        if lowerLabel.text != nil && lowerLabel.text?.length > 0 {
            textLabel.frame = CGRect(x: imageView.frame.maxX + MarginLeft, y: bounds.minY + LabelMarginTop, width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height: bounds.height/3 )
            lowerLabel.frame = CGRect(x: imageView.frame.maxX + MarginLeft, y: bounds.midY + 3 , width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height:bounds.height/3 )
        }else {
            textLabel.frame = CGRect(x: imageView.frame.maxX + MarginLeft, y: bounds.midY - bounds.height / 6, width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height: bounds.height/3 )
        }
        
        viewReferralContain.frame = CGRect(x: frame.sizeWidth - LabelRightWidth - MarginRight, y: bounds.minY, width: LabelRightWidth, height: bounds.height)
        
        borderReferralView.frame = CGRect(x: bounds.minX, y: bounds.minY + ViewMargintop, width: LabelRightWidth, height: 1)
        incentiveLabel.frame = CGRect(x: bounds.minX, y: bounds.minY + LabelMarginTop, width: LabelRightWidth, height: viewReferralContain.height/3)
        incentiveFlagLabel.frame = CGRect(x: bounds.minX, y: bounds.midY + 3, width: LabelRightWidth, height: viewReferralContain.height/3)
        upperReferralView.frame = CGRect(x: bounds.minX, y: bounds.maxY - ViewMargintop, width: LabelRightWidth, height: 1)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
