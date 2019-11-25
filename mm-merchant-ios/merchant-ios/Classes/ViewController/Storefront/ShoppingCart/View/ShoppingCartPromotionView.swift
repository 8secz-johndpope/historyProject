//
//  ShoppingCartPromotionCell.swift
//  merchant-ios
//
//  Created by Alan YU on 6/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Foundation

protocol ShoppingCartPromotionViewDelegate: NSObjectProtocol {
    func didSelectBanner(_ banner: Banner)
}

class ShoppingCartPromotionView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, BannerCellDelegate {
    
    var promotionIcon: UIImageView?!
    var promotionTextLabel: UILabel!
    var promotionTextField: UITextField!
    var promotionTextFieldImage: UIImageView!
    var bannerCollectionView : UICollectionView!
    
    let bannerRatio = CGFloat(100.0 / 375.0)
    let LowerViewHeight = CGFloat(0)
    
    weak var delegate: ShoppingCartPromotionViewDelegate?
    
    var cartBannerList = [Banner]() {
        didSet {
            if self.cartBannerList.count > 0 {
                self.bannerCollectionView.reloadData()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        // upper - config banner collection view
        setupBannerCollectionView()
        self.addSubview(bannerCollectionView)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: self.bannerCollectionView.frame.maxY + LowerViewHeight)
        
        self.disableScrollToTop()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Collection View
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.CellIdentifier, for: indexPath) as! BannerCell
        
        if let analyticsViewKey = self.analyticsViewKey {
            cell.initAnalytics(withViewKey: analyticsViewKey)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        cell.delegate = self
        cell.bannerList = self.cartBannerList
        cell.positionLocation = "Cart"
        cell.isShoppingCartBanner = true
        cell.disableScrollToTop()
        cell.showOverlay(false)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return bannerCollectionView.frame.size
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Turn off the timer to avoid crashing if banner cell is disappeared
        if let bannerCell = cell as? BannerCell {
            bannerCell.isAutoScroll = false
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointerOrTypeMismatch)
        }
    }
    
    // MARK: - Banner Cell Delegate
    
    func didSelectBanner(_ banner: Banner) {
        delegate?.didSelectBanner(banner)
    }
    
    // MARK: - Helper
    
    private func setupBannerCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        bannerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width * self.bannerRatio), collectionViewLayout: layout)
        bannerCollectionView.dataSource = self
        bannerCollectionView.delegate = self
        bannerCollectionView.alwaysBounceVertical = false
        bannerCollectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.CellIdentifier)
        bannerCollectionView.backgroundColor = UIColor.white
    }
    
}
