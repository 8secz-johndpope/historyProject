//
//  NoCollectionItemCell.swift
//  merchant-ios
//
//  Created by Markus Chow on 8/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

protocol NoCollectionItemCellDelegate: NSObjectProtocol {
    func didSelectAddFriendButton(_ sender: UIButton)
}

class NoCollectionItemCell: UICollectionViewCell {
	
    private final let buttonAddFriendWidth = CGFloat(110)
    private final let buttonAddFriendHeight = CGFloat(40)
    private final let imageAddFriendWidth = CGFloat(25)
    private final let imageAddFriendHeight = CGFloat(25)
    
	var imageView = UIImageView()
	var label = UILabel()
	
    var buttonAddFriend = UIButton(type: .custom)
    var imageAddFriend = UIImageView()
    
    weak var delegate: NoCollectionItemCellDelegate?
    
	override init(frame: CGRect) {
		super.init(frame: frame)
		
        if let image = UIImage(named:"icon_wishlist_default") {
            imageView.image = image
        }
        
        contentView.addSubview(imageView)
		label.textAlignment = .center
		label.formatSize(16)
		label.textColor = UIColor.secondary3()
		label.text =  ""
        
		contentView.addSubview(label)
        
        createAddFriendButton()
        setAddFriendButtonHidden(true)
	}
	
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let image = imageView.image {
            let imageViewWidth = image.size.width
            let imageViewHeight = width * (image.size.height / width)
            imageView.frame = CGRect(x: (frame.width - imageViewWidth)/2, y: (frame.height - imageViewHeight) / 2 , width: imageViewWidth, height: imageViewHeight)
        }
        
        let labelHeight = CGFloat(20)
        label.frame = CGRect(x: 0, y: imageView.frame.maxY + 10, width: frame.width, height: labelHeight)
    }
    
    private func createAddFriendButton() {
        
        buttonAddFriend.frame = CGRect(x: (frame.width - buttonAddFriendWidth)/2, y: label.frame.maxY + 10, width: buttonAddFriendWidth, height: buttonAddFriendHeight)
        buttonAddFriend.layer.borderColor = UIColor.primary1().cgColor
        buttonAddFriend.layer.borderWidth = 1
        buttonAddFriend.layer.cornerRadius = 5.0
        buttonAddFriend.titleLabel?.formatSize(16)
        buttonAddFriend.setTitleColor(UIColor.primary1(), for: UIControlState())
        buttonAddFriend.setTitle(String.localize("LB_CA_IM_FIND_USER_ADD"), for: UIControlState())
        buttonAddFriend.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        buttonAddFriend.addTarget(self, action: #selector(self.buttonAddFriendTouched), for: .touchUpInside)
        contentView.addSubview(buttonAddFriend)
        
        imageAddFriend.frame = CGRect(x: 5, y: (buttonAddFriendHeight - imageAddFriendHeight)/2 , width: imageAddFriendWidth, height: imageAddFriendHeight)
        imageAddFriend.image = UIImage(named:"addFriend_icon_red")
        buttonAddFriend.addSubview(imageAddFriend)
    }
    
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
    
    @objc func buttonAddFriendTouched (_ sender: UIButton) {
        self.delegate?.didSelectAddFriendButton(sender)
    }
    
    func setAddFriendButtonHidden(_ isHidden: Bool) {
        if isHidden {
            imageView.frame.originY = (frame.height - imageView.frame.sizeHeight) / 2
            label.frame.originY = imageView.frame.maxY + 10
            buttonAddFriend.frame.originY = label.frame.maxY + 10
            buttonAddFriend.isHidden = true
        } else {
            imageView.frame.originY = (frame.height - imageView.frame.sizeHeight) / 3
            label.frame.originY = imageView.frame.maxY + 10
            buttonAddFriend.frame.originY = label.frame.maxY + 10
            buttonAddFriend.isHidden = false
        }
    }
}
