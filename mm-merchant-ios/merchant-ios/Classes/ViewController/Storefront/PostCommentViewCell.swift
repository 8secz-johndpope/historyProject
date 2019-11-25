//
//  PostCommentViewCell.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 5/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
protocol PostCommentViewCellDelegate: class{
    func didTapOnProfileImage(_ index: Int)
    func deleteClicked(_ collectionViewCell: UICollectionViewCell, index: Int)
}
class PostCommentViewCell : SwipeActionMenuCell{
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var lowerLabel = UILabel()
    var bgView = UIView()
    var diamondImageView = UIImageView()
    var rightLabel = UILabel()
    var badgeLabel = UILabel()
    private final let MarginRight : CGFloat = 10
    private final let MarginLeft : CGFloat = 20
    private final let LabelMarginTop : CGFloat = 8
    private final let LabelMarginRight : CGFloat = 15
    private final let ImageWidth : CGFloat = 44
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 120
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let LabelBadgeHeight : CGFloat = 20
    private final let BgViewMarginLeft : CGFloat = 10
    private final let BgViewMarginTop : CGFloat = 5
    private final let LabelUpperHeight : CGFloat = 24
    private final let LabelLowerMarginBottom : CGFloat = 13
    var isCanDelete : Bool = false
    weak var delegate : PostCommentViewCellDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
//        self.layer.shadowColor = UIColor.lightGray.cgColor
//        self.layer.shadowOffset = CGSize(width: 0, height: 2)
//        self.layer.shadowRadius = 2.0
//        self.layer.shadowOpacity = 1.0
//        self.layer.masksToBounds = false
//        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).CGPath
        
        
        imageView.layer.borderWidth = 0.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.primary1().cgColor
        
        contentView.addSubview(imageView)
        upperLabel.applyFontSize(14, isBold: true)
        upperLabel.textColor = UIColor.secondary12()
        upperLabel.numberOfLines = 1
        upperLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(upperLabel)
        
        lowerLabel.numberOfLines = 0
        
        lowerLabel.textAlignment = NSTextAlignment.left
        lowerLabel.applyFontSize(12, isBold: false)
        lowerLabel.lineBreakMode = .byTruncatingTail
        lowerLabel.textColor = UIColor.secondary12()
        contentView.addSubview(lowerLabel)

        diamondImageView.image = UIImage(named: "curator_diamond")
        contentView.addSubview(diamondImageView)
        contentView.addSubview(diamondImageView)
        diamondImageView.isHidden = true
        rightLabel.formatSize(12)
        rightLabel.textAlignment = .right
        contentView.addSubview(rightLabel)
        
        badgeLabel.formatSize(12)
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        badgeLabel.textColor = UIColor.white
        badgeLabel.layer.cornerRadius = LabelBadgeHeight / 2
        badgeLabel.backgroundColor = UIColor.primary1()
        badgeLabel.isHidden = true
        contentView.addSubview(badgeLabel)
        
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapOnProfileImage)))
        imageView.isUserInteractionEnabled = true
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.contentView.addGestureRecognizer(longPressGestureRecognizer)

        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: LabelMarginTop, width: ImageWidth, height: ImageWidth)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: bounds.minY + LabelMarginTop, width: bounds.width - (imageView.frame.maxX + MarginRight + LabelRightWidth + MarginRight) , height: LabelUpperHeight )
        lowerLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: LabelLowerMarginTop, width: bounds.width - (imageView.frame.maxX +  MarginRight * 2) , height: bounds.height - (LabelLowerMarginTop + LabelLowerMarginBottom))
        rightLabel.frame = CGRect(x: upperLabel.frame.maxX , y: bounds.minY + LabelMarginTop, width: bounds.maxX - (upperLabel.frame.maxX + MarginLeft), height: LabelUpperHeight )
        
        badgeLabel.frame = CGRect(x: bounds.maxX - (MarginLeft + LabelBadgeHeight) , y: bounds.minY + LabelLowerMarginTop, width: LabelBadgeHeight, height:LabelBadgeHeight )
        
//        bgView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - BgViewMarginTop)
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory ){
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: imageCategory), placeholderImage : UIImage(named: "default_profile_icon"))
        imageView.contentMode = .scaleAspectFill
    }
    func configImage (_ type: Int) {
        //TODO will be define later with real data
        let temp = type % 4
        if temp == 0 {
            diamondImageView.isHidden = true
            imageView.layer.cornerRadius = imageView.frame.height / 2
            imageView.layer.borderWidth = 0.0
        } else if temp == 1 {
            diamondImageView.isHidden = false
            imageView.layer.cornerRadius = imageView.frame.height / 2
            imageView.layer.borderWidth = 1.0
        } else if temp == 2{
            diamondImageView.isHidden = true
            imageView.layer.cornerRadius = 3
            imageView.layer.borderWidth = 0.0
        } else {
            diamondImageView.isHidden = true
            imageView.layer.cornerRadius = 0
            imageView.layer.borderWidth = 0.0
        }
        
    }
    
    func setBadgeNumber(_ number : Int) {
        if number > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = String(number)
            
            var width = StringHelper.getTextWidth(badgeLabel.text!, height: LabelBadgeHeight, font: badgeLabel.font)
            if width < LabelBadgeHeight {
                width = LabelBadgeHeight
            }
            var frame = self.badgeLabel.frame
            frame.size.width = width
            frame.originX = bounds.width - (MarginLeft + width)
            self.badgeLabel.frame = frame
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    
    override var canBecomeFirstResponder : Bool {
        return true
    }

    
    @objc func tapOnProfileImage(_ sender: Any) {
        delegate?.didTapOnProfileImage(self.tag)
    }
    
    @objc func longPressGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.began && self.isCanDelete) {
            becomeFirstResponder()
            if let delegate = self.delegate {
                delegate.deleteClicked(self, index: self.tag)
            }
            
        }
    }

}

