//
//  FollowingUserViewCell
//  merchant-ios
//
//  Created by Trung Vu on 3/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


@objc
protocol FollowingUserViewCellDelegate: NSObjectProtocol {
    @objc func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow)
}
class FollowingUserViewCell : UICollectionViewCell{
    
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var borderView = UIView()
    var lowerLabel = UILabel()
    var bottomLabel = UILabel()
    var followButton = ButtonFollow()
    
    private final let MarginRight : CGFloat = 20
    private final let MarginLeft : CGFloat = 15
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let ImageWidth : CGFloat = 44
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 63
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let ButtonWidth : CGFloat = 64
    private final let ChatButtonWidth : CGFloat = 30
    private final let ImageIconFollow: CGFloat = 20
    private final let space:CGFloat = 8.0
    
    var IsFollow: Bool = true
    weak var delegateFollowingUserList: FollowingUserViewCellDelegate?
    var user = User()
    var profileType : TypeProfile?
    
    var diamondImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        imageView.layer.borderWidth = 1.0
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.primary1().cgColor
        imageView.layer.cornerRadius = ImageWidth / 2
        addSubview(imageView)
        
        upperLabel.font = UIFont.usernameFont()
        upperLabel.text = ""
        upperLabel.textColor = .black
        upperLabel.numberOfLines = 1
        upperLabel.lineBreakMode = .byTruncatingTail
        addSubview(upperLabel)
        
        
        bottomLabel.text = ""
        bottomLabel.formatSize(12)
        bottomLabel.textColor = UIColor.secondary3()
        addSubview(bottomLabel)
        
        followButton.addTarget(self, action: #selector(FollowingUserViewCell.onFollowHandle), for: UIControlEvents.touchUpInside)
        addSubview(followButton)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        diamondImageView.image = UIImage(named: "curator_diamond")
        addSubview(diamondImageView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        followButton.frame = CGRect(x: frame.sizeWidth - ButtonFollow.ButtonFollowSize.width - MarginRight, y: (bounds.height - ButtonFollow.ButtonFollowSize.height)/2, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: bounds.minY + LabelMarginTop, width: bounds.width - (imageView.frame.maxX + MarginRight + (followButton.isHidden == true ? 0:LabelRightWidth) + MarginRight) , height: (bounds.height - LabelMarginTop * 2) / 2)
        bottomLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: upperLabel.frame.origin.y + upperLabel.frame.height, width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height:(bounds.height - LabelMarginTop * 2) / 2 )
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func getTextWidth(_ text: String, height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.width
    }
    
    //MARK: - setup data
    
    func setImage(_ imageKey: String, category: ImageCategory, width: Int = Constants.MaxImageWidth) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage: UIImage(named: "default_profile_icon"))
		imageView.contentMode = .scaleAspectFill
    }
    func setupDataCell(_ user: User) {
        self.user = user
        setImage(user.profileImage, category: .user)
        self.upperLabel.text = String(format: "%@", user.displayName)
        self.bottomLabel.text = String(format: "%d %@", user.followerCount, String.localize("LB_CA_NO_OF_FOLLOWER"))
        self.followButton.setFollowButtonState(self.isFollowed(user))
        if user.isCurator == 1 {
            diamondImageView.isHidden = false
            imageView.layer.borderWidth = 1.0
        } else {
            diamondImageView.isHidden = true
            imageView.layer.borderWidth = 0.0
        }
        self.layoutSubviews()
        if user.isLoading {
            self.followButton.showLoading()
        }else {
            self.followButton.hideLoading()
        }
    }
    
    func isFollowed(_ user: User) ->Bool{
        return FollowService.instance.cachedFollowingUserKeys.contains(user.userKey )
    }

    
    //MARK:  - handle follow
    @objc func onFollowHandle(_ sender: ButtonFollow) {
        self.delegateFollowingUserList?.onTapFollowHandle(sender.tag, sender: sender)
    }
}
