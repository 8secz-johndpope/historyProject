//
//  OutfitBrandViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


class OutfitBrandViewCell: UICollectionViewCell {
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var borderView = UIView()
    var lowerLabel = UILabel()
    
    var imageViewIcon = UIImageView()
    var buttonView = UIView()
    var followButton = UIButton()
    var imageViewDiamond =  UIImageView()
    
    private final let MarginRight : CGFloat = 20
    private final let MarginLeft : CGFloat = 15
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let ImageWidth : CGFloat = 44
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 63
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let ButtonHeight : CGFloat = 25
    private final let ButtonWidth : CGFloat = 64
    private final let ChatButtonWidth : CGFloat = 30
    private final let HeightLabel: CGFloat = 21
    var isSelectedCell = false
    var modeList = ModeGetTagList.brandTagList
    let viewAvatar = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        viewAvatar.backgroundColor = UIColor.clear
        self.addSubview(viewAvatar)
        
        backgroundColor = UIColor.white
        imageView.image = UIImage(named: "logo_kate_spade_M")
        imageView.contentMode = .scaleAspectFill
        viewAvatar.addSubview(imageView)
        
        upperLabel.formatSize(15)
        upperLabel.text = ""
        upperLabel.textColor = UIColor.secondary2()
        upperLabel.numberOfLines = 1
        upperLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
        addSubview(upperLabel)
        
        lowerLabel.text = ""
        lowerLabel.formatSize(12)
        lowerLabel.textColor = UIColor.secondary3()
        addSubview(lowerLabel)
        
        imageViewIcon.image = UIImage()//icon_checkbox_checked
        imageViewIcon.contentMode = .scaleAspectFill
        addSubview(imageViewIcon)
        
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        imageViewDiamond.image = UIImage(named: "curator_diamond")
        imageViewDiamond.isHidden = true
        viewAvatar.addSubview(imageViewDiamond)
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageViewIcon.frame = CGRect(x: MarginLeft, y: (self.frame.height - ButtonHeight) / 2, width: ButtonHeight, height: ButtonHeight)
        
        viewAvatar.frame = CGRect(x: imageViewIcon.frame.maxX + MarginRight, y: bounds.midY - ImageWidth / 2, width: ImageWidth, height: ImageWidth)
        imageView.frame = viewAvatar.bounds
        upperLabel.frame = CGRect(x: viewAvatar.frame.maxX + MarginRight, y: (self.frame.height - HeightLabel)/2, width: bounds.width - (viewAvatar.frame.maxX + 2*MarginRight) , height: HeightLabel)
        if modeList == ModeGetTagList.brandTagList {
            lowerLabel.frame = CGRect(x: viewAvatar.frame.maxX + MarginRight, y: upperLabel.frame.origin.y + upperLabel.frame.height, width: bounds.width - (viewAvatar.frame.maxX + MarginRight * 2) , height:(bounds.height - LabelMarginTop * 2) / 2)
        } else { // mode tag friend list
            lowerLabel.frame = CGRect(x: viewAvatar.frame.maxX + MarginRight, y: upperLabel.frame.origin.y + upperLabel.frame.height, width: bounds.width - (imageView.frame.maxX + MarginRight * 2) , height:0)
        }
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        imageViewDiamond.frame = CGRect(x: viewAvatar.frame.width - ImageDiamondWidth, y: imageView.frame.height - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - setup data
    
    func setImage(_ imageKey : String, category : ImageCategory, placeHolder: String = "holder"){
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageKey, category: category), placeholderImage : UIImage(named: placeHolder), contentMode: UIViewContentMode.scaleAspectFit)
    }
    func setupDataCell(_ merchant: Merchant) {
        setImage(merchant.headerLogoImage, category: .merchant)
        self.upperLabel.text = String(format: "%@", merchant.merchantNameInvariant)
        self.lowerLabel.text = String(format: "%@", merchant.merchantName)
        self.imageViewDiamond.isHidden = true
         layoutSubviews()
    }
    func setupDataCellByUser(_ user: User, mode: ModeGetTagList, placeHolder: String = "holder") {
        modeList = mode
        setImage(user.profileImage, category: .user, placeHolder: placeHolder)
        imageView.contentMode = .scaleAspectFill
        self.upperLabel.text = user.displayName
        if user.isCurator == 1 {
            self.imageViewDiamond.isHidden = false
        } else {
            self.imageViewDiamond.isHidden = true
        }
        layoutSubviews()
        
    }
}
