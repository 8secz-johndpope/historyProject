//
//  GroupChatHeaderView.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class GroupChatHeaderView: UICollectionReusableView {
    
    var label : UILabel!
    var addButton : UIButton!
    var addButtonTappedHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        let labelPadding = CGFloat(15)
        label = UILabel(frame: CGRect(x: labelPadding, y: 0, width: frame.size.width - labelPadding, height: frame.size.height))
        label.formatSize(13)
        label.textColor = UIColor.secondary2()
        addSubview(label)
        
        let buttonPadding = CGFloat(10)
        let buttonWidth = frame.size.height
        addButton = UIButton(type: .custom)
        addButton.setImage(UIImage(named:"add_icon"), for: UIControlState())
        addButton.frame =  CGRect(x: frame.size.width - buttonWidth -  buttonPadding, y: (frame.size.height - buttonWidth)/2, width: buttonWidth, height: buttonWidth)
        addButton.addTarget(self, action: #selector(GroupChatHeaderView.addButtonTapped), for: .touchUpInside)
        addSubview(addButton)
        
        let separator = UIView(frame: CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 1))
        separator.backgroundColor = UIColor.secondary1()
        addSubview(separator)
    }
    
    @objc func addButtonTapped(_ button: UIButton) {
        if let callback = self.addButtonTappedHandler {
            callback()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
