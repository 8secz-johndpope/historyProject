//
//  CuratorCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/26/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CuratorCell: UICollectionViewCell {
    
    static let CellIdentifier = "CuratorCellID"
    static let NameLabelHeight: CGFloat = 40
    static let TopViewHeight: CGFloat = 40
    static let CuratorCellWidth: CGFloat = 80.0
    
    let buttonFollow = ButtonFollow()
    static let ButtonFollowBottomPadding:CGFloat = 20.0

    var imageView = UIImageView()
    static let ImageViewPaddingLeft:CGFloat = 10.0
    static let ImageViewPaddingTop:CGFloat = 0.0

    var nameLabel =  UILabel()
    static let LabelPadding:CGFloat = 10.0
    static let LabelHeight:CGFloat = 15.0

    let curatorDiamondImageView = UIImageView()
    private final let CuratorDiamondImageViewSize:CGSize = CGSize(width: 20, height: 20)

    let labelListAll = UILabel()
    
    var userKey: String?
    
    var shouldShowListAll:Bool = false {
        didSet{
            updateUIForShowAllCell()
        }
    }
    
    func updateUIForShowAllCell() {
        if shouldShowListAll{
            labelListAll.isHidden = false
            self.imageView.image = nil
            nameLabel.isHidden = true
            buttonFollow.isHidden = true
            curatorDiamondImageView.isHidden = true
        } else{
            labelListAll.isHidden = true
            nameLabel.isHidden = false
            curatorDiamondImageView.isHidden = false
            if let userKey = self.userKey, userKey == Context.getUserKey(){
                buttonFollow.isHidden = true
            } else {
                buttonFollow.isHidden = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        imageView.clipsToBounds = true
        self.imageView.backgroundColor = UIColor.secondary1()
        addSubview(imageView)
        
        nameLabel.applyFontSize(12, isBold: true)
        nameLabel.textColor = UIColor.secondary2()
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = UIColor.white
        addSubview(nameLabel)
        
        curatorDiamondImageView.image = UIImage(named: "curator_diamond")
        addSubview(curatorDiamondImageView)
        
        buttonFollow.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        addSubview(buttonFollow)
        
        labelListAll.formatSize(16)
        labelListAll.numberOfLines = 2
        labelListAll.textAlignment = .center
        labelListAll.textColor = UIColor.white
        labelListAll.text = String.localize("LB_NEWFEED_CURATOR_ALL")
        labelListAll.isHidden = true
        addSubview(labelListAll)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateUIForShowAllCell()
        
        let widthImageView = CuratorCell.CuratorCellWidth - 2*CuratorCell.ImageViewPaddingLeft
        imageView.frame = CGRect(x: (self.bounds.width - widthImageView) / 2, y: CuratorCell.ImageViewPaddingTop, width: widthImageView, height: widthImageView)
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        
        curatorDiamondImageView.frame = CGRect(x: imageView.frame.maxX - CuratorDiamondImageViewSize.width, y: imageView.frame.maxY - CuratorDiamondImageViewSize.height, width: CuratorDiamondImageViewSize.width, height: CuratorDiamondImageViewSize.height)

        nameLabel.frame = CGRect(x: imageView.frame.minX, y: imageView.frame.maxY + CuratorCell.LabelPadding, width: imageView.frame.sizeWidth, height: CuratorCell.LabelHeight)
        
        buttonFollow.frame = CGRect(x: (frame.sizeWidth - ButtonFollow.ButtonFollowSize.width)/2, y: nameLabel.frame.maxY + CuratorCell.LabelPadding, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)

        let paddingLeftRight: CGFloat = 8
        var labelAllFrame = imageView.frame
        labelAllFrame.originX = labelAllFrame.originX + paddingLeftRight
        labelAllFrame.sizeWidth = imageView.frame.sizeWidth - 2 * paddingLeftRight
        labelListAll.frame = labelAllFrame
    }
    
    func setImage(_ key: String, imageCategory: ImageCategory, index: Int? = nil, width: Int? = nil) {
        self.imageView.image = self.placeholderImage()
        if key.isEmpty {
            return
        }
        
        /* Remove not used variables
        var imageWidth = Int(self.bounds.width * UIScreen.main.scale)
        
        if let width = width {
            imageWidth = width
        }*/
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(key, category: imageCategory), placeholderImage: self.placeholderImage(), clipsToBounds: true, contentMode: .scaleAspectFill, progress: nil, optionsInfo: nil, completion: {[weak self] (image, error, cacheType, imageURL) -> Void in
            if error == nil {
                if let strongSelf = self {
                    if strongSelf.shouldShowListAll {
                        strongSelf.imageView.image = nil
                    } else {
                        if index == nil || index == strongSelf.tag {
                            strongSelf.imageView.image = image
                        }
                    }
                }
            }
        })
    }
    
    func placeholderImage() -> UIImage?{
        return UIImage(named: Constants.ImageName.BrandPlaceholder)
    }
    
    class func curatorCellHeight() -> CGFloat{
        return  CuratorCell.LabelPadding + CuratorCell.LabelHeight + CuratorCell.CuratorCellWidth - 2*CuratorCell.ImageViewPaddingLeft  + CuratorCell.ImageViewPaddingTop
    }
}
