//
//  PostLikeViewCell.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/10/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

protocol PostLikeCellDelegate : class {
    func followUserClicked(_ likeObj: PostLike, isCurrentFollowing: Bool)
    
}

class PostLikeViewCell: UICollectionViewCell {
    private var imageView = UIImageView()
    private var diamondImageView = UIImageView()
    
    private var labelName = UILabel()
    private var buttonFollow = ButtonFollow()
    
    private var borderView = UIView()
    
    private final let MarginRight : CGFloat = 10
    private final let MarginLeft : CGFloat = 20
    private final let ImageWidth : CGFloat = 44
    private final let LabelLowerMarginBottom : CGFloat = 13
    private final let ImageDiamondWidth : CGFloat = 16
    
    weak var delegate : PostLikeCellDelegate?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        labelName.formatSmall()
        labelName.textColor = UIColor.secondary2()
        
        imageView.layer.borderWidth = 0.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.primary1().cgColor
        contentView.addSubview(imageView)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        contentView.addSubview(diamondImageView)
        contentView.addSubview(labelName)
        
        addSubview(buttonFollow)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        buttonFollow.addTarget(self, action: #selector(PostLikeViewCell.clickedFollowButton), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        buttonFollow.frame = CGRect(x: bounds.maxX - MarginLeft - ButtonFollow.ButtonFollowSize.width, y: bounds.midY - ButtonFollow.ButtonFollowSize.height / 2, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        labelName.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: 0 , width: bounds.width - (imageView.frame.maxX + MarginRight + MarginRight + ButtonFollow.ButtonFollowSize.width + MarginLeft) , height: bounds.height ) //fix bug overlap with follow/unfollow button
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }
    
    func setupData(_ likeObj : PostLike, isFollowingUser : Bool = false) {
        labelName.text = likeObj.displayName
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(likeObj.profileImageKey , category: .user), placeholderImage : UIImage(named: "default_profile_icon"))
        imageView.contentMode = .scaleAspectFill
        diamondImageView.isHidden = !likeObj.isCurator
        imageView.layer.borderWidth = likeObj.isCurator ? 1.0 : 0.0
        buttonFollow.setFollowButtonState(isFollowingUser)
        buttonFollow.isHidden = likeObj.userKey == Context.getUserKey()
        self.likeObj = likeObj
        self.isFollowingUser = isFollowingUser
    }
    
    private var likeObj : PostLike?
    private var isFollowingUser : Bool = false
    
    @objc func clickedFollowButton() {
        if let delegate = delegate, let like = likeObj {
            delegate.followUserClicked(like, isCurrentFollowing: isFollowingUser)
        }
    }
}
