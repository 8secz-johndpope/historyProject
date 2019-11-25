//
//  RatingCollectionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Cosmos

protocol RatingCellDelegate: NSObjectProtocol {
    func didTouchRatingView()
    func didFinishTouchingRatingView()
}

class RatingCollectionCell: UICollectionViewCell {
    
    static let DefaultHeight: CGFloat = 65
    static let CellIdentifier = "RatingCollectionCellID"
    
    weak var delegate: RatingCellDelegate?
    var ratingView = CosmosView()
    var triangleUpImageView = UIImageView()
    
    private var borderView = UIView()
    
    var data: ReviewData? {
        didSet {
            if let data = self.data {
                ratingView.rating = Double(data.ratingValue)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        triangleUpImageView.image = UIImage(named: "icon_triangleUp")
        addSubview(triangleUpImageView)
        addSubview(borderView)
        addSubview(ratingView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        triangleUpImageView.frame = CGRect(x: frame.width/2 - 27/2, y: -12, width: 27, height: 13)
        
        ratingView.frame = CGRect(x: frame.width/2 - 275/2 + 55, y: frame.height/2 - 15, width: 275, height: frame.height/2)
        ratingView.settings.starSize = Constants.Value.RatingStarWidth
        ratingView.settings.totalStars = 5
        ratingView.settings.starMargin = Constants.Value.RatingStarMargin
        ratingView.settings.fillMode = .full
        ratingView.settings.filledColor = UIColor.ratingStar()
        ratingView.settings.minTouchRating = 1
        ratingView.didTouchCosmos = didTouchRatingView
        ratingView.didFinishTouchingCosmos = didFinishTouchingRatingView
        
        borderView.frame = CGRect(x: 10, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
        borderView.backgroundColor = UIColor.secondary1()
    }
    
    private func didTouchRatingView(_ rating: Double) {
        if let data = self.data {
            data.ratingValue = Int(rating)
            delegate?.didTouchRatingView()
        }
    }
    
    private func didFinishTouchingRatingView(_ rating: Double) {
        if let data = self.data {
            data.ratingValue = Int(rating)
            delegate?.didFinishTouchingRatingView()
        }
    }
}
