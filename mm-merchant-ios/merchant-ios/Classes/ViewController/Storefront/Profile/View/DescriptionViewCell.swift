//
//  DescriptionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class DescriptionViewCell: UICollectionViewCell {
    static let MarginLeft : CGFloat = 16.0
    static let LabelNameHeight : CGFloat = 22.0
    static let MarginBottom : CGFloat = 4.0
    static let MarginTop : CGFloat = 8.0
    
    var textLabel = UILabel()
    var labelName = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        //let bounds = CGRect(x:16, y: 0, width: CGRectGetMaxX(frame), height: CGRectGetMaxY(frame))
        //let label = UILabel(frame: bounds)
       //textLabel.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        if let fontBold = UIFont(name: Constants.Font.Normal, size: 14) {
            textLabel.font = fontBold
        } else {
            textLabel.formatSizeBold(14)
        }
        
        textLabel.textColor = UIColor.black
        textLabel.numberOfLines = 0
        //self.textLabel = label
        self.addSubview(textLabel)
        
        labelName.applyFontSize(15, isBold: true)
        labelName.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        labelName.textColor = UIColor.black
        self.addSubview(labelName)
		
		//layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.labelName.frame = CGRect(x: DescriptionViewCell.MarginLeft, y: DescriptionViewCell.MarginTop, width: self.bounds.width - DescriptionViewCell.MarginLeft * 2, height: DescriptionViewCell.LabelNameHeight)
		
        let height = self.bounds.sizeHeight - DescriptionViewCell.MarginBottom - labelName.frame.maxY - DescriptionViewCell.MarginBottom
		
		self.textLabel.frame = CGRect(x: DescriptionViewCell.MarginLeft, y: self.labelName.frame.maxY + DescriptionViewCell.MarginBottom, width: self.bounds.width - DescriptionViewCell.MarginLeft * 2, height: height)
		
    }
    func setUpData(_ merchant: Merchant){
        self.labelName.text = merchant.merchantName
        self.textLabel.text = merchant.merchantDesc
		
		layoutSubviews()
    }
	func setUpData(_ brand: Brand){
		self.labelName.text = brand.brandName
		self.textLabel.text = brand.brandDesc
		
		layoutSubviews()
	}
	func setUpData(_ user: User){
		// curator's description
        self.labelName.text = String.localize("LB_CA_PROFILE_ABOUT") + " " + user.displayName
		if  user.userDescription.trim().length != 0{
            let descriptionText : String = user.userDescription
			self.textLabel.text = descriptionText
		}
        else{
            self.textLabel.text = String.localize("LB_CA_CURATOR_PROF_DESC_NIL")
        }
        layoutSubviews()
    }
	
//	func getTextHeight(text: String, width: CGFloat, font: UIFont) -> CGFloat {
//		let constraintRect = CGSize(width: width, height: CGFloat.max)
//		let boundingBox = text.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
//		return boundingBox.height
//	}
}
