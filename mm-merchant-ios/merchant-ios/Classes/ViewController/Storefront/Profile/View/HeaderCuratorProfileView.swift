//
//  HeaderCuratorProfileView.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class HeaderCuratorProfileView: HeaderMyProfileCell {
    
    var aboutButton : UIButton!
    
    var completionAboutHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let aboutButton = { () -> UIButton in
            let height = CGFloat(21)
            let widthImage = CGFloat(20)
            let marginright = CGFloat(16)
            
            let text = String.localize("LB_CA_PROFILE_ABOUT")
            let width = StringHelper.getTextWidth(text, height: height, font: UIFont.systemFont(ofSize: 12))
            let originY = self.labelUsername.origin.y + (HeighLabelUserName - height) / 2
            let button = UIButton(frame: CGRect(x: bounds.width - width - Margin.top * 2 - widthImage - marginright, y: originY, width: width + Margin.top * 2 + widthImage, height: height))
            button.setTitle(text, for: UIControlState())
            button.backgroundColor = UIColor.clear
            button.setTitleColor(UIColor.white, for: UIControlState())
            button.setImage(UIImage(named: "right_image_white"), for: UIControlState())
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: width + Margin.top + widthImage , bottom: 0, right: 0)
            button.titleLabel?.formatSize(12)
            button.addTarget(self, action: #selector(HeaderCuratorProfileView.gotoCuratorAboutPage), for: .touchUpInside)
            self.aboutButton = button
            return button
        }()
        
        actionView.addSubview(aboutButton)
        
    }
    
    override func setFrameLabelUserName() {
        var width = StringHelper.getTextWidth(labelUsername.text!, height: HeighLabelUserName, font: labelUsername.font)
        
        let originX = avatarViewContain.frame.maxX + Margin.left
        var maxWidth = self.bounds.sizeWidth - originX - QRCodeWidth - Margin.left
        if aboutButton != nil {
           maxWidth = maxWidth - aboutButton.frame.sizeWidth
        }
        if width > maxWidth {
            width = maxWidth
        }
        
        var originY = Margin.top
        if labelRealName.isHidden {
            originY = (buttonWhistlist.frame.minY - 2*HeighLabelUserName - 5) / 2.0 + 5
        }
        labelUsername.frame = CGRect(x: avatarViewContain.frame.maxX + Margin.left, y: originY, width: width, height: HeighLabelUserName)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let aboutButton = self.aboutButton {
            aboutButton.frame.originY = self.labelUsername.origin.y + 2
            aboutButton.frame.sizeHeight = self.labelUsername.frame.sizeHeight
            
            
            let originX = avatarViewContain.frame.maxX + Margin.left
            let width = aboutButton.frame.minX - originX
            tfAlias.frame = CGRect(x: originX, y: labelUsername.frame.minY, width: width, height: HeighLabelUserName)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func gotoCuratorAboutPage() {
        if let callback = completionAboutHandler {
            callback()
        }
    }
}
