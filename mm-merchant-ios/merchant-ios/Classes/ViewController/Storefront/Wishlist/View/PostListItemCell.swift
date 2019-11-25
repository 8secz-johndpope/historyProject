//
//  PostListItemCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class AvatarPostView: AvatarView {
    
    let sizeAvatar = CGFloat(30)
    /**
     Create avatar with size small
     
     - parameter imageStr: String
     
     - returns: avatar view
     */
    convenience init(image: UIImage = UIImage(named: "default_profile_icon")!, isCurator: Int) {
        self.init(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        
        imageView.layer.cornerRadius = imageView.width / 2
        imageView.clipsToBounds = true
        imageView.image = image
        imageViewDiamond.isHidden = true
        self.mode = .big
        
        switch isCurator {
        case 0:
            imageViewDiamond.image = UIImage()
            imageViewDiamond.isHidden = true
        case 1:
            imageViewDiamond.image = UIImage(named: "curator_diamond")
            imageViewDiamond.isHidden = false

        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let widthDiamond = CGFloat(11)
        let heightDiamond = CGFloat(11)
        imageView.frame = CGRect(x: 0, y: 0, width: sizeAvatar, height: sizeAvatar)
        imageViewDiamond.frame = CGRect(x: self.bounds.maxX - widthDiamond, y: self.bounds.maxY - widthDiamond, width: widthDiamond, height: heightDiamond)
        imageView.layer.cornerRadius = imageView.width/2
    }

}

class PostListItemCell: SwipeActionMenuCell {
    
    static let postCellIndentifier = "PostListItemCellId"
    static let CellHeight : CGFloat = 100
    private final let heightLabel = CGFloat(21)
    private var widhtLabel = CGFloat(50)
    
    private var postImageView: UIImageView!
    private var avatarView: AvatarView!
    private var userNameLabel: UILabel!
    private var brandNameLabel: UILabel!
    private var brandDescriptionLabel: UILabel!
    
    var postImageHandler: ((_ data: Any) -> Void)?
    var brandLabelHandler: ((_ data: Any) -> Void)?
    
    var data: Post?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
		
        let ContainerPaddingTop = CGFloat(10)
        let ContainerHeight = CGFloat(80)
        
        let containerFrame = CGRect(x: 0, y: ContainerPaddingTop, width: frame.width, height: ContainerHeight)
        let containerView = UIView(frame: containerFrame)
        
        self.contentView.addSubview(containerView)
        
        let MarginLeft = CGFloat(15)
        let productImageFrame = CGRect(x: MarginLeft, y: 0, width: 80, height: 80)
        let postImageView = UIImageView(frame: productImageFrame)
        postImageView.contentMode = .scaleAspectFill
        
        containerView.addSubview(postImageView)
        self.postImageView = postImageView
        self.postImageView.isUserInteractionEnabled = true
        self.postImageView.image = UIImage(named: "post_dummy")
        self.postImageView.contentMode = .scaleAspectFit
        
        /// avatar style
        let marginLeft = CGFloat(22)
        let xPos = postImageView.frame.maxX + marginLeft
        
        let avatarView = { () -> AvatarView in
            let avatarView = AvatarPostView(image: UIImage(named: "default_profile_icon")!, isCurator: 1)
            avatarView.frame = CGRect(x: xPos, y: 0, width: avatarView.width, height: avatarView.height)
            self.avatarView = avatarView
            
            return avatarView
        } ()
        
        containerView.addSubview(avatarView)
        
        /// name label style
        let nameLabel = { () -> UILabel in
            let nameLabel = UILabel(frame: CGRect(x: avatarView.frame.maxX + Margin.left, y: (avatarView.height - heightLabel)/2, width: self.widhtLabel, height: self.heightLabel))
            nameLabel.formatSize(12)
            nameLabel.textColor = UIColor.secondary2()
            self.userNameLabel = nameLabel
            self.userNameLabel.text = ""
            self.userNameLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            
            return nameLabel
        }()
        
        containerView.addSubview(nameLabel)
        
        /// brand name label style
        let nameBrandLabel = { () -> UILabel in
            let nameBrandLabel = UILabel(frame: CGRect(x: nameLabel.frame.maxX + Margin.left, y: (avatarView.height - heightLabel)/2, width: self.widhtLabel, height: self.heightLabel))
            nameBrandLabel.formatSize(12)
            nameBrandLabel.round(5.0)
            nameBrandLabel.textColor = UIColor.secondary2()
            nameBrandLabel.layer.borderWidth = 1.0
            nameBrandLabel.layer.borderColor = UIColor.secondary1().cgColor
            nameBrandLabel.text = ""
            nameBrandLabel.textAlignment = .center
            nameBrandLabel.isUserInteractionEnabled = true
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(PostListItemCell.brandTapped))
            nameBrandLabel.addGestureRecognizer(singleTap)
            
            self.brandNameLabel = nameBrandLabel
            
            return nameBrandLabel
        }()
        
        containerView.addSubview(nameBrandLabel)
        
        // description name label
        let descriptionLabel = { () -> UILabel in
            let descriptionLabel = UILabel(frame: CGRect(x: avatarView.frame.origin.x, y: avatarView.frame.maxY + Margin.top, width: self.width - avatarView.frame.origin.x - Margin.left, height: self.heightLabel))
            descriptionLabel.formatSize(12)
            self.brandDescriptionLabel = descriptionLabel
            self.brandDescriptionLabel.text = ""
            self.brandDescriptionLabel.lineBreakMode = .byTruncatingTail
            self.brandDescriptionLabel.numberOfLines = 2
            self.brandDescriptionLabel.textColor = UIColor.secondary6()
            
            return descriptionLabel
        }()
        
        containerView.addSubview(descriptionLabel)
        
        let lineHeight = CGFloat(1)
        let line = UIView(frame: CGRect(x: 0, y: self.contentView.frame.maxY - lineHeight, width: self.contentView.frame.width, height: lineHeight))
        line.backgroundColor = UIColor.backgroundGray()
        
        self.contentView.addSubview(line)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func formatBrandText(_ brandText: String) -> String {
        let maxLengthOfText = 6
        var text = brandText
        if text.length > maxLengthOfText {
            text = (text as NSString).substring(to: maxLengthOfText)
            text = text + "..."
        }
        
        return text
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

		// clear left menu items
		self.leftMenuItems = nil
		
        var width = StringHelper.getTextWidth(self.userNameLabel.text!, height: heightLabel, font: self.userNameLabel.font)
        
        let widthBrandLabel = StringHelper.getTextWidth(self.formatBrandText(self.brandNameLabel.text ?? ""), height: heightLabel, font: self.brandNameLabel.font) + Margin.left * 2
    
        if 100 > bounds.width {
            width = bounds.width - widthBrandLabel - avatarView.frame.maxX - Margin.left * 3
        }
        
        self.userNameLabel.frame = CGRect(x: avatarView.frame.maxX + Margin.left, y: (avatarView.height - heightLabel)/2, width: width, height: self.heightLabel)
        
        self.brandNameLabel.frame = CGRect(x: userNameLabel.frame.maxX + Margin.left, y: (avatarView.height - heightLabel)/2, width: widthBrandLabel, height: self.heightLabel)
        
        let heightDescription = StringHelper.heightForText(self.brandDescriptionLabel.text!, width: self.brandDescriptionLabel.width, font: self.brandDescriptionLabel.font)
        
        if heightDescription > heightLabel {
            self.brandDescriptionLabel.frame = CGRect(x: avatarView.frame.origin.x, y: avatarView.frame.maxY + Margin.top, width: self.width - avatarView.frame.origin.x - Margin.left, height: heightLabel * 2 )
        } else {
            self.brandDescriptionLabel.frame = CGRect(x: avatarView.frame.origin.x, y: avatarView.frame.maxY + Margin.top, width: self.width - avatarView.frame.origin.x - Margin.left, height: heightLabel)
        }
    }
    
    // MARK: - Actions
    
    @objc func brandTapped() {
        if let callback = brandLabelHandler {
            if let data = self.data {
                if let merchant = data.merchant {
                    callback(merchant)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    /**
     go to PDP
     */
    func cellTapped() {
        if let callback = postImageHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    //MARK: API
    
    func setupData(_ data: Post) {
        self.data = data 
        
        if data.postImage.length > 0 {
            setImage(data.postImage, category: .post, targetImageView: self.postImageView, placeHolder: "default_cover")
        } else {
            self.postImageView.image = UIImage(named: "default_cover")
        }
        
        if let user = data.user {
            self.userNameLabel.text = user.displayName
            self.avatarView.setupViewByUser(user, isMerchant: (data.isMerchantIdentity.rawValue == 1))
            setImage(user.getProfileImage(), category: .user, targetImageView: self.avatarView.imageView, placeHolder: "default_profile_icon")
        } else {
            self.avatarView.imageView.image = UIImage(named: "default_profile_icon")
            self.avatarView.imageViewDiamond.isHidden = true
            self.userNameLabel.text = ""
        }
        
        if let merchant = data.merchant {
            if data.isMerchantIdentity == .fromContentManager {
                self.avatarView.setupViewByMerchant(merchant)
                self.userNameLabel.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                brandNameLabel.isHidden = true
            } else {
                brandNameLabel.text = merchant.merchantName.length > 0 ? merchant.merchantName : merchant.merchantCompanyName
                brandNameLabel.text = self.formatBrandText(self.brandNameLabel.text ?? "")
                brandNameLabel.isHidden = false
            }
        } else {
            brandNameLabel.isHidden = true
        }
        
        // display post text
        self.brandDescriptionLabel.text = data.postText
        
        layoutSubviews() // update frame
    }
    
    /**
     set Image for image view
     
     - parameter imageKey:        key image String
     - parameter category:        category
     - parameter targetImageView: imageView
     */
    func setImage(_ imageKey: String, category: ImageCategory, targetImageView: UIImageView, placeHolder: String) {
        
        var size = ResizerSize.size512
        if category == .user {
            size = .size128
        }
        targetImageView.mm_setImageWithURL(ImageURLFactory.URLSize(size, key: imageKey, category: category), placeholderImage: UIImage(named: placeHolder))
        targetImageView.contentMode = .scaleAspectFill
    }
	
}
