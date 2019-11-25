//
//  ProductBannerGroupCell.swift
//  merchant-ios
//
//  Created by Tony Fung on 26/4/2017.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit


protocol ProductBannerGroupCellDelegate: NSObjectProtocol {
    func didSelectProductBanner(_ banner: Banner)
    func didSelectProductItem(_ style: Style)
}

class ProductItemCell: UICollectionViewCell {
    static let CellIdentifier = "ProductBannerItemCell"
    var skuItem : SkuItem!
    
    var imageView = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        
        nameLabel.formatSize(13)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        addSubview(nameLabel)
        
        priceLabel.formatSize(16)
//        priceLabel.font = saleFont
        priceLabel.textAlignment = .center
        priceLabel.escapeFontSubstitution = true
        addSubview(priceLabel)
        
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSku(_ sku: SkuItem) {
        
        self.skuItem = sku
        guard let style = skuItem.style else {
            self.imageView.image = UIImage(named: "brand_placeholder")
            self.nameLabel.text = ""
            self.priceLabel.text = ""
            return 
        }
        
        if let customImageKey = skuItem.productImageKey {
            self.imageView.mm_setImageWithURL(ImageURLFactory.URLSize512(customImageKey, category: .product), placeholderImage: UIImage(named: "brand_placeholder"), contentMode: .scaleAspectFill)
        } else {
            ProductManager.setProductImage(imageView: self.imageView, style: style, colorKey: style.defaultSku()?.colorKey ?? "" , placeholderImage: UIImage(named: "brand_placeholder"), completion: { (image, error) -> Void in
                if image != nil { self.imageView.backgroundColor = UIColor.clear }
            })
        }
        
        self.nameLabel.text = style.brandName
        self.priceLabel.attributedText = PriceHelper.fillPrice(style.priceSale, priceRetail: style.priceRetail, isSale: style.isOnSale() ? 1: 0)
        
        self.nameLabel.applyFontSize(13, isBold: true)
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = self.bounds.width - 6
        let height = 134 / 115 * width
        imageView.frame = CGRect(x: 3, y: 6, width: width, height: height)
        
        nameLabel.frame = CGRect(x: bounds.minX + 5 , y: imageView.frame.maxY + 4, width: bounds.width - 10 , height: 20)
        priceLabel.frame = CGRect(x: bounds.minX, y: nameLabel.frame.maxY , width: bounds.width, height: 20)
        
    }
    
 
    class func itemSize(_ countPerRow: Int) -> CGSize {
        let cellWidth = UIScreen.main.bounds.sizeWidth / CGFloat(countPerRow)
        let imageWidth = cellWidth - 6
        var height = 134 / 115 * imageWidth
        height +=  55
        return CGSize(width: cellWidth, height: height)
    }
    
}


class BannerHeader : UICollectionReusableView {
    static let ReuseIdentifier = "BannerHeader"
    var imageView = UIImageView()
    private var banner : Banner?
    private weak var delegate : ProductBannerGroupCellDelegate?
    var isBlackZonePage = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(contentsOfFile: "holder")
        imageView.contentMode = .scaleAspectFill
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didSelectBanner)))
        self.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }
    
    func setBanner(_ banner : Banner, index: Int, delegate: ProductBannerGroupCellDelegate?) {
        self.banner = banner
        self.imageView.tag = index
        self.setImage(banner.bannerImage, imageView: imageView, banner: banner)
        self.layoutSubviews()
        self.delegate = delegate
    }
    
    @objc private func didSelectBanner(_ gesture : UITapGestureRecognizer) {
        guard let banner = banner else { return }
        if let bannerHeader = gesture.view as? BannerHeader {
            bannerHeader.recordAction(.Tap, sourceRef: "\(banner.bannerName)", sourceType: .ProductBanner, targetRef: banner.link, targetType: .URL)
        }
        
        delegate?.didSelectProductBanner(banner)
    }
    
    private func setImage(_ imageKey : String, imageView: UIImageView, banner: Banner) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey, category: .banner), placeholderImage: UIImage(named: "postPlaceholder"), contentMode: .scaleAspectFill)
        
        if let viewKey = self.analyticsViewKey {
            imageView.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(banner.bannerKey)", impressionType: "Banner",
                impressionVariantRef: isBlackZonePage ? "BlackZone" : "RedZone",
                impressionDisplayName: "\(banner.bannerName)",
                positionComponent: "ProductBanner",
                positionIndex: (imageView.tag + 1),
                positionStringIndex: "\(imageView.tag + 1)-0",
                positionLocation: isBlackZonePage ? "Newsfeed-Home-BlackZone" : "Newsfeed-Home-RedZone", viewKey: viewKey))
        }
    }
    
    

    
}

class ProductBannerGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    static let MarginBottom:CGFloat = 10.0
    private var collectionView: UICollectionView!
    
    let MarginLeft = CGFloat(20)
    let Padding = CGFloat(7)

    static private let rowHeight = 100
    

    static let CellIdentifier = "ProductBannerGroupCell"
    var itemPerRow = 3
    
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
        layout.itemSize = ProductItemCell.itemSize(banner.itemPerRow())
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
        return 185.0 / 375.0 * width
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return banner.skuList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: BannerHeader.ReuseIdentifier, for: indexPath)
            
        if let bannerView = view as? BannerHeader {
            if let analyticsViewKey = self.analyticsViewKey {
                bannerView.analyticsViewKey = analyticsViewKey
            }
            bannerView.isBlackZonePage = false
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
        var merchantCode = ""
        if let merchant = CacheManager.sharedManager.cachedMerchantById(style.merchantId) {
            merchantCode = merchant.merchantCode
        }
        
        cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(nil, authorType: nil,
            brandCode: String(style.brandId),
            impressionRef: style.styleCode,
            impressionType: "Product",
            impressionVariantRef: skuCode,
            impressionDisplayName: style.skuName,
            merchantCode: style.merchantCode.length > 0 ? style.merchantCode : merchantCode,
            parentRef: nil,
            parentType: nil,
            positionComponent: "ProductBanner",
            positionStringIndex: "\(self.currentIndex + 1)-\(indexPath.row + 1)",
            positionLocation: "Newsfeed-Home-RedZone", referrerRef: nil, referrerType: nil, viewKey: viewKey))
        
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
     
        return CGSize(width: frame.size.width, height: ProductBannerGroupCell.headerHeight(UIScreen.main.bounds.width))
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ProductItemCell.itemSize(banner.itemPerRow())
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    class func getCellHeight(_ banner: Banner) -> CGFloat {
        let row = ceil(CGFloat(banner.skuList.count) / CGFloat(banner.itemPerRow()))
        return row * ProductItemCell.itemSize(banner.itemPerRow()).height + ProductBannerGroupCell.headerHeight(UIScreen.main.bounds.width) + 30
    }
}
