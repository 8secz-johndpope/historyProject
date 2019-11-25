//
//  StyleCouponCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/8.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

protocol StyleCouponDelegate: NSObjectProtocol {
    func clickOnCoupon(_ coupon: Coupon, cell: StyleCouponCell, claimCompletion: (() -> Void)?)

}
class StyleCouponCell: UICollectionViewCell,UICollectionViewDelegate,UICollectionViewDataSource {
    static public let CellIdentifier = "StyleCouponCell"
    static public let CellHeight: CGFloat = 68
    public var datasouces = [Coupon]() {
        didSet {
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
            
            self.collectionView.reloadData()
        }
    }
    public var claimedCoupon = [Coupon]() {
        didSet {
            for item in self.datasouces {
                if let _ = claimedCoupon.index(where: { $0.couponId == item.couponId }) {
                    item.isClaimed = true
                }
            }
            self.collectionView.reloadData()
        }
    }
    static public let Size = CGSize(width: 90, height: 40)
    static public let ViewHeight = CGFloat(68)
    public var delegate: StyleCouponDelegate?
    public var positionLocation = ""
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
      
        self.contentView.addSubview(collectionView)
        self.contentView.addSubview(leftLabel)
        self.leftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(15)
            make.centerY.equalTo(self.contentView)
            make.width.equalTo(49)
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    //MARK: - UICollectionViewDataSoure & UICollectionViewDelegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datasouces.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StyleCouponContentCell", for: indexPath) as? StyleCouponContentCell {
            let coupon = datasouces[indexPath.row]
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let coupon = datasouces[indexPath.row]
        delegate?.clickOnCoupon(coupon, cell: self, claimCompletion: {
            collectionView.reloadItems(at: [indexPath])
        })
        if let cell = collectionView.cellForItem(at: indexPath) as? StyleCouponContentCell {
            cell.recordAction(.Tap, sourceRef: coupon.couponReference, sourceType: .Coupon, targetRef: coupon.couponName, targetType: .PDP)
        }
    }
    
    //MARK: - lazy
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 4
        layout.itemSize = CGSize(width: StyleCouponCell.Size.width, height: StyleCouponCell.Size.height)
        
        let collectionView = UICollectionView(frame: CGRect(x: 49.0, y: 14.0, width: frame.width - 49.0, height: StyleCouponCell.Size.height), collectionViewLayout: layout)
        collectionView.register(StyleCouponContentCell.self, forCellWithReuseIdentifier: "StyleCouponContentCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    lazy var leftLabel: UILabel = {
        let leftLabel = UILabel()
        leftLabel.font = UIFont.systemFont(ofSize: 12)
        leftLabel.textColor = UIColor(hexString: "#999999")
        leftLabel.textAlignment = .left
        leftLabel.text = String.localize("LB_CA_CART_MERC_COUPON_LIST")
        return leftLabel
    }()
}

class StyleCouponContentCell: UICollectionViewCell {
    public func setData(_ data: Coupon) {
        backgroundImageView.image = UIImage(named: data.isClaimed ? "coupon2" : "coupon1")
        bottomLabel.text = data.isClaimed ? String.localize("LB_CA_COUPON_CLAIMED") : String.localize("LB_CA_PDP_COUPON_CLICK_CLAIM")
        
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let minimumSpendAmount = formatter.string(from: NSNumber(value: data.minimumSpendAmount))?.replacingOccurrences(of: ".00", with: ""),let couponAmount = formatter.string(from: NSNumber(value: data.couponAmount))?.replacingOccurrences(of: ".00", with: "") {
             topLabel.text = String.localize("满{0}减").replacingOccurrences(of: "{0}", with: minimumSpendAmount) + couponAmount
        }
       
    }
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(backgroundImageView)
        self.contentView.addSubview(topLabel)
        self.contentView.addSubview(bottomLabel)
        
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        topLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.top.equalTo(self.contentView).offset(5)
        }
        bottomLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-6)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - lazy
    lazy private var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.image = UIImage(named: "coupon1")
        return backgroundImageView
    }()
    lazy private var topLabel: UILabel = {
        let topLabel = UILabel()
        topLabel.font = UIFont.systemFont(ofSize: 12)
        topLabel.textColor = .white
        topLabel.textAlignment = .center
        return topLabel
    }()
    lazy private var bottomLabel: UILabel = {
        let bottomLabel = UILabel()
        bottomLabel.font = UIFont.systemFont(ofSize: 8)
        bottomLabel.textColor = .white
        bottomLabel.textAlignment = .center
        return bottomLabel
    }()
}
