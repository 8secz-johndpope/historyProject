//
//  MagazineCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/16/16.
//  Copyright © 2016 Quang Truong Dinh. All rights reserved.
//

import UIKit

protocol MagazinecellDelegate: NSObjectProtocol {
    
    func handleLikeAction(isLike islike: Bool, sender: UIButton)
    
}
class MagazineCell: UICollectionViewCell {
    
    static let CellIdentifier = "MagazineCellId"
    
    private final let TitleMinHeight: CGFloat = 34
    private final let TitleMaxHeight: CGFloat = 68
	private final let TitleFontBaseSize: CGFloat = 12
    private final let CategoryMinHeight: CGFloat = 17
    private final let CategoryMaxHeight: CGFloat = 17
    private final let CategoryWidth: CGFloat = 60
    private final let CategoryRedLineWidth: CGFloat = 36
    private final let TitleVerticalMargin: CGFloat = 15
    private final let LabelVerticalMargin: CGFloat = 35
    private final let TitlePadding: CGFloat = 30
    private final let LikeButtonWidth: CGFloat = 28
    private final let LikeButtonHeight: CGFloat = 25
    private final let LikeViewWidth: CGFloat = 50
    
    var backgroundImageView: UIImageView!
    var imageCoverView: UIView!
    var categoryView: UIView!
    var categoryLabel: UILabel!
    var titleLabel: UILabel!
    var likeView: UIView!
    var likeCountLabel: UILabel!
    var overlayView: UIView!
    var likeButton: ButtonRedDot!
    var backgroundImageOffset: CGPoint!
    var foregroundImageOffset: CGPoint!
    
    private var leftRedLine: UIImageView!
    private var rightRedLine: UIImageView!
    
    var isLikeButtonSelected: Bool = false
    
    var completionLikeHandler: ((_ isLike: Bool) -> ())?
    weak var delegate: MagazinecellDelegate?
    
    var likeCount = 0
    var backgroundImage: UIImage! {
        didSet {
            self.backgroundImageView.image = backgroundImage
            setBackgroundImageOffset(backgroundImageOffset)
        }
    }
    
    var magazine: MagazineCover? {
        didSet {
            if let magazine = magazine {
                leftRedLine.isHidden = magazine.category.isEmpty
                rightRedLine.isHidden = magazine.category.isEmpty
                categoryLabel.isHidden = magazine.category.isEmpty
//                categoryLabel.text = "Category"
                titleLabel.text = magazine.contentPageName
                likeButton.isSelected = magazine.isLike
                likeCount = magazine.likeCount
                likeCountLabel.text = String(format: "%d", likeCount)
            }
        }
    }
    
    var contentPageCollection: ContentPageCollection? {
        didSet {
            if let contentPageCollection = contentPageCollection {
                leftRedLine.isHidden = true
                rightRedLine.isHidden = true
                titleLabel.text = contentPageCollection.contentPageCollectionName
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupBackgroundImageView()
        addSubview(backgroundImageView)
        
        overlayView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = 0.3
        addSubview(overlayView)
        
        categoryView = UIView(frame: CGRect(x: 0, y: (3/4) * frame.height - TitleMinHeight / 2 - MagazineCollectionViewLayoutConstants.Cell.standardHeight / 4, width: frame.width, height: CategoryMinHeight))
        
        leftRedLine = UIImageView(frame: CGRect(x: frame.width / 2 - CategoryWidth / 2 - CategoryRedLineWidth - 10, y: CategoryMinHeight / 2 - 1, width: CategoryRedLineWidth, height: 1))
        leftRedLine.image = UIImage(named: "magazine_red_line")
        categoryView.addSubview(leftRedLine)
        
        rightRedLine = UIImageView(frame: CGRect(x: frame.width / 2 + CategoryWidth / 2 + 10, y: CategoryMinHeight / 2 - 1, width: CategoryRedLineWidth, height: 1))

        rightRedLine.image = UIImage(named: "magazine_red_line")
        categoryView.addSubview(rightRedLine)
        
        categoryLabel = UILabel(frame: CGRect(x: frame.width / 2 - CategoryWidth / 2, y: 0, width: CategoryWidth, height: CategoryMinHeight))
        categoryLabel.formatSize(14)
        categoryLabel.textColor = UIColor.white
        categoryLabel.textAlignment = .center
        categoryView.addSubview(categoryLabel)
        
        titleLabel = UILabel(frame: CGRect(x: TitlePadding / 2, y: (3/4) * frame.height - TitleMinHeight / 2, width: frame.width - TitlePadding, height: TitleMinHeight))
		titleLabel.numberOfLines = 2
		titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.formatSize(Int(TitleFontBaseSize))
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = NSTextAlignment.center		
        
        addSubview(categoryView)
        addSubview(titleLabel)
        
        titleLabel.isHidden = false
        
        likeView = UIView(frame: CGRect(x: self.bounds.width - LikeViewWidth - 10, y: frame.height - MagazineCollectionViewLayoutConstants.Cell.standardHeight / 4 - LikeButtonHeight / 4, width: LikeViewWidth, height: LikeButtonHeight))
        likeButton = ButtonRedDot(type: .custom)
        likeButton.imageEdgeInsets = UIEdgeInsets(top: LikeButtonHeight / 4, left: LikeButtonWidth / 4, bottom: LikeButtonHeight / 4, right: LikeButtonWidth / 4)
        likeButton.setImage(UIImage(named: "heart"), for: UIControlState())
        likeButton.setImage(UIImage(named: "icon_heart_filled"), for: .selected)
        likeButton.frame = CGRect(x: 0, y: 0, width: LikeButtonWidth, height: LikeButtonHeight)
        likeButton.addTarget(self, action: #selector(MagazineCell.likeButtonTapped), for: .touchUpInside)
        
        likeCountLabel = UILabel(frame: CGRect(x: LikeButtonWidth, y: 0, width: LikeViewWidth - LikeButtonWidth, height: LikeButtonHeight))
        likeCountLabel.formatSize(12)
        
        likeCountLabel.textAlignment = NSTextAlignment.right
        likeCountLabel.textColor = UIColor.white
        likeView.addSubview(likeCountLabel)
        
        likeView.addSubview(likeButton)
        addSubview(likeView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundImageView?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        setBackgroundImageOffset(backgroundImageOffset)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        let featuredHeight = MagazineCollectionViewLayoutConstants.Cell.featuredHeight
        let standardHeight = MagazineCollectionViewLayoutConstants.Cell.standardHeight
        
        let delta = 1 - ((featuredHeight - frame.height) / (featuredHeight - standardHeight))
        
        let scale = max(delta, 0.5)
        titleLabel.frame = CGRect(x: TitlePadding / 2, y: (3/4) * frame.height - TitleMinHeight / 2, width: frame.width - TitlePadding, height: TitleMinHeight + (TitleMaxHeight - TitleMinHeight) * scale)
        titleLabel.formatSizeInFloat(TitleFontBaseSize + (25.0 - TitleFontBaseSize) * delta)
        
        categoryLabel.formatSize(14)
        
        categoryView.frame = CGRect(x: 0, y: (3/4) * frame.height - TitleMinHeight / 2 - MagazineCollectionViewLayoutConstants.Cell.standardHeight / 4, width: frame.width, height: TitleMinHeight)
        
        titleLabel.textColor = UIColor.white
        categoryLabel.textColor = UIColor.white
        
        likeView.frame = CGRect(x: frame.width - LikeViewWidth - 10, y: frame.height - MagazineCollectionViewLayoutConstants.Cell.standardHeight / 4 - LikeButtonHeight / 4, width: LikeViewWidth, height: LikeButtonHeight)
        
        overlayView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
    
    private func setupBackgroundImageView() {
        backgroundImageOffset = CGPoint.zero
        self.clipsToBounds = true
        backgroundImageView = UIImageView(frame: CGRect.zero)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = false
        addSubview(backgroundImageView)
    }
    
    private func setBackgroundImageOffset(_ imageOffset: CGPoint) {
        backgroundImageOffset = imageOffset
        backgroundImageView.frame = backgroundImageView.bounds.offsetBy(dx: backgroundImageOffset.x, dy: backgroundImageOffset.y)
    }
    
    func showLikeView(_ show: Bool) {
        likeView.isHidden = !show
    }
    
    // MARK - Actions
    
    @objc func likeButtonTapped(_ sender: UIButton) {
        if let tappedButton = sender as? ButtonRedDot{
            if tappedButton == self.likeButton{
                if tappedButton.isSelected {
                    
                    if likeCount > 0 {
                        tappedButton.isSelected = false
                        self.magazine?.isLike = false
                        likeCount = likeCount - 1
                        likeCountLabel.text = String(format: "%d", likeCount)
                        
                        if let delegate = self.delegate {
                            delegate.handleLikeAction(isLike: false, sender: sender)
                        }
                    }
                    
                    
                } else {
                    let wishListAnimation = WishListAnimation(heartImage: UIImageView(), redDotButton: tappedButton)
                    wishListAnimation.showAnimation(completion: {
                        
                        
                        tappedButton.isSelected = true
                        self.magazine?.isLike = true
                        self.likeCount = self.likeCount + 1
                        self.likeCountLabel.text = String(format: "%d", self.likeCount)
                        if let delegate = self.delegate {
                            delegate.handleLikeAction(isLike: true, sender: sender)
                        }

                    })
                }
            }
        }
    }
}
