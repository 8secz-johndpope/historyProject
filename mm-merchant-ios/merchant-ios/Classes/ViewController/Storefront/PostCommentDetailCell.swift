//
//  PostCommentViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
protocol PostCommentDetailCellDelegate: class {
    func didTapOnProfileImage(_ index: Int)
    func deleteClicked(_ collectionViewCell: UICollectionViewCell, index: Int)
}
class PostCommentDetailCell : UICollectionViewCell
{
    
    static let CellIdentifier = "PostCommentDetailCell"
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var commentLabel = UILabel()
    var bgView = UIView()
    var diamondImageView = UIImageView()
    var timeStampLabel = UILabel()
    var badgeLabel = UILabel()
    var bottomLine = UIView()
    
    private final let MarginRight : CGFloat = 12
    private final let MarginLeft : CGFloat = 14
    private final let LabelMarginTop : CGFloat = 18
    private final let LabelMarginRight : CGFloat = 15
    private final let ImageWidth : CGFloat = 32
    private final let ImageDiamondWidth : CGFloat = 16
    private final let LabelRightWidth : CGFloat = 120
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let LabelBadgeHeight : CGFloat = 20
    private final let BgViewMarginLeft : CGFloat = 10
    private final let BgViewMarginTop : CGFloat = 5
    private final let LabelUpperHeight : CGFloat = 24
    static let BaseCellHeight: CGFloat = 52
    static let CommentLabelMarginTop: CGFloat = 4
    static let CommentLabelMarginBottom : CGFloat = 18
    static let CommentLabelMarginLeft: CGFloat = 14
    static let CommentLabelMarginRight : CGFloat = 14
    
    var isCanDelete : Bool = false
    weak var delegate : PostCommentDetailCellDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
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
        
        commentLabel.numberOfLines = 0
        
        commentLabel.textAlignment = NSTextAlignment.left
        commentLabel.applyFontSize(12, isBold: false)
        commentLabel.lineBreakMode = .byTruncatingTail
        commentLabel.textColor = UIColor.secondary12()
        contentView.addSubview(commentLabel)

        diamondImageView.image = UIImage(named: "curator_diamond")
        contentView.addSubview(diamondImageView)
        contentView.addSubview(diamondImageView)
        diamondImageView.isHidden = true
        timeStampLabel.formatSize(12)
        contentView.addSubview(timeStampLabel)
        
        badgeLabel.formatSize(12)
        badgeLabel.textAlignment = .center
        badgeLabel.clipsToBounds = true
        badgeLabel.textColor = UIColor.white
        badgeLabel.layer.cornerRadius = LabelBadgeHeight / 2
        badgeLabel.backgroundColor = UIColor.primary1()
        badgeLabel.isHidden = true
        contentView.addSubview(badgeLabel)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOnProfileImage))
        tapGesture.cancelsTouchesInView = true
        self.imageView.addGestureRecognizer(tapGesture)
        
        imageView.isUserInteractionEnabled = true
        
        bottomLine = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 1))
        bottomLine.backgroundColor = UIColor.backgroundGray()
        contentView.addSubview(bottomLine)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGestureRecognized))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.contentView.addGestureRecognizer(longPressGestureRecognizer)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX + MarginLeft, y: LabelMarginTop, width: ImageWidth, height: ImageWidth)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight, y: LabelMarginTop - 4, width: bounds.width - (imageView.frame.maxX + MarginRight + LabelRightWidth + MarginRight) , height: LabelUpperHeight)
        timeStampLabel.frame = CGRect(x: imageView.frame.maxX + MarginRight , y: LabelLowerMarginTop, width: bounds.width - (imageView.frame.maxX +  MarginRight * 2), height: LabelUpperHeight)
        badgeLabel.frame = CGRect(x: bounds.maxX - (MarginLeft + LabelBadgeHeight) , y: bounds.minY + LabelLowerMarginTop, width: LabelBadgeHeight, height:LabelBadgeHeight)
        diamondImageView.frame = CGRect(x: imageView.frame.maxX - (ImageDiamondWidth - 2), y: imageView.frame.maxY - ImageDiamondWidth, width: ImageDiamondWidth, height: ImageDiamondWidth)
        imageView.layer.cornerRadius = imageView.frame.size.height / 2
        commentLabel.frame = CGRect(x: MarginLeft, y: imageView.frame.maxY + PostCommentDetailCell.CommentLabelMarginTop, width: bounds.width - (PostCommentDetailCell.CommentLabelMarginLeft + PostCommentDetailCell.CommentLabelMarginRight) , height: bounds.height - (imageView.frame.maxY + PostCommentDetailCell.CommentLabelMarginBottom))
        bottomLine.frame = CGRect(x: 15, y: self.bounds.maxY - 1, width: self.bounds.maxX - 30, height: 1)
    }
    
    class func getCommentTextHeight(_ widthCell: CGFloat, text: String) -> CGFloat {
        let lowerLabel = UILabel()
        if let font = UIFont(name: Constants.Font.Normal, size: 12) {
            lowerLabel.font = font
        } else {
            lowerLabel.formatSize(12)
        }
        
        let constraintRect = CGSize(width: widthCell - PostCommentDetailCell.CommentLabelMarginLeft - PostCommentDetailCell.CommentLabelMarginRight, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: lowerLabel.font], context: nil)
        return boundingBox.height
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ key : String, imageCategory : ImageCategory ){
        
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(key, category: imageCategory), placeholderImage : UIImage(named: "default_profile_icon"))
        imageView.contentMode = .scaleAspectFill
    }
    func configImage (_ type: Int) {
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

