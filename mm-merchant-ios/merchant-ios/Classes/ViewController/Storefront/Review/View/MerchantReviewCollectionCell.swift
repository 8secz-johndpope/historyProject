//
//  MerchantReviewCollectionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Cosmos

protocol MerchantReviewCellDelegate: NSObjectProtocol {
    func didTouchMerchantRatingView()
    func didFinishTouchingMerchantRatingView()
}

class MerchantReviewCollectionCell: UICollectionViewCell {
    
    private enum RatingViewTag: Int {
        case productDescription = 1000
        case service = 1001
        case logistics = 1002
    }
    
    static let DefaultHeight: CGFloat = 370
    static let CellIdentifier = "MerchantReviewCollectionCellID"
    
    private final let PaddingContent: CGFloat = 22
    private final let ActionButtonWidth: CGFloat = 90
    private final let ActionButtonHeight: CGFloat = 45
    
    var orderActionButtonView = UIView()
    var merchantImageView: UIImageView!
    weak var delegate:MerchantReviewCellDelegate?
    
    private let ratingTitles = [
        ["name" : String.localize("LB_CA_PROD_DESC"), "image" : "shopRating1"],
        ["name" : String.localize("LB_CA_CUST_SERVICE"), "image" : "shopRating2"],
        ["name" : String.localize("LB_CA_SHIPMENT_RATING"), "image" : "shopRating3"]
    ]
    
    var data: MerchantReviewData? {
        didSet {
            if let data = self.data {
                if let imageKey = data.order?.headerLogoImage {
                    _ = self.merchantImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .merchant), placeholderImage: UIImage(named: "im_order_brand"), contentMode: .scaleAspectFit)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        let titleWidth: CGFloat = 80
        let titleHeight: CGFloat = 25
        let topMargin: CGFloat = 15
        let redLineWidth: CGFloat = 36
        
        let titleLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.width / 2 - 40, y: topMargin, width: titleWidth, height: titleHeight))
            label.formatSize(18)
            label.textAlignment = .center
            label.text = String.localize("LB_CA_OMS_MERC_RATE")
            return label
        }()
        addSubview(titleLabel)
        
        let leftRedLine = UIImageView(frame: CGRect(x: frame.width / 2 - titleWidth / 2 - redLineWidth - 10, y: topMargin + titleHeight / 2 - 1, width: redLineWidth, height: 1))
        leftRedLine.image = UIImage(named: "magazine_red_line")
        addSubview(leftRedLine)
        
        let rightRedLine = UIImageView(frame: CGRect(x: frame.width / 2 + titleWidth / 2 + 10, y: topMargin + titleHeight / 2 - 1, width: redLineWidth, height: 1))
        rightRedLine.image = UIImage(named: "magazine_red_line")
        addSubview(rightRedLine)
        
        merchantImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: frame.width/2 - 45, y: 55, width: 90, height: 35))
            imageView.backgroundColor = UIColor.clear
            return imageView
        }()
        addSubview(merchantImageView)
        
        let merchantRateNoteLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.width/2 - 100, y: 105, width: 200, height: 25))
            label.formatSize(18)
            label.textAlignment = .center
            label.text = String.localize("LB_AC_OMS_MERC_RATE_NOTE")
            return label
        }()
        addSubview(merchantRateNoteLabel)
        
        var index = 0
        for ratingTitle in self.ratingTitles{
            let ratingView = RatingView(frame: CGRect(x: frame.width / 2 - 275 / 2, y: 145 + 65 * CGFloat(index), width: 275, height: 65), title: ratingTitle["name"], image: ratingTitle["image"])
            
            //Start from 1000 to avoid default value of tag
            ratingView.tag = 1000 + index
            index += 1
            addSubview(ratingView)
            
            ratingView.ratingHandler = { (ratingValue: Double, isFinished: Bool) -> Void in
                if let data = self.data {
                    if let ratingValueTag = RatingViewTag(rawValue: ratingView.tag) {
                        let rating = Int(ratingView.ratingView.rating)
                        
                        switch ratingValueTag {
                        case .productDescription:
                            data.productDescriptionRating = rating
                        case .logistics:
                            data.logisticsRating = rating
                        case .service:
                            data.serviceRating = rating
                        }
                    }
                }
                if isFinished {
                    self.delegate?.didFinishTouchingMerchantRatingView()
                }else {
                    self.delegate?.didTouchMerchantRatingView()
                }
            }
        }
        
        orderActionButtonView.frame = CGRect(x: 0, y: self.bounds.midY - (ActionButtonHeight / 2), width: frame.size.width, height: ActionButtonHeight)
        contentView.addSubview(orderActionButtonView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

internal class RatingView: UIView {
    
    var shopRatingImageView: UIImageView!
    var ratingView: CosmosView!
    var ratingHandler: ((_ ratingValue: Double, _ isFinished: Bool) -> Void)?
    
    init(frame: CGRect, title: String?, image: String?) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        shopRatingImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: 15, y: (frame.height - 80) / 2 + 10, width: 30, height: 30))
            imageView.backgroundColor = UIColor.clear
            imageView.image = UIImage(named: image!)
            return imageView
        }()
        addSubview(shopRatingImageView)
        
        let ratingTitleLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 0, y: (frame.height - 80) / 2 + 30, width: 60, height: 40))
            label.formatSize(15)
            label.textAlignment = .center
            label.text = title
            return label
        }()
        
        addSubview(ratingTitleLabel)
        let starSize = Constants.Value.RatingStarWidth
        ratingView = CosmosView()
        ratingView.clipsToBounds = true
        ratingView.settings.starSize = Double(starSize)
        ratingView.settings.starMargin = Constants.Value.RatingStarMargin
        ratingView.settings.totalStars = 5
        ratingView.settings.fillMode = .full
        ratingView.settings.filledColor = UIColor.ratingStar()
        ratingView.settings.minTouchRating = 1
        ratingView.rating = 5.0
        ratingView.didTouchCosmos = didTouchRatingView
        ratingView.didFinishTouchingCosmos = didFinishTouchingRatingView
        ratingView.frame = CGRect(x: 85, y: self.frame.height/2 - CGFloat(starSize)/2, width: self.frame.width - 85, height: CGFloat(starSize))
        addSubview(ratingView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didTouchRatingView(_ rating: Double) {
        ratingView.update()
        self.ratingHandler?(rating, false)
        
        
    }
    
    private func didFinishTouchingRatingView(_ rating: Double) {
        ratingView.update()
        self.ratingHandler?(rating, true)
    }
}
