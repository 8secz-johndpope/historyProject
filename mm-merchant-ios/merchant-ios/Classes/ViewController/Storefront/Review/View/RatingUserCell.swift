//
//  UserRatingCell.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Cosmos

protocol RatingUserCellDelegate: NSObjectProtocol {
    func didTapOnUser(_ userName: String)
}

class RatingUserCell: UICollectionViewCell {
    
    static let CellIdentifier = "RatingUserCellID"
    static let FontSize = 15
    
    private static let BaseCellHeight: CGFloat = 105
    private static let PaddingContent: CGFloat = 10
    private static let PaddingLeft: CGFloat = 15
    private static let PaddingRight: CGFloat = 15
    private static let AvatarSize = CGSize(width: 30, height: 30)
    
    private final let RatingViewSize = CGSize(width: 85, height: 14)
    private final let LabelHeight: CGFloat = 25
    private final let RatingViewMargin: CGFloat = 10
    private final let CommentDateTopMargin: CGFloat = 5
    
    var avatarView: AvatarView!
    var usernameLabel: UILabel!
    var ratingView: CosmosView!
    var userCommentLabel: UILabel!
    var commentDateLabel: UILabel!
    var moreActionButton : UIButton!
    
    var displayAvatar = true
    
    weak var delegate: RatingUserCellDelegate?
    
    var moreReviewHandler: ((RatingUserCell) -> Void)?
    
    var skuReview: SkuReview? {
        didSet {
            if let skuReview = self.skuReview {
                userCommentLabel.text = skuReview.description
                commentDateLabel.text = Constants.DateFormatter.getFormatter("yyyy.MM.dd").string(from: skuReview.lastCreated)
                ratingView.rating = Double(skuReview.rating)
                usernameLabel.text = skuReview.userDisplayName
                avatarView.setAvatarImage(skuReview.userProfileImage)
                if skuReview.isCurator == 1 {
                    avatarView.imageViewDiamond.image = UIImage(named: "curator_diamond")
                    avatarView.imageViewDiamond.isHidden = false
                }
                else {
                    avatarView.imageViewDiamond.image = nil
                    avatarView.imageViewDiamond.isHidden = true
                }
                moreActionButton.isHidden = (skuReview.userKey == Context.getUserKey())
            } else {
                userCommentLabel.text = ""
                userCommentLabel.text = ""
                commentDateLabel.text = ""
                ratingView.rating = 0
                moreActionButton.isHidden = true
            }
            
            self.updateViewFrame()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let marginLeft: CGFloat = 12
        let moreActionButtonSize = CGSize(width: 30, height: 30)
        
        avatarView = AvatarView(imageStr: "", width: RatingUserCell.AvatarSize.width, height: RatingUserCell.AvatarSize.height, mode: .custom)
        avatarView.sizeCustomAvatar = RatingUserCell.AvatarSize
        avatarView.frame = CGRect(x: RatingUserCell.PaddingLeft, y: RatingUserCell.PaddingContent, width: RatingUserCell.AvatarSize.width, height: RatingUserCell.AvatarSize.height)
        self.addSubview(avatarView)
        
        usernameLabel = UILabel()
        usernameLabel.format()
        
        if let font = UIFont(name: Constants.Font.Bold, size: CGFloat(RatingUserCell.FontSize)) {
            usernameLabel.font = font
        } else {
            usernameLabel.formatSizeBold(RatingUserCell.FontSize)
        }
        
        usernameLabel.textColor = UIColor.black
        usernameLabel.lineBreakMode = .byTruncatingTail
        usernameLabel.frame = CGRect(x: avatarView.frame.maxX + marginLeft, y: RatingUserCell.PaddingContent, width: frame.width - avatarView.frame.maxX - marginLeft - moreActionButtonSize.width, height: RatingUserCell.AvatarSize.height)
        self.addSubview(usernameLabel)
        
        moreActionButton = UIButton()
        moreActionButton.frame = CGRect(x: self.frame.maxX - marginLeft - moreActionButtonSize.width, y: usernameLabel.frame.midY - (moreActionButtonSize.height / 2), width: moreActionButtonSize.width, height: moreActionButtonSize.height)
        moreActionButton.setImage(UIImage(named: "btn_option"), for: UIControlState())
        moreActionButton.addTarget(self, action: #selector(RatingUserCell.moreReviewAction), for: .touchUpInside)
        self.addSubview(moreActionButton)
        
        let userContentView = UIView(frame: CGRect(x: RatingUserCell.PaddingContent, y: RatingUserCell.PaddingContent, width: RatingUserCell.AvatarSize.width + usernameLabel.width - marginLeft - 30, height: RatingUserCell.AvatarSize.height))
        userContentView.backgroundColor = UIColor.clear
        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(RatingUserCell.onTapUser))
        userContentView.isUserInteractionEnabled = true
        userContentView.addGestureRecognizer(tapAvatar)
        userContentView.becomeFirstResponder()
        self.addSubview(userContentView)

        ratingView = CosmosView()
        ratingView.settings.minTouchRating = 1
        ratingView.settings.totalStars = 5
        ratingView.settings.starSize = 14
        ratingView.settings.fillMode = .full
        ratingView.settings.starMargin = 4
        ratingView.text = ""
        ratingView.settings.filledColor = UIColor.ratingStar()
        ratingView.clipsToBounds = true
        
        // Only set frame rating view after all setting because CosmosView update frame itself automatically
        ratingView.frame = CGRect(x: RatingUserCell.PaddingLeft, y: avatarView.frame.maxY + RatingViewMargin, width: RatingViewSize.width, height: RatingViewSize.height)
        self.addSubview(ratingView)
        
        userCommentLabel = UILabel(frame: CGRect(x: RatingUserCell.PaddingLeft, y: ratingView.frame.maxY + RatingViewMargin, width: frame.sizeWidth - RatingUserCell.PaddingLeft - RatingUserCell.PaddingRight, height: LabelHeight))
        userCommentLabel.format()
        userCommentLabel.textColor = UIColor.black
        if let font = UIFont(name: "PingFangSC-Light", size: 14) {
            userCommentLabel.font = font
        } else {
            userCommentLabel.formatSizeBold(14)
        }
        self.addSubview(userCommentLabel)
        
        commentDateLabel = UILabel(frame: CGRect(x: RatingUserCell.PaddingLeft, y: userCommentLabel.frame.maxY + CommentDateTopMargin, width: frame.sizeWidth - RatingUserCell.PaddingLeft - RatingUserCell.PaddingRight, height: LabelHeight))
        commentDateLabel.formatSize(12)
        self.addSubview(commentDateLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func updateViewFrame() {
        let userCommentLabelHeight = RatingUserCell.getLabelHeight(text: userCommentLabel.text, cellWidth: frame.sizeWidth, font: userCommentLabel.font)

        if !displayAvatar {
            avatarView.isHidden = true
            usernameLabel.isHidden = true
            ratingView.frame = CGRect(x: RatingUserCell.PaddingLeft, y: RatingViewMargin, width: RatingViewSize.width, height: RatingViewSize.height)
        }
        userCommentLabel.frame = CGRect(x: RatingUserCell.PaddingLeft, y: ratingView.frame.maxY + RatingViewMargin, width: frame.sizeWidth - RatingUserCell.PaddingLeft - RatingUserCell.PaddingRight, height: userCommentLabelHeight)
        commentDateLabel.frame = CGRect(x: RatingUserCell.PaddingLeft, y: userCommentLabel.frame.maxY + CommentDateTopMargin, width: frame.sizeWidth - RatingUserCell.PaddingLeft - RatingUserCell.PaddingRight, height: LabelHeight)
    }
    
    // MARK: - Size
    
    // Get Size label of user comment label
    class func getLabelHeight(text: String?, cellWidth: CGFloat, font: UIFont? = nil) -> CGFloat {
        if let text: String = text {
            let labelWidth = cellWidth - (RatingUserCell.PaddingLeft + RatingUserCell.PaddingRight)
            let dummyLabel = UILabel()
            if let font = font {
                dummyLabel.font = font
            }
            else {
                dummyLabel.formatSize(RatingUserCell.FontSize)
            }
            dummyLabel.numberOfLines = 0
            
            return StringHelper.heightForText(text, width: labelWidth, font: dummyLabel.font)
        }
        
        return 0
    }
    
    class func getCellSize(text: String?, cellWidth: CGFloat, hasAvatar: Bool = true) -> CGSize {
        if let _: String = text {
            
            let dummyLabel = UILabel()
            if let font = UIFont(name: "PingFangSC-Light", size: 14) {
                dummyLabel.font = font
            } else {
                dummyLabel.formatSizeBold(14)
            }

            var detailLabelHeight = RatingUserCell.getLabelHeight(text: text, cellWidth: cellWidth, font: dummyLabel.font)
            
            if !hasAvatar {
                detailLabelHeight -= self.AvatarSize.height
            }
            
            return CGSize(width: cellWidth, height: self.BaseCellHeight + detailLabelHeight)
        }
        
        return CGSize.zero
    }
    
    // MARK: - Actions
    
    @objc func onTapUser(_ sender: UITapGestureRecognizer) {
        if let skuReview = self.skuReview {
            self.delegate?.didTapOnUser(skuReview.userName)
        }
    }
    
    @objc func moreReviewAction() {
        if let action = moreReviewHandler {
            action(self)
        }
    }
}
