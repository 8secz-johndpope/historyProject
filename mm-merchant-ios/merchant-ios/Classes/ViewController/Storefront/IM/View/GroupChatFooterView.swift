//
//  GroupChatFooterView.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class GroupChatFooterView: UICollectionReusableView {
    
    var seeMoreSelected = false
    
    var seeMoreButton : UIButton!
    var seeMoreButtonTappedHandler: (() -> Void)?
    var arrowImageView : UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame:frame)
    
        let buttonWidth = CGFloat(100)
        let buttonHeight = CGFloat(44)
        let arrowWidth = CGFloat(13)
        let arrowHeight = CGFloat(13)
        
        if frame.height > 1 {
            seeMoreButton = UIButton(type: .custom)
            seeMoreButton.formatSecondaryNonBorder()
            seeMoreButton.setTitle(String.localize("LB_IM_CHAT_USER_MORE"), for: UIControlState())
            seeMoreButton.frame =  CGRect(x: (frame.size.width - buttonWidth)/2, y: 0, width: buttonWidth, height: buttonHeight)
            seeMoreButton.addTarget(self, action: #selector(GroupChatFooterView.seeMoreButtonTapped), for: .touchUpInside)
            addSubview(seeMoreButton)
            
            arrowImageView  =  UIImageView(frame: CGRect(x: (frame.size.width - arrowWidth)/2, y: seeMoreButton.frame.maxY - 8, width: arrowWidth, height: arrowHeight))
            arrowImageView.image = UIImage(named:"arrow_close")
            arrowImageView.contentMode = .scaleAspectFit
            addSubview(arrowImageView)
        }
        
        let separator = UIView(frame: CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 1))
        separator.backgroundColor = UIColor.secondary1()
        addSubview(separator)
    }
    
    @objc func seeMoreButtonTapped(_ button: UIButton) {
        
        seeMoreSelected = !seeMoreSelected
        if seeMoreSelected {
            seeMoreButton.setTitle("", for: UIControlState())
            arrowImageView.image = UIImage(named:"arrow_open")
        } else {
            seeMoreButton.setTitle(String.localize("LB_IM_CHAT_USER_MORE"), for: UIControlState())
            arrowImageView.image = UIImage(named:"arrow_close")
        }
        
        if let callback = self.seeMoreButtonTappedHandler {
            callback()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
