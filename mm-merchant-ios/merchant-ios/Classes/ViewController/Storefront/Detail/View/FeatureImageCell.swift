//
//  ImageDefaultCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class FeatureImageCell: UICollectionViewCell {
    
    private let BadgeImageSize = CGSize(width: ScreenWidth / 7.0, height: ScreenWidth / 7.0)
    var featureCollectionView: UICollectionView!
    var heartImageView = UIImageView()
    var badgeImageView = UIImageView()
    var pageControl = UIPageControl()
    
    var wishTapHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        clipsToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        featureCollectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        featureCollectionView.backgroundColor = UIColor.white
        featureCollectionView.showsHorizontalScrollIndicator = false
        featureCollectionView.isPagingEnabled = true
        addSubview(featureCollectionView)
        
        heartImageView.image = UIImage(named: "star_nav")
        heartImageView.contentMode = .scaleAspectFit
        addSubview(heartImageView)
    
        //Default Hide
        badgeImageView.isHidden = true
        badgeImageView.backgroundColor = UIColor.clear
        addSubview(badgeImageView)
        
        pageControl.numberOfPages = 5
        pageControl.currentPage = 0
        pageControl.tintColor = UIColor.black
        pageControl.pageIndicatorTintColor = UIColor.primary2()
        pageControl.currentPageIndicatorTintColor = UIColor.primary1()
        addSubview(pageControl)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 5
        let sizeOfHeartImageView = Constants.FaviorIconSize

        heartImageView.frame = CGRect(x: bounds.maxX - sizeOfHeartImageView.width - margin, y: bounds.maxY - sizeOfHeartImageView.height - margin, width: sizeOfHeartImageView.width, height: sizeOfHeartImageView.height)
        pageControl.frame = CGRect(x: bounds.midX - 40, y: bounds.maxY - 20, width: 80, height: 20)
        
        badgeImageView.frame = CGRect(x: margin + 4, y: margin + 44 + 8, width: BadgeImageSize.width, height: BadgeImageSize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setBadgeImage(_ imageKey: String) {
         badgeImageView.mm_setImageWithURL(ImageURLFactory.get(imageKey, isForProductList: false), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
    }
}
