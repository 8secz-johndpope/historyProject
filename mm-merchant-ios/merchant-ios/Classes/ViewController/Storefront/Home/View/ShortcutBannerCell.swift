//
//  ShortcutBannerCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 4/20/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol ShortcutBannerCellDelegate: NSObjectProtocol {
    func didSelectBanner(_ banner: Banner)
}

class ShortcutBannerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    private final let DefaultSupplementaryViewID = "DefaultSupplementaryView"
    static let CellIdentifier = "ShortcutBannerCell"
    private final let shortcutBackgroundColor = UIColor(hexString: "#F9F9F9")
    static let MarginBottom:CGFloat = 10.0
    static let HeightFooterView: CGFloat = 24.0
    static let HeightHeaderView: CGFloat = 24.0
    private var collectionView: UICollectionView!
    let MarginLeft = CGFloat(20)
    let Padding = CGFloat(12)
    static let ItemPerRow = 4
    static let CellHeight = CGFloat(76)
    static let Margin = CGFloat(10)
    var delegate: ShortcutBannerCellDelegate?
    var itemPerRow = 4
    
    var isBlackZonePage = true
    
    var datasources = [Banner]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        setupCollectionView()
        contentView.addSubview(collectionView)
    }
    
    // MARK: Views
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: self.bounds.sizeHeight), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        collectionView.register(ShortcutCell.self, forCellWithReuseIdentifier: ShortcutCell.CellIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DefaultSupplementaryViewID)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: DefaultSupplementaryViewID)
        collectionView.isScrollEnabled = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = CGRect(x: 0, y: 0, width: frame.width, height: self.bounds.sizeHeight)
        if isBlackZonePage {
            collectionView.backgroundColor = shortcutBackgroundColor
        } else {
            collectionView.backgroundColor = UIColor.white
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datasources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShortcutCell.CellIdentifier, for: indexPath) as! ShortcutCell
        let banner = self.datasources[indexPath.row]
        cell.banner = banner
        cell.setImage(banner.bannerImage, banner: banner, index: indexPath.row)
        
        if let analyticsViewKey = self.analyticsViewKey {
            let impressionKey = AnalyticsManager.sharedManager.recordImpression(
                brandCode: nil,
                impressionRef: "\(banner.bannerKey)",
                impressionType: "Banner",
                impressionVariantRef: isBlackZonePage ? "BlackZone" : "RedZone",
                impressionDisplayName: isBlackZonePage ? "b\(indexPath.row + 1)" : "r\(indexPath.row + 1)",
                positionComponent: "ShortcutBanner",
                positionIndex: indexPath.row + 1,
                positionLocation: isBlackZonePage ? "Newsfeed-Home-BlackZone" : "Newsfeed-Home-RedZone",
                viewKey: analyticsViewKey)
            cell.initAnalytics(withViewKey: analyticsViewKey, impressionKey: impressionKey)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let banner = self.datasources[indexPath.row]
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.recordAction(.Tap, sourceRef: isBlackZonePage ? "b\(indexPath.row + 1)" : "r\(indexPath.row + 1)", sourceType: .ShortcutBanner, targetRef: banner.link, targetType: .URL)
        }
        delegate?.didSelectBanner(banner)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.bounds.sizeWidth / CGFloat(self.itemPerRow), height: ShortcutBannerCell.CellHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: DefaultSupplementaryViewID, for: indexPath)
        if kind == UICollectionElementKindSectionHeader {
            supplementaryView.backgroundColor = shortcutBackgroundColor
        } else {
            supplementaryView.backgroundColor = UIColor.white
        }
        
        return supplementaryView
    }
    
    class func getCellHeight(_ datasources: [Banner], itemPerRow: Int, isBlackZone: Bool) -> CGFloat {
        let row = ceil(CGFloat(datasources.count) / CGFloat(itemPerRow))
        return (CGFloat(row) * ShortcutBannerCell.CellHeight) - (isBlackZone ? 0 : 1)
    }

}
