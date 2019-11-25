//
//  BlackZoneProductBannerCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/16/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class BlackZoneProductBannerCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout  {
    
    
    static let MarginBottom:CGFloat = 10.0
    private var collectionView: UICollectionView!
    
    let MarginLeft = CGFloat(20)
    let Padding = CGFloat(7)
    
    static let CellIdentifier = "ProductBannerGroupCell"
    static let ItemPerRow = 2
    
    var delegate: ProductBannerGroupCellDelegate?
    
    var banner = Banner() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var currentIndex = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCollectionView()
        contentView.addSubview(collectionView)
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = ProductItemCell.itemSize(BlackZoneProductBannerCell.ItemPerRow)
        layout.minimumInteritemSpacing = 0
        
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.bounds.sizeWidth, height: self.bounds.sizeHeight), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(ProductItemCell.self, forCellWithReuseIdentifier: ProductItemCell.CellIdentifier)
        collectionView.register(BannerHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: BannerHeader.ReuseIdentifier)
        
        collectionView.isScrollEnabled = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.collectionView.frame = CGRect(x: 0, y: 0, width: frame.width, height: self.bounds.sizeHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    class func headerHeight(_ width: CGFloat) -> CGFloat {
        return 846.0 / 1242.0 * width
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return banner.skuList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: BannerHeader.ReuseIdentifier, for: indexPath)
        
        if let bannerView = view as? BannerHeader {
            bannerView.analyticsViewKey = self.analyticsViewKey
            bannerView.isBlackZonePage = true
            bannerView.setBanner(banner, index: currentIndex, delegate: delegate)
            bannerView.analyticsImpressionKey = bannerView.imageView.analyticsImpressionKey
        }
        
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductItemCell.CellIdentifier, for: indexPath) as! ProductItemCell
        let skuItem = banner.skuList[indexPath.row]
        cell.setSku(skuItem)
        
        guard let style = skuItem.style else {
            return cell
        }
        
        guard let viewKey = self.analyticsViewKey else { return cell }
        
        var skuCode = ""
        if let sku = style.findSkuBySkuId(skuItem.skuID) {
            skuCode = sku.skuCode
        }
        
        cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(nil, authorType: nil, brandCode: String(style.brandId),
            impressionRef: style.styleCode,
            impressionType: "Product",
            impressionVariantRef: skuCode,
            impressionDisplayName: style.skuName,
            merchantCode: style.merchantCode,
            parentRef: nil,
            parentType: nil,
            positionComponent: "ProductBanner",
            positionStringIndex: "\(self.currentIndex + 1)-\(indexPath.row + 1)",
            positionLocation: "Newsfeed-Home-BlackZone", referrerRef: nil, referrerType: nil, viewKey: viewKey))
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? ProductItemCell {
            cell.imageView.kf.cancelDownloadTask()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if let header = view as? BannerHeader {
            header.imageView.kf.cancelDownloadTask()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let style = banner.skuList[indexPath.item].style else { return }
        delegate?.didSelectProductItem(style)
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? ProductItemCell else { return }
        cell.recordAction(.Tap, sourceRef: style.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: frame.size.width, height: BlackZoneProductBannerCell.headerHeight(UIScreen.main.bounds.width))
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ProductItemCell.itemSize(BlackZoneProductBannerCell.ItemPerRow)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    class func getCellHeight(_ banner: Banner) -> CGFloat {
        let row = ceil(CGFloat(banner.skuList.count) / CGFloat(BlackZoneProductBannerCell.ItemPerRow))
        return row * ProductItemCell.itemSize(BlackZoneProductBannerCell.ItemPerRow).height + BlackZoneProductBannerCell.headerHeight(UIScreen.main.bounds.width) + 30
    }
}
