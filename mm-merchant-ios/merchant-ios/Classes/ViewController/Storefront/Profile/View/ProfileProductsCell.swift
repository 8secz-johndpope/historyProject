//
//  ProfileProductsCell.swift
//  merchant-ios
//
//  Created by HungPM on 4/26/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class ProfileProductsCell: UICollectionViewCell {
    
    static let HeaderHeight = CGFloat(82)
    
    enum Index: Int {
        case CART
        case ORDER
        case COUPON
        case WISHLIST
    }
    
    private let ImageSize = CGSize(width: 25, height: 25)
    private var badgeLabel: UIView!
    private var redDotCoupon: UIView!
    private var redDotWishlist: UIView!
    
    var actionTapHandler: ((Int) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        
        let width = ceil(frame.width / 4)
        for index in 0 ..< 4 {
            let viewContainer = UIView(frame: CGRect(x: width * CGFloat(index), y: 0, width: width, height: ProfileProductsCell.HeaderHeight))
            viewContainer.tag = index
            viewContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(actionTap)))
            contentView.addSubview(viewContainer)
            
            let imageView = UIImageView(frame: CGRect(x: (viewContainer.width - ImageSize.width) / 2, y: (viewContainer.height - ImageSize.height) / 2 - 10, width: ImageSize.width, height: ImageSize.height))
            imageView.contentMode = .scaleAspectFit
            viewContainer.addSubview(imageView)
            let margin = CGFloat(8)
            
            let label = UILabel(frame: CGRect(x: 0, y: imageView.frame.maxY + margin, width: viewContainer.width, height: 20))
            label.textAlignment = .center
            label.formatSize(12)
            viewContainer.addSubview(label)
            
            switch index {
            case Index.CART.rawValue:
                imageView.image = UIImage(named: "profile_bag")
                label.text = String.localize("LB_CA_CART")
                
                let badgeWidth = CGFloat(15)
                badgeLabel = UIView(frame: CGRect(x:imageView.frame.maxX - 2, y: imageView.frame.minY - 5, width: badgeWidth, height: badgeWidth))
                badgeLabel.backgroundColor = UIColor.primary1()
                badgeLabel.layer.cornerRadius = badgeWidth / 2
                badgeLabel.isHidden = true
                viewContainer.addSubview(badgeLabel)
                
                let padding = CGFloat(2)
                let label = UILabel(frame: CGRect(x: padding, y: padding, width: badgeWidth - padding * 2, height: badgeWidth - padding * 2))
                label.textColor = .white
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 11)
                label.tag = 100
                badgeLabel.addSubview(label)
                
            case Index.ORDER.rawValue:
                imageView.image = UIImage(named: "myprofile_btn2")
                label.text = String.localize("LB_CA_MY_ORDERS")
                
            case Index.COUPON.rawValue:
                imageView.image = UIImage(named: "myprofile_btn3")
                label.text = String.localize("LB_COUPON")
                
                redDotCoupon = UIView(frame: CGRect(x: imageView.frame.maxX, y: imageView.frame.minY, width: 6, height: 6))
                redDotCoupon.backgroundColor = UIColor.primary1()
                redDotCoupon.round()
                redDotCoupon.isHidden = true
                viewContainer.addSubview(redDotCoupon)
                
            case Index.WISHLIST.rawValue:
                imageView.image = UIImage(named: "star_profile")
                label.text = String.localize("LB_CA_PROFILE_COLLECTION")
                
                redDotWishlist = UIView(frame: CGRect(x: imageView.frame.maxX, y: imageView.frame.minY, width: 6, height: 6))
                redDotWishlist.backgroundColor = UIColor.primary1()
                redDotWishlist.round()
                redDotWishlist.isHidden = true
                viewContainer.addSubview(redDotWishlist)
                
            default:
                break
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func actionTap(tapGesture: UITapGestureRecognizer) {
        if let tag = tapGesture.view?.tag {
            actionTapHandler?(tag)
        }
    }
    
    func showCartBadge(show: Bool, number: Int? = nil) {
        if let number = number, let label = badgeLabel.viewWithTag(100) as? UILabel, show {
            badgeLabel.isHidden = false
            
            let text = number > 99 ? "99+" : "\(number)"
            var textWidth = StringHelper.getTextWidth(text, height: label.height, font: label.font)
            if textWidth < badgeLabel.layer.cornerRadius * 2 - 4 {
                textWidth = badgeLabel.layer.cornerRadius * 2 - 4
            }
            
            badgeLabel.width = textWidth + 4
            label.width = textWidth
            label.text = text
        }
        else {
            badgeLabel.isHidden = true
        }
    }
    
    func showCouponRedDot(show: Bool) {
        redDotCoupon.isHidden = !show
    }
    
    func showWishlistRedDot(show: Bool) {
        redDotWishlist.isHidden = !show
    }
    
}
