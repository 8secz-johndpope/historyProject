//
//  GroupChatNameCell.swift
//  merchant-ios
//
//  Created by HungPM on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class GroupChatNameCell: UICollectionViewCell {
    
    var lblGroupName: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let separatorViewTop = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
            view.backgroundColor = UIColor.secondary1()
            
            return view
        } ()
        contentView.addSubview(separatorViewTop)

        let MarginLeft = CGFloat(15)
        let PaddingMargin = CGFloat(17)

        let lblGroupChatName = UILabel(frame: CGRect(x: MarginLeft, y: 0, width: 80, height: frame.height))
        lblGroupChatName.formatSize(13)
        lblGroupChatName.text = String.localize("LB_IM_CHAT_GROUP_NAME")
        contentView.addSubview(lblGroupChatName)
        
        let ArrowWidth = CGFloat(32)
        let arrowImageView = UIImageView(frame: CGRect(x: self.frame.width - ArrowWidth - PaddingMargin, y: (self.frame.height - ArrowWidth) / 2, width: ArrowWidth, height: ArrowWidth))
        arrowImageView.image = UIImage(named: "icon_arrow_small")
        arrowImageView.contentMode = .scaleAspectFit
        contentView.addSubview(arrowImageView)
        
        lblGroupName = UILabel(frame: CGRect(x: lblGroupChatName.frame.maxX, y: 0, width: arrowImageView.frame.minX - lblGroupChatName.frame.maxX - 5, height: frame.height))
        lblGroupName.font = UIFont.systemFont(ofSize: 13)
        lblGroupName.textColor = UIColor.secondary2()
        lblGroupName.textAlignment = .right
        contentView.addSubview(lblGroupName)
        
        let separatorViewBottom = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1))
            view.backgroundColor = UIColor.secondary1()
            
            return view
        } ()
        contentView.addSubview(separatorViewBottom)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
