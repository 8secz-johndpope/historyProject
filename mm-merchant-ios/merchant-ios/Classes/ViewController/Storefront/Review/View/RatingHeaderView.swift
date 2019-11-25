//
//  RatingHeader.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Cosmos //Rating View

protocol RatingHeaderViewDelegate: NSObjectProtocol {
    func didSelectReviewHeader()
}

class RatingHeaderView: UICollectionReusableView {
    
    static let ViewIdentifier = "RatingHeaderViewID"
    static let DefaultHeight: CGFloat = 56
    
    private final let ArrowSize = CGSize(width: 6, height: 24)
    private final let TotalTitleLabelSize = CGSize(width: 60, height: 25)
    private final let RatingViewSize = CGSize(width: 85, height: 14)
    private final let TotalValueSize = CGSize(width: 50, height: 25)
    private final let TotalCommentLabelHeight: CGFloat = 32
    
    var contentView: UIView!
    var ratingView: CosmosView!
    var totalTitleLabel: UILabel!
    var totalValueLabel: UILabel!
    var totalCommentLabel: UILabel!
    var disclosureIndicatorImageView: UIImageView?
    
    weak var delegate: RatingHeaderViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.primary2()
        
        let containerView = { () -> UIView in
            
            let topPadding: CGFloat = 6
            let rightPadding: CGFloat = Margin.left
            let view = UIView(frame: CGRect(x: 0, y: topPadding, width: frame.width, height: frame.height - topPadding))
            view.backgroundColor = UIColor.white
            
            self.totalTitleLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: rightPadding, y: (view.frame.sizeHeight - TotalTitleLabelSize.height) / 2, width: self.TotalTitleLabelSize.width, height: self.TotalTitleLabelSize.height))
                label.adjustsFontSizeToFitWidth = true
                label.formatSmall()
                return label
                } ()
            
            self.totalTitleLabel.text = String.localize("LB_CA_PROD_REVIEW")
            view.addSubview(self.totalTitleLabel)
            
            let showReviewButton = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
                button.backgroundColor = UIColor.clear
                button.addTarget(self, action: #selector(RatingHeaderView.headerTapped), for: .touchUpInside)
                return button
            } ()
            view.addSubview(showReviewButton)
            
            self.ratingView = CosmosView()
            self.ratingView.settings.minTouchRating = 1
            self.ratingView.settings.totalStars = 5
            self.ratingView.settings.starSize = 14.0
            self.ratingView.settings.fillMode = .full
            self.ratingView.settings.starMargin = 4.0
            self.ratingView.text = ""
            self.ratingView.clipsToBounds = true
            self.ratingView.settings.filledColor = UIColor(hexString: "#f5a623")
            //only set frame rating view after all setting because CosmosView update frame itself automatically
            self.ratingView.frame = CGRect(x: self.totalTitleLabel.frame.maxX + rightPadding, y: (view.frame.sizeHeight - self.RatingViewSize.height) / 2, width: self.RatingViewSize.width, height: self.RatingViewSize.height)
            view.addSubview(ratingView)
            
            self.totalValueLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: self.ratingView.frame.maxX + rightPadding, y: (view.frame.sizeHeight - TotalValueSize.height) / 2, width: self.TotalValueSize.width, height: self.TotalValueSize.height))
                label.adjustsFontSizeToFitWidth = true
                label.formatSize(11)
                label.textColor = UIColor.secondary3()
                return label
                } ()
            
            totalValueLabel.text = ""
            view.addSubview(self.totalValueLabel)
            
            let arrowView = { () -> UIImageView in
                let imageView = UIImageView(frame: CGRect(x: view.frame.width - self.ArrowSize.width - Margin.left, y: (view.frame.sizeHeight - ArrowSize.height) / 2, width: ArrowSize.width, height: ArrowSize.height))
                imageView.image = UIImage(named: "filter_right_arrow")
                imageView.contentMode = .scaleAspectFit
                imageView.isHidden = false
                return imageView
            } ()
            
            disclosureIndicatorImageView = arrowView
            view.addSubview(disclosureIndicatorImageView!)
            
            totalCommentLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: totalValueLabel.frame.maxX, y: (view.frame.sizeHeight - TotalCommentLabelHeight) / 2, width: arrowView.frame.originX - totalValueLabel.frame.maxX - 5, height: self.TotalCommentLabelHeight))
                label.adjustsFontSizeToFitWidth = true
                label.formatSize(14)
                label.textAlignment = .right
                label.textColor = UIColor.secondary3()
                return label
                } ()
            view.addSubview(totalCommentLabel)
            
            let separatorHeight = Constants.Separator.DefaultThickness
            let separatorView = { () -> UIView in
                let view = UIView(frame: CGRect(x: Margin.left, y: view.frame.height - separatorHeight, width: frame.width - 2 * Margin.left, height: separatorHeight))
                view.backgroundColor = Constants.Separator.DefaultColor
                return view
            } ()
            view.addSubview(separatorView)

            return view
            
        } ()
        
        contentView = containerView
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let paddingLeft: CGFloat = 0
        
        contentView.frame.originX = paddingLeft
        contentView.frame.sizeWidth = contentView.frame.sizeWidth - paddingLeft
        
        disclosureIndicatorImageView?.frame.originX = contentView.frame.sizeWidth - ArrowSize.width - Margin.left
    }
    
    //MARK: - View
    func showDisclosureIndicator(_ isShow: Bool) {
        if let disclosureIndicatorImageView = self.disclosureIndicatorImageView {
            disclosureIndicatorImageView.isHidden = !isShow
        }
    }
    
    //MARK: - Action
    @objc func headerTapped() {
        recordAction(.Tap, sourceRef: "AllReviews", sourceType: .Button, targetRef: "AllReviews", targetType: .View)
        
        delegate?.didSelectReviewHeader()
    }
    
}
