//
//  CMSPageCouponCell.swift
//  storefront-ios
//
//  Created by Kam on 12/6/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit

class CMSPageCouponCell: MerchantCouponCell {
    
    var cellModel: CMSPageCouponCellModel?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel = model as? CMSPageCouponCellModel {
            self.delegate = cellModel.delegate
            self.cellModel = cellModel
            
            when(fulfilled: concatCoupons(), claimedCoupons()).then { [weak self] coupons, responseClaimedCounpon -> Void in
                if let strongSelf = self {
                    if let cmsCoupons = coupons {
                        strongSelf.datasouces = cmsCoupons
                    }
                    if let claimedCoupons = responseClaimedCounpon.coupons {
                        strongSelf.claimedCoupon = claimedCoupons.filter { $0.isRedeemable }
                    }
                    strongSelf.layoutSubviews()
                }
                }.catch { (error) in
                    Log.error("error")
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.targetType = .CMS
    }
    
    override func layoutSubviews() {
        leftLabel.isHidden = true
        rightLabel.isHidden = true
        iconImageView.isHidden = true
        
        collectionView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: cellModel?.cellHeight ?? 0)
    }
    
    private func concatCoupons() -> Promise<[Coupon]?> {
        return Promise<[Coupon]?> { fulfill, reject in
            var coupons = [Coupon]()
            if let model = self.cellModel, let datas = model.data {
                for data in datas {
                    if let coupon = data.coupon {
                        coupons.append(coupon)
                    }
                }
                fulfill(coupons)
            } else {
                reject(NSError(domain: "CMSCoupon", code: -1, userInfo: ["reason": "no data"]))
            }
        }
    }
    
    private func claimedCoupons() -> Promise<CouponResult> {
        if LoginManager.isValidUser() {
            return CouponManager.shareManager().wallet(forMerchantId: CouponMerchant.combine.rawValue)
        } else {
            return Promise<CouponResult> { fulfill, reject in
                fulfill((merchantId: -1, coupons: []))
            }
        }
    }
}
