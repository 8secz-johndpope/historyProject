//
//  MerchantCouponCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/25/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol MerchantCouponDelegate: NSObjectProtocol {
    func clickOnCoupon(_ coupon: Coupon, cell: MerchantCouponCell, claimCompletion: (() -> Void)?)
    func viewAllCoupon()
}

class MerchantCouponCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    static let Size = CGSize(width: 90, height: 55)
    static let CmsSize = CGSize(width: 112, height: 64)
    static let Spacing = CGFloat(6)
    static let CellIdentifier = "MerchantCouponCell"
    static let ViewHeight = CGFloat(106)
    static let CmsViewHeight = CGFloat(64)
    var collectionView: UICollectionView!
    var datasouces = [Coupon]() {
        didSet {
            if targetType != .CMS {
                var mmCoupons = [Coupon]()
                mmCoupons = datasouces.filter { (coupon) -> Bool in
                    return coupon.isMmCoupon()
                }
                mmCoupons.sort(by: { $0.couponAmount > $1.couponAmount })
                
                var filterCoupons: [Coupon] = datasouces.filter { (coupon) -> Bool in
                    return coupon.merchantId != Constants.MMMerchantId
                }
                filterCoupons.sort(by: { $0.couponAmount > $1.couponAmount })
                
                datasouces.removeAll()
                datasouces = mmCoupons
                datasouces.append(contentsOf: filterCoupons)
            }
            
            self.collectionView.reloadData()
        }
    }
    var delegate: MerchantCouponDelegate?
    var claimedCoupon = [Coupon]() {
        didSet {
            for item in self.datasouces {
                if let _ = claimedCoupon.index(where: { $0.couponId == item.couponId }) {
                    item.isClaimed = true
                }
            }
            self.collectionView.reloadData()
        }
    }
    
    var leftLabel = UILabel()
    var rightLabel = UILabel()
    var iconImageView = UIImageView()
    var positionLocation = ""
    var targetType = AnalyticsActionRecord.ActionElement.PDP
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupCollectionView()
        self.contentView.addSubview(collectionView)
        
        leftLabel.applyFontSize(14, isBold: false)
        leftLabel.text = String.localize("LB_CA_CLAIM_MERCHANT_COUPON")
        leftLabel.textColor = UIColor.secondary2()
        self.contentView.addSubview(leftLabel)
        
        
        rightLabel.applyFontSize(14, isBold: false)
        rightLabel.text = String.localize("LB_MORE")
        rightLabel.textColor = UIColor.secondary2()
        rightLabel.textAlignment = .right
        rightLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MerchantCouponCell.viewAllCoupon)))
        rightLabel.isUserInteractionEnabled = true
        self.contentView.addSubview(rightLabel)
        
        iconImageView.image = UIImage(named: "filter_right_arrow")
        iconImageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(iconImageView)
        
        self.backgroundColor = UIColor.white
    }
    
    @objc func viewAllCoupon() {
        self.delegate?.viewAllCoupon()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelHeight = CGFloat(45)
        var width = StringHelper.getTextWidth(leftLabel.text ?? "", height: labelHeight, font: leftLabel.font)
        leftLabel.frame = CGRect(x: Margin.left, y: 0, width: bounds.size.width / 2, height: labelHeight)
        
        let iconSize = CGSize(width: 6, height: 24)
        
        width = StringHelper.getTextWidth(rightLabel.text ?? "", height: labelHeight, font: rightLabel.font)
        
        let margin = CGFloat(5)
        rightLabel.frame = CGRect(x: bounds.size.width -  Margin.left - width - iconSize.width - margin, y: 0, width: width, height: labelHeight)
        
        iconImageView.frame = CGRect(x: bounds.size.width -  Margin.left - iconSize.width, y: rightLabel.frame.midY - iconSize.height / 2 , width: iconSize.width, height: iconSize.height)
        
        collectionView.frame = CGRect(x: 0, y: leftLabel.frame.maxY, width: bounds.size.width, height: MerchantCouponCell.Size.height)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: MerchantCouponCell.Size.height)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: MerchantCouponCell.Size.height), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CMSCouponCell.self, forCellWithReuseIdentifier: CMSCouponCell.CellIdentifier)
        collectionView.register(CouponCell.self, forCellWithReuseIdentifier: CouponCell.CellIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Margin.left, bottom: 0, right: 0)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let coupon = datasouces[indexPath.row]
        
        if self.targetType == .CMS, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CMSCouponCell.CellIdentifier, for: indexPath) as? CMSCouponCell {
            cell.setData(coupon)
            return cell
        } else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CouponCell.CellIdentifier, for: indexPath) as? CouponCell {
            cell.setData(coupon)
            if let viewKey = self.analyticsViewKey {
                var impressionVariantRef = ""
                if let merchantId = coupon.merchantId {
                    impressionVariantRef = String(merchantId)
                }
                var merchantCode = ""
                if let merchant = CacheManager.sharedManager.cachedMerchantById(coupon.merchantId ?? 0) {
                    merchantCode = merchant.merchantCode
                }
                
                cell.initAnalytics(withViewKey: viewKey, impressionKey: AnalyticsManager.sharedManager.recordImpression(impressionRef: "\(coupon.couponReference)",
                    impressionType: "Coupon",
                    impressionVariantRef: impressionVariantRef,
                    impressionDisplayName: coupon.couponName,
                    merchantCode: merchantCode,
                    positionComponent: "CouponListing",
                    positionIndex: indexPath.row + 1,
                    positionLocation: positionLocation,
                    viewKey: viewKey))
            }
            return cell
        }
        
        return UICollectionViewCell()
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return MerchantCouponCell.Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if targetType == .CMS {
            return MerchantCouponCell.CmsSize
        }
        
        return MerchantCouponCell.Size
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasouces.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let coupon = datasouces[indexPath.row]
        delegate?.clickOnCoupon(coupon, cell: self, claimCompletion: {
            collectionView.reloadItems(at: [indexPath])
        })
        if let cell = collectionView.cellForItem(at: indexPath) as? CouponCell {
            cell.recordAction(.Tap, sourceRef: coupon.couponReference, sourceType: .Coupon, targetRef: coupon.couponName, targetType: targetType)
        }
    }


}


class CouponCell: UICollectionViewCell {

    enum ImageBackground: String {
        case mmActive = "coupon_small_mm_active",
        mmClaimed = "coupon_small_mm_claimed",
        merchantActive = "coupon_small_merchant_active",
        merchantClaimed = "coupon_small_merchant_claimed"
    }
    
    static let CellIdentifier = "CouponCell"
    
    var imageView = UIImageView()
    var coupon: Coupon?
    var amountLabel = UILabel()
    var thresholdLabel = UILabel()
    var conditionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(imageView)
        
        amountLabel.textAlignment = .center
        amountLabel.applyFontSize(14, isBold: true)
        amountLabel.escapeFontSubstitution = true
        self.contentView.addSubview(amountLabel)
        
        thresholdLabel.applyFontSize(10, isBold: false)
        thresholdLabel.textColor = UIColor.primary1()
        thresholdLabel.textAlignment = .center
        self.contentView.addSubview(thresholdLabel)
        
        conditionLabel.applyFontSize(8, isBold: false)
        conditionLabel.textColor = UIColor.primary1()
        conditionLabel.textAlignment = .center
        self.contentView.addSubview(conditionLabel)
    }
    
    func setData(_ data: Coupon) {

        self.coupon = data
        
        if data.isMmCoupon() {
            imageView.image = UIImage(named: data.isClaimed ? ImageBackground.mmClaimed.rawValue : ImageBackground.mmActive.rawValue)
        } else {
            imageView.image = UIImage(named: data.isClaimed ? ImageBackground.merchantClaimed.rawValue : ImageBackground.merchantActive.rawValue)
        }
        
        DispatchQueue.main.async {
            if let amount = data.couponAmount.formatPrice() {
                if amount.length > 0 {
                    let attString = NSMutableAttributedString(string: amount, attributes: [NSAttributedStringKey.foregroundColor : data.isClaimed ? UIColor.black : UIColor.primary1()])
                    attString.addAttributes([NSAttributedStringKey.font : UIFont.fontWithSize(9, isBold: false)], range: NSRange(location: 0, length: 1))
                    attString.addAttributes([NSAttributedStringKey.font : UIFont.fontWithSize(15, isBold: true)], range: NSRange(location: 1, length: amount.length - 1))
                    
                    self.amountLabel.attributedText = attString
                }
            }
        }
        
        thresholdLabel.textColor = data.isClaimed ? UIColor.gray : UIColor.primary1()
        thresholdLabel.text = String.localize("LB_CA_COUPON_DISCOUNT_FIXED_THRESHOLD_AMOUNT").replacingOccurrences(of: "{0}", with: data.minimumSpendAmount.formatPriceWithoutCurrencySymbol() ?? "")
        
        conditionLabel.textColor = data.isClaimed ? UIColor.gray : UIColor.primary1()
        conditionLabel.text = data.quickClaimDescription
        
        self.layoutSubviews()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        let margin = CGFloat(2)
        let labelHeight = CGFloat(14)
        
        amountLabel.frame = CGRect(x: margin, y: self.bounds.minY + 5, width: self.bounds.sizeWidth - 2 * margin, height: labelHeight)
        thresholdLabel.frame = CGRect(x: margin, y: amountLabel.frame.maxY + margin, width: self.bounds.sizeWidth - 2 * margin, height: labelHeight - 4)
        conditionLabel.frame = CGRect(x: margin, y: self.bounds.maxY - labelHeight - 1, width: self.bounds.sizeWidth - 2 * margin, height: labelHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class CMSCouponCell: UICollectionViewCell {
    
    static let CellIdentifier = "CMSCouponCell"
    
    private var imageView = UIImageView()
    private var claimedFlag = UIImageView()
    private var merchantIcon = UIImageView()
    var coupon: Coupon?
    private var amountLabel = UILabel()
    private var thresholdLabel = UILabel()
    private var actionLabel = UILabel()
    private var claimedArrow = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.image = UIImage(named: "coupon_small_red")
        self.contentView.addSubview(imageView)
        
        merchantIcon.backgroundColor = .white
        imageView.addSubview(merchantIcon)
        
        amountLabel.textAlignment = .left
        amountLabel.applyFontSize(24, isBold: true)
        amountLabel.textColor = .white
        amountLabel.escapeFontSubstitution = true
        self.contentView.addSubview(amountLabel)
        
        thresholdLabel.applyFontSize(10, isBold: false)
        thresholdLabel.textColor = .white
        thresholdLabel.textAlignment = .left
        self.contentView.addSubview(thresholdLabel)
        
        actionLabel.applyFontSize(8, isBold: false)
        actionLabel.textColor = .white
        actionLabel.textAlignment = .center
        self.contentView.addSubview(actionLabel)
        
        claimedArrow.image = UIImage(named: "coupon_small_claimed_arrow")
        self.contentView.addSubview(claimedArrow)
        
        claimedFlag.image = UIImage(named: "coupon_small_claimed_flag")
        self.contentView.addSubview(claimedFlag)
    }
    
    func setData(_ data: Coupon) {
        
        self.coupon = data
        
        if let brandId = data.segmentBrandId, brandId > 0, let brand = CacheManager.sharedManager.cachedBrandById(brandId) {
            merchantIcon.mm_setImageWithURL(
                ImageURLFactory.URLSize128(brand.headerLogoImage, category: .brand),
                placeholderImage: UIImage(named: "holder"),
                contentMode: .scaleAspectFit
            )
        } else if let merchantId = data.segmentMerchantId, merchantId > 0, let merchant = CacheManager.sharedManager.cachedMerchantById(merchantId) {
            merchantIcon.mm_setImageWithURL(
                ImageURLFactory.URLSize128(merchant.headerLogoImage, category: .merchant),
                placeholderImage: UIImage(named: "holder"),
                contentMode: .scaleAspectFit
            )
        } else if let merchantId = data.merchantId, merchantId != Constants.MMMerchantId, let merchant = CacheManager.sharedManager.cachedMerchantById(merchantId) {
            merchantIcon.mm_setImageWithURL(
                ImageURLFactory.URLSize128(merchant.headerLogoImage, category: .merchant),
                placeholderImage: UIImage(named: "holder"),
                contentMode: .scaleAspectFit
            )
        } else { merchantIcon.image = Merchant().MMIconCircle }
    
        if let amount = data.couponAmount.formatPrice() {
            if amount.length > 0 {
                let attString = NSMutableAttributedString(string: amount)
                attString.addAttributes([NSAttributedStringKey.font : UIFont.fontWithSize(9, isBold: false)], range: NSRange(location: 0, length: 1))
                attString.addAttributes([NSAttributedStringKey.font : UIFont.fontWithSize(15, isBold: true)], range: NSRange(location: 1, length: amount.length - 1))
                    
                self.amountLabel.attributedText = attString
            }
        }

        thresholdLabel.text = String.localize("LB_CA_COUPON_DISCOUNT_FIXED_THRESHOLD_AMOUNT").replacingOccurrences(of: "{0}", with: data.minimumSpendAmount.formatPriceWithoutCurrencySymbol() ?? "")
        
        actionLabel.text = String.localize(data.isClaimed ? "立即使用" : "LB_CA_INCENTIVE_REF_REFERRER_CLAIM")
        claimedFlag.isHidden = !data.isClaimed
        claimedArrow.isHidden = !data.isClaimed
        
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        let margin = CGFloat(2)
        let labelHeight = CGFloat(14)
        
        merchantIcon.frame = CGRect(x: 10, y: 7, width: 30, height: 30)
        merchantIcon.round()
        
        claimedFlag.sizeToFit()
        claimedFlag.frame = CGRect(x: self.imageView.frame.maxX - claimedFlag.frame.width, y: 0, width: claimedFlag.frame.size.width, height: claimedFlag.frame.size.height)
        
        let amountX = merchantIcon.frame.maxX + 8
        amountLabel.frame = CGRect(x: amountX, y: 5, width: self.bounds.sizeWidth - amountX, height: 22)
        
        let thresholdX = merchantIcon.frame.maxX + 12
        thresholdLabel.frame = CGRect(x: thresholdX, y: amountLabel.frame.maxY, width: self.bounds.sizeWidth - thresholdX, height: 8)
        
        actionLabel.frame = CGRect(x: self.bounds.center.x - (32/2), y: self.bounds.maxY - labelHeight - 1, width: 32, height: labelHeight)
        
        claimedArrow.sizeToFit()
        claimedArrow.frame = CGRect(x: actionLabel.frame.maxX + margin, y: actionLabel.centerY - (claimedArrow.frame.size.height/2), width: claimedArrow.frame.size.width, height: claimedArrow.frame.size.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
