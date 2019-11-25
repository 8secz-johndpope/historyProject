//
//  MerchantListViewCell.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


@objc
protocol MerchantCellDelegate: NSObjectProtocol {
    @objc optional func onTapFollowHandle(_ rowIndex: Int, sender: ButtonFollow)
}
class MerchantListViewCell : UICollectionViewCell{
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
    private final let ButtonHeight : CGFloat = ButtonFollow.ButtonFollowSize.height
    private final let ButtonWidth : CGFloat = 64
    private final let ChatButtonWidth : CGFloat = 30
    var merchant: Merchant?
    var IsFollow: Bool = true
    weak var delegateMerchantList: MerchantCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addSubview(imageView)
        upperLabel.applyFontSize(15, isBold: true)
        
        upperLabel.textColor = UIColor.secondary2()
        upperLabel.numberOfLines = 1
        upperLabel.lineBreakMode = .byTruncatingTail
        addSubview(upperLabel)
        
        lowerLabel.formatSize(12)
        lowerLabel.textColor = UIColor.secondary3()
        lowerLabel.lineBreakMode = .byTruncatingTail
        lowerLabel.numberOfLines = 1
        lowerLabel.isHidden = true
        addSubview(lowerLabel)
        
        bottomLabel.formatSize(12)
        bottomLabel.textColor = UIColor.secondary3()
        addSubview(bottomLabel)
        
        followButton.addTarget(self, action: #selector(MerchantListViewCell.onFollowHandle), for: UIControlEvents.touchUpInside)
        followButton.isCollectType = true
        addSubview(followButton)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        followButton.frame = CGRect(x: frame.sizeWidth - ButtonFollow.ButtonFollowSize.width - MarginRight, y: (bounds.height - ButtonFollow.ButtonFollowSize.height)/2, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: bounds.minY + LabelMarginTop + 8, width: bounds.width - (imageView.frame.maxX + MarginRight + (followButton.isHidden == true ? 0:ButtonFollow.ButtonFollowSize.width + MarginRight / 2) + MarginRight) , height: (bounds.height - LabelMarginTop * 2) / 3)
        
        lowerLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: upperLabel.frame.origin.y + upperLabel.frame.height, width: bounds.width - ((imageView.frame.maxX + MarginRight + (followButton.isHidden == true ? 0 : ButtonFollow.ButtonFollowSize.width + MarginRight / 2) + MarginRight)) , height:(bounds.height - LabelMarginTop * 2) / 3 )
        
        
        bottomLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: upperLabel.frame.origin.y + upperLabel.frame.height, width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height:(bounds.height - LabelMarginTop * 2) / 3 )
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
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
    
    func setImage(_ imageKey : String, category : ImageCategory){
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: category), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
    func setupDataCell(_ merchant: Merchant) {
        self.merchant = merchant
        if merchant.headerLogoImage.length > 0{
            setImage(merchant.headerLogoImage, category: .merchant)
        }
        else if merchant.largeLogoImage.length > 0{
            setImage(merchant.largeLogoImage, category: .merchant)
        }
        self.upperLabel.text = String(format: "%@", merchant.merchantNameInvariant)
        self.lowerLabel.text = String(format: "%@", merchant.merchantName)
        self.bottomLabel.text = String(format: "%d %@", merchant.followerCount, String.localize("人已收藏"))
        self.followButton.setFollowButtonState(merchant.followStatus)
        if merchant.isLoading {
            self.followButton.showLoading()
        }else {
            self.followButton.hideLoading()
        }
    }
    
    //MARK:  - handle follow
    @objc func onFollowHandle(_ sender: ButtonFollow) {
        self.delegateMerchantList?.onTapFollowHandle!(sender.tag, sender: sender)
    }
}
