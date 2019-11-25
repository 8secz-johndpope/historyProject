//
//  AvatarView.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
struct SizeAvatar {
    static let width: CGFloat = 36
    static let height: CGFloat = 36
    static let w_small: CGFloat = 30
    static let h_small: CGFloat = 30
}
struct SizeDiamondIcon {
    static let width:CGFloat = 14.0
    static let height:CGFloat = 14.0
}

enum ModeSizeAvatar:Int {
    case small = 0,
    big,
    custom
}
class AvatarView: UIView {
    
    var imageView = UIImageView()
    var imageViewDiamond = UIImageView()
    var isCurator = 0
    var mode = ModeSizeAvatar.big
    var sizeCustomAvatar: CGSize = CGSize.zero
    
    convenience init(imageStr: String, isCurator: Int) {
        self.init(frame: CGRect(x: 0, y: 0, width: SizeAvatar.width, height: SizeAvatar.height))
        imageView.clipsToBounds = true
        
        setAvatarImage(imageStr)
        switch isCurator {
        case 0:
            imageViewDiamond.image = UIImage()
            break
        case 1:
            imageViewDiamond.image = UIImage(named: "curator_diamond")
            break
        default:
            break
        }
        
    }
    convenience init(imageStr: String, width:CGFloat = 30, height:CGFloat = 30, mode: ModeSizeAvatar = .small) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        imageView.layer.cornerRadius = imageView.width/2
        imageView.clipsToBounds = true
        setAvatarImage(imageStr)
        imageViewDiamond.isHidden = true
        self.mode = mode
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.layer.cornerRadius = imageView.width/2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        imageViewDiamond.contentMode = .scaleAspectFill
        self.addSubview(imageViewDiamond)
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch mode {
        case .small:
            imageView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
            imageViewDiamond.frame = CGRect(x: self.bounds.maxX - SizeDiamondIcon.width, y: self.bounds.maxY - SizeDiamondIcon.width, width: 5, height: 5)
            break
        case .big:
            imageView.frame = CGRect(x: 0, y: 0, width: self.frame.sizeWidth, height: self.frame.sizeHeight)
            imageViewDiamond.frame = CGRect(x: self.bounds.maxX - SizeDiamondIcon.width, y: self.bounds.maxY - SizeDiamondIcon.width, width: SizeDiamondIcon.width, height: SizeDiamondIcon.height)
            break
        case .custom:
            
            imageView.frame = CGRect(x: (self.bounds.sizeWidth - self.sizeCustomAvatar.width) / 2, y: (self.bounds.sizeHeight - self.sizeCustomAvatar.height) / 2, width: self.sizeCustomAvatar.width, height: self.sizeCustomAvatar.height)
            let sizeDiamond = CGSize(width: imageView.frame.width / 3.6, height: imageView.frame.height / 3.6)
            imageViewDiamond.frame = CGRect(x: imageView.frame.maxX - sizeDiamond.width, y: imageView.frame.maxY - sizeDiamond.height, width: sizeDiamond.width, height: sizeDiamond.height)
        }
        
        imageView.layer.cornerRadius = imageView.width/2
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAvatarImage(_ key: String) {
        let defaultImage = UIImage(named: "default_profile_icon")
        
        if key.length > 0 {
            imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: .user), placeholderImage: defaultImage)
        } else {
            imageView.image = defaultImage
        }
        
        imageView.contentMode = .scaleAspectFill
    }
    
    func setupViewByUser(_ user:User, isMerchant : Bool = false) -> Void {
        setAvatarImage(user.getProfileImage())
        self.isCurator = user.isCurator
        if self.isCurator == 1 && !isMerchant {
            imageViewDiamond.image = UIImage(named: "curator_diamond")
        } else {
            imageViewDiamond.image = UIImage()
        }
    }
    
    func setupViewByMerchant(_ merchant: Merchant) -> Void {
        let defaultImage = UIImage(named: "default_profile_icon")
        if (merchant.smallLogoImage.length > 0) {
            imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(merchant.smallLogoImage, category: .merchant), placeholderImage : defaultImage)
            
        } else {
            imageView.image = defaultImage
        }
        imageView.contentMode = .scaleAspectFit
        self.isCurator = 0
    }
    
}
