//
//  BaseCouponViewCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/22/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import Kingfisher
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class BaseCouponViewCell: UITableViewCell {
    let UnlimitedQuota = 999999999
    
    @IBOutlet weak var iconMerchant: UIImageView!
    @IBOutlet weak var lblAmount: UILabel!
    @IBOutlet weak var lblExpand: UILabel!
    @IBOutlet weak var lblThreshold: UILabel!
    @IBOutlet weak var lblCouponInfo: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var imgViewCouponState: UIImageView!
    @IBOutlet weak var imgViewBackground: UIImageView!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblCouponNote: UILabel!
    @IBOutlet weak var couponNoteContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var btnExpand: UIButton!
    
    @IBOutlet weak var iconMerchantCenter: NSLayoutConstraint!
    @IBOutlet weak var labelExpandCenter: NSLayoutConstraint!
    @IBOutlet weak var labelAmountCenter: NSLayoutConstraint!
//    @IBOutlet weak var labelThresholdCenter: NSLayoutConstraint!
    
    enum CouponState: Int {
        case none
        case new
        case inactive
    }
    
    var isActiveCoupon = true
    var data: Coupon?

    var buttonTapHandler: ((_ coupon: Coupon) -> ())? {
        didSet {
            let tapHandler = self.buttonTapHandler
            let handler: ((_ coupon: Coupon) -> ()) = { (coupon) in
                if LoginManager.isValidUser() {
                    tapHandler?(coupon)
                } else {
                    var bundle = QBundle()
                    bundle["mode"] = QValue(SignupMode.couponCenter.rawValue)
                    Navigator.shared.dopen(Navigator.mymm.website_login, params: bundle, modal: true)
                }
            }
            self.buttonTapHandler = handler
        }
    }
    var toggleExpandCollapseHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblThreshold.font = UIFont.fontRegularWithSize(11)
    }
    
    func fillData(_ coupon: Coupon, shouldShowMerchantName: Bool = true) {
        
        iconMerchant.round()
        
        let couponInfo = NSMutableAttributedString()
        if let merchantId = coupon.merchantId, shouldShowMerchantName {
            
            
            if let merchant = (merchantId == Constants.MMMerchantId ? Merchant.MM() : CacheManager.sharedManager.cachedMerchantById(merchantId)) {
                if merchantId == Constants.MMMerchantId {
                    iconMerchant.image = Merchant().MMIconCircle
                } else {
                    iconMerchant.mm_setImageWithURL(ImageURLFactory.URLSize128(merchant.largeLogoImage, category: ImageCategory.merchant), placeholderImage : UIImage(named: "holder"), contentMode: UIViewContentMode.scaleAspectFit)
                }
                
                var merchantName = ""
                if merchantId == Constants.MMMerchantId {
                    merchantName = String.localize("LB_CA_PROFILE_MY_COUPON_MYMM")
                } else if merchant.merchantName != "" {
                    merchantName = merchant.merchantName
                }

                couponInfo.append(NSAttributedString(string: merchantName + "\n"))
                couponInfo.addAttributes([NSAttributedStringKey.font : UIFont.fontRegularWithSize(13),
                                          NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.secondary2() : UIColor.secondary3()], range: NSRange(location: 0, length: merchantName.length))
            } else {
                iconMerchant.image = UIImage(named: "holder")
            }
        }
        
        couponInfo.append(NSAttributedString(string: coupon.couponName + "\n"))
        couponInfo.addAttributes([NSAttributedStringKey.font : UIFont.fontRegularWithSize(12), NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.secondary2() : UIColor.secondary3()], range: NSRange(location: couponInfo.length - coupon.couponName.length - 1, length: coupon.couponName.length))
        
        var couponDate = ""
        var couponExpire: String?
        var couponQuota: String?
        
        if let startDate = coupon.availableFrom, let endDate = coupon.availableTo {
            couponDate = Constants.DateFormatter.getFormatter(.dateOnlyWithDot).string(from: startDate) + "-" + Constants.DateFormatter.getFormatter(.dateOnlyWithDot).string(from: endDate)
            
            let timeInterval = endDate.timeIntervalSinceNow
            let differentDays = timeInterval / 86400
            
            if Date() < startDate as Date {
                couponExpire = String.localize("LB_CA_COUPON_YET_AVAIL")
            }
            else if differentDays < 5 && differentDays >= 1 {
                couponExpire = String.localize("LB_CA_COUPON_SOON_EXPIRED").replacingOccurrences(of: "{date}", with: "\(Int(differentDays))")
            }
            else if differentDays > 0 && differentDays < 1 {
                couponExpire = String.localize("LB_CA_COUPON_SOON_EXPIRED_1DAY")
            }
        } else if coupon.availableTo == nil {
            couponExpire = String.localize("LB_CA_COUPON_PERIOD_FOREVER")
        }
        
        if coupon.maximumUserRedemptionsCount == UnlimitedQuota {
            couponQuota = String.localize("LB_CA_COUPON_QUOTA_UNLIMITED")
        }
        else if coupon.maximumUserRedemptionsCount > 1 {
            couponQuota = String.localize("LB_CA_COUPON_QUOTA").replacingOccurrences(of: "{NoofQuotaLeft}", with: "\(coupon.remainingRedemptionCount())")
        }
        
        if couponDate != "" {
            couponInfo.append(NSAttributedString(string: couponDate + "\n"))
            couponInfo.addAttributes([NSAttributedStringKey.font : UIFont.fontRegularWithSize(12), NSAttributedStringKey.foregroundColor : UIColor.secondary3()], range: NSRange(location: couponInfo.length - couponDate.length - 1, length: couponDate.length))
        }
        
        if couponExpire != nil {
            couponInfo.append(NSAttributedString(string: couponExpire!))
            couponInfo.addAttributes([NSAttributedStringKey.font : UIFont.fontRegularWithSize(10), NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.red : UIColor.secondary3()], range: NSRange(location: couponInfo.length - couponExpire!.length, length: couponExpire!.length))
        }
        
        if couponQuota != nil {
            couponInfo.append(NSAttributedString(string: couponQuota!))
            couponInfo.addAttributes([NSAttributedStringKey.font : UIFont.fontRegularWithSize(10), NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.red : UIColor.secondary3()], range: NSRange(location: couponInfo.length - couponQuota!.length, length: couponQuota!.length))
        }
        
        if couponInfo.string.last == "\n" {
            couponInfo.deleteCharacters(in: NSRange(location: couponInfo.length - 1, length: 1))
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        couponInfo.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: couponInfo.length))
        
        lblCouponInfo.attributedText = couponInfo
        
        if let amount = coupon.couponAmount.formatPrice() {
            var fixedAmount = amount
            
            let numberOfCommas = min(max(amount.components(separatedBy: ",").count - 1, 0), 2)
            
            if coupon.couponAmount >= 10000 {
                // ¥xx,xxx without .
                var maxLength: Int!
                if #available(iOS 10, *) {
                    maxLength = 6 + numberOfCommas
                }
                else {
                    maxLength = 7 + numberOfCommas
                }
                if amount.length > maxLength {
                    fixedAmount = amount[0..<maxLength] + "..."
                }
            }
            else if coupon.couponAmount >= 1000 {
                // ¥x,xxx.x
                var maxLength: Int!
                if #available(iOS 10, *) {
                    maxLength = 7 + numberOfCommas
                }
                else {
                    maxLength = 8 + numberOfCommas
                }
                
                if amount.length > maxLength {
                    fixedAmount = amount[0..<maxLength] + "..."
                }
            }
            
            let attString = NSMutableAttributedString(string: fixedAmount)
            attString.addAttributes([NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.red : UIColor.secondary3(), NSAttributedStringKey.font : UIFont.fontRegularWithSize(14)], range: NSRange(location: 0, length: 1))
            attString.addAttributes([NSAttributedStringKey.foregroundColor : isActiveCoupon ? UIColor.red : UIColor.secondary3(), NSAttributedStringKey.font : UIFont.fontRegularWithSize(24)], range: NSRange(location: 1, length: fixedAmount.length - 1))
            lblAmount.attributedText = attString
            
            let thresholdAmount = String.localize("LB_CA_COUPON_DISCOUNT_FIXED_THRESHOLD_AMOUNT").replacingOccurrences(of: "{0}", with: coupon.minimumSpendAmount.formatPriceWithoutCurrencySymbol() ?? "")
            lblThreshold.text = thresholdAmount
            lblThreshold.textColor = UIColor.secondary3()
        }
    }
    
    func expand(_ expand: Bool) {
        if let coupon = data {
            if coupon.isSegmented == 1, let _ = CouponManager.shareManager().getCouponRemarkWith(coupon.segmentMerchantId, brandId: coupon.segmentBrandId, categoryId: coupon.segmentCategoryId) {
                let segmentString = String.localize("LB_CA_COUPON_SEGMENT")
                let attString = NSMutableAttributedString(string: segmentString, attributes: [NSAttributedStringKey.font : UIFont.fontRegularWithSize(11), NSAttributedStringKey.foregroundColor : UIColor.secondary3()])
                
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(x: 0, y: 0, width: 8, height: 5)
                if expand {
                    attachment.image = UIImage(named: "Triangle_red")
                }
                else {
                    attachment.image = UIImage(named: "Triangle_grey")
                }
                
                attString.append(NSAttributedString(string: " "))
                attString.append(NSAttributedString(attachment: attachment))
                
                lblExpand.attributedText = attString
                
                lblExpand.isHidden = false
                btnExpand.isHidden = false
                iconMerchantCenter.constant = -10
                labelAmountCenter.constant = -24
//                labelThresholdCenter.constant = 0
                labelExpandCenter.constant = 20
            }
            else {
                lblExpand.isHidden = true
                btnExpand.isHidden = true
                labelAmountCenter.constant = -24
                iconMerchantCenter.constant = 0
//                labelThresholdCenter.constant = 10
            }
        }
    }

    func setCouponState(_ state: CouponState) {
        switch state {
        case .none:
            imgViewCouponState.isHidden = true
            
        case .new:
            imgViewCouponState.isHidden = false
            imgViewCouponState.image = UIImage(named: "label_coupon_new")
            
        case .inactive:
            imgViewCouponState.isHidden = false
            imgViewCouponState.image = UIImage(named: "label_coupon_notEffective")
        }
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        if let coupon = data {
            buttonTapHandler?(coupon)
        }
    }
}
