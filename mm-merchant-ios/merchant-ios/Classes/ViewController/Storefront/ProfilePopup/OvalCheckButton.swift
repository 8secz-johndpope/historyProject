//
//  OvalCheckButton.swift
//  merchant-ios
//
//  Created by LongTa on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class OvalCheckButton: UIView {

    static let ovalSize = CGSize(width: 50, height: 50)
    static let stickSize = CGSize(width: 17, height: 17)
    
    let ovalUnCheckImageName = "Oval_Img"
    let ovalCheckImageName = "Oval_Img_Selected"
    
    let ovalStickImageName = "Group_Check_Icon"
    
    let imageViewOval = UIImageView()
    
    let imageViewStick = UIImageView()
    
    let labelOval = UILabel()

    let label = UILabel()
    static let labelHeight:CGFloat = 20
    static let labelPaddingTop:CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageViewOval.image = UIImage(named: ovalCheckImageName)
        addSubview(imageViewOval)

        labelOval.text = "1"
        labelOval.formatSizeBold(18)
        labelOval.textColor = UIColor.secondary1()
        labelOval.textAlignment = .center
        addSubview(labelOval)
        
        imageViewStick.image = UIImage(named: ovalStickImageName)
        addSubview(imageViewStick)
        
        label.formatSmall()
        label.textAlignment = .center
        addSubview(label)
        
        setChecked(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    func setupLayouts() {
        
        imageViewOval.frame = CGRect(x: 0, y: OvalCheckButton.stickSize.height/3, width: OvalCheckButton.ovalSize.width, height: OvalCheckButton.ovalSize.height)
        
        labelOval.frame = imageViewOval.frame

        imageViewStick.frame = CGRect(x: imageViewOval.frame.sizeWidth*2/3, y: 0, width: OvalCheckButton.stickSize.width, height: OvalCheckButton.stickSize.height)

        if let text = label.text{
            let textWidth = StringHelper.getTextWidth(text, height: OvalCheckButton.labelHeight, font: label.font)
            label.frame = CGRect(x: (frame.sizeWidth - textWidth)/2, y: imageViewOval.frame.maxY + OvalCheckButton.labelPaddingTop, width: textWidth, height: OvalCheckButton.labelHeight)
        }
    }
    
    class func defaultHeight() -> CGFloat{
        return OvalCheckButton.stickSize.height/2 + OvalCheckButton.ovalSize.height + OvalCheckButton.labelPaddingTop + OvalCheckButton.labelHeight
    }
    
    func setChecked(_ isChecked: Bool){
        imageViewStick.isHidden = !isChecked
        if isChecked{
            imageViewOval.image = UIImage(named: ovalCheckImageName)
            labelOval.textColor = UIColor.primary1()
        }
        else{
            imageViewOval.image = UIImage(named: ovalUnCheckImageName)
            labelOval.textColor = UIColor.secondary1()
        }
    }
}
