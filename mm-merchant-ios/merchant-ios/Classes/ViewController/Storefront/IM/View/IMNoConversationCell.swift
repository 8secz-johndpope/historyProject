//
//  IMNoConversationCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol IMNoConversationCellDelegate: NSObjectProtocol {
    func didSelectAddFriendButton(_ sender: UIButton)
}

class IMNoConversationCell: UICollectionViewCell {
    
    var imageView : UIImageView!
    var label: UILabel!
    
    var buttonAddFriend: UIButton!
    var imageAddFriend: UIImageView!
    
    private let viewContainer = UIView()

    weak var delegate: IMNoConversationCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(viewContainer)
        
        imageView = UIImageView(image: UIImage(named:"im_chatlist"))
        viewContainer.addSubview(imageView)
		
		label = UILabel()
		label.textAlignment = .center
		label.formatSize(16)
		label.textColor = UIColor.secondary3()
		label.text = String.localize("LB_CA_CS_NOMSG")
		viewContainer.addSubview(label)
        
        buttonAddFriend = UIButton(type: .custom)
        buttonAddFriend.layer.borderColor = UIColor.primary1().cgColor
        buttonAddFriend.layer.borderWidth = 1
        buttonAddFriend.layer.cornerRadius = 5.0
        buttonAddFriend.titleLabel?.formatSize(16)
        buttonAddFriend.setTitleColor(UIColor.primary1(), for: UIControlState())
        buttonAddFriend.setTitle(String.localize("LB_CA_IM_FIND_USER_ADD"), for: UIControlState())
        buttonAddFriend.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        buttonAddFriend.addTarget(self, action: #selector(self.buttonAddFriendTouched), for: .touchUpInside)
        viewContainer.addSubview(buttonAddFriend)
        
        let imageAddFriendWidth = CGFloat(25)
        let imageAddFriendHeight = CGFloat(25)

        imageAddFriend = UIImageView(frame:CGRect(x: 0, y: 0, width: imageAddFriendWidth, height: imageAddFriendHeight))
        imageAddFriend.image = UIImage(named:"addFriend_icon_red")
        buttonAddFriend.addSubview(imageAddFriend)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin = CGFloat(10)
        let labelHeight = CGFloat(20)
        
        let imageViewHeight = CGFloat(72)
        let imageViewWidth = CGFloat(90)

        if buttonAddFriend.isHidden {
            let height = labelHeight + imageViewHeight + margin
            viewContainer.frame = CGRect(x: 0, y: (contentView.frame.height - height) / 2, width: contentView.width, height: height)
            
            imageView.frame = CGRect(x: (viewContainer.width - imageViewWidth) / 2, y: 0, width: imageViewWidth, height: imageViewHeight)
            label.frame = CGRect(x: 0, y: imageView.frame.maxY + margin, width: contentView.width, height: labelHeight)
        }
        else {
            let buttonAddFriendHeight = CGFloat(40)
            let buttonAddFriendWidth = CGFloat(110)
            
            let height = labelHeight + imageViewHeight + buttonAddFriendHeight + 2 * margin
            viewContainer.frame = CGRect(x: 0, y: (contentView.frame.height - height) / 2, width: contentView.width, height: height)

            imageView.frame = CGRect(x: (viewContainer.width - imageViewWidth) / 2, y: 0, width: imageViewWidth, height: imageViewHeight)
            label.frame = CGRect(x: 0, y: imageView.frame.maxY + margin, width: contentView.width, height: labelHeight)

            buttonAddFriend.frame = CGRect(x: (viewContainer.width - buttonAddFriendWidth) / 2, y: label.frame.maxY + margin, width: buttonAddFriendWidth, height: buttonAddFriendHeight)
            imageAddFriend.frame = CGRect(x: 5, y: (buttonAddFriendHeight - imageAddFriend.height) / 2 , width: imageAddFriend.width, height: imageAddFriend.height)
        }
    }
	
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonAddFriendTouched (_ sender: UIButton) {
        self.delegate?.didSelectAddFriendButton(sender)
    }
}
