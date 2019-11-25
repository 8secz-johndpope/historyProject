//
//  ShoppingCartSectionHeaderView.swift
//  merchant-ios
//
//  Created by Alan YU on 7/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

let ShoppingCartSectionMerchantImageWidth = CGFloat(100 / Constants.Ratio.ProductImageHeight)
let ShoppingCartSectionArrowWidth = CGFloat(64)

class ShoppingCartSectionHeaderView: UICollectionReusableView {
    
    static let ViewIdentifier = "ShoppingCartSectionHeaderViewID"
    static let DefaultHeight: CGFloat = 44
    
    var selectAllCartItemButton: UIButton!
    var merchantImageView: UIImageView!
    var merchantNameLabel: UILabel!
    var cartItemSelectHandler: ((_ data: ShoppingCartSectionData) -> Void)?
    
    var headerTappedHandler: ((_ data: ShoppingCartSectionData) -> Void)?

    var viewCouponHandler: ((_ merchant: CartMerchant) -> Void)?
    
    var data: ShoppingCartSectionData? {
        didSet {
            if let data = self.data {
                self.allCartItemSelected = data.sectionSelected
                
                if let merchantImageKey = self.data?.merchant?.merchantImage {
                    self.merchantImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(merchantImageKey, category: .merchant), placeholderImage: UIImage(named: "holder"), clipsToBounds: true, contentMode: .scaleAspectFit)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                merchantNameLabel.text = self.data?.merchant?.merchantName
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    private var allCartItemSelected = false {
        didSet {
            self.selectAllCartItemButton.isSelected = self.allCartItemSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.backgroundGray()
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        let containerView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
            view.backgroundColor = UIColor.white
            
            let merchantNameWidth = view.bounds.width - Constants.Checkbox.Size.width - ShoppingCartSectionMerchantImageWidth - ShoppingCartSectionArrowWidth
            
            //
            let checkBoxContainer = { () -> UIView in
                let view = CenterLayoutView(frame: CGRect(x: 0, y: 0, width: Constants.Checkbox.Size.width, height: frame.height))
                
                let button = UIButton(type: .custom)
                button.config(
                    normalImage: UIImage(named: "icon_checkbox_unchecked"),
                    selectedImage: UIImage(named: "icon_checkbox_checked")
                )
                button.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
                button.imageView?.sizeToFit()
                button.addTarget(self, action: #selector(ShoppingCartSectionHeaderView.toggleSelectAllCartItems), for: .touchUpInside)
                
                view.addSubview(button)
                self.selectAllCartItemButton = button
                
                return view
            } ()
            view.addSubview(checkBoxContainer)
            
            //
            let merchantImageConatinerView = { () -> UIView in
                let view = UIView(frame: CGRect(x: checkBoxContainer.frame.maxX, y: 0, width: ShoppingCartSectionMerchantImageWidth, height: frame.height))
                
                let merchantImageTopPadding = CGFloat(8)
                let merchantImageLeftPadding = CGFloat(10)
                let merchantImageRightPadding = CGFloat(20)
                
                let imageView = UIImageView(frame: UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsets(top: merchantImageTopPadding, left: merchantImageLeftPadding, bottom: merchantImageTopPadding, right: merchantImageRightPadding)))
                
                imageView.contentMode = .scaleAspectFit
                
                view.addSubview(imageView)
                self.merchantImageView = imageView
                
                return view
            } ()
            view.addSubview(merchantImageConatinerView)
            
            //
            self.merchantNameLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: merchantImageConatinerView.frame.maxX, y: 0, width: merchantNameWidth, height: frame.height))
                label.formatSmall()
                label.adjustsFontSizeToFitWidth = false
                label.lineBreakMode = NSLineBreakMode.byTruncatingTail
                label.numberOfLines = 1
                return label
            } ()
            view.addSubview(self.merchantNameLabel)
            
            // clear button cover from Merchant image to right arrow. Tap to go to the Merchant Public Profile Page
            let clearButton = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: merchantImageConatinerView.frame.minX, y: 0, width: frame.width - merchantImageConatinerView.frame.minX, height: frame.height)
                button.backgroundColor = UIColor.clear
                button.addTarget(self, action: #selector(ShoppingCartSectionHeaderView.headerTapped), for: .touchUpInside)
                return button
            } ()
            view.addSubview(clearButton)
            
            //
            let couponButtonView = { () -> UIButton in
                let couponButtonWidth = CGFloat(55)

                let button = UIButton(type: .custom)
                button.setTitle(String.localize("LB_CA_CART_MERC_COUPON_LIST"), for: UIControlState())
                button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
                button.setTitleColor(UIColor.primary1(), for: UIControlState())
                button.frame = CGRect(x: frame.width - couponButtonWidth, y: 0, width: couponButtonWidth, height: frame.height)
                button.addTarget(self, action: #selector(ShoppingCartSectionHeaderView.showMerchantCouponList), for: .touchUpInside)
                return button
            } ()
            view.addSubview(couponButtonView)
            
            let separatorHeight = CGFloat(1)
            let separatorView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: self.merchantNameLabel.frame.maxY - separatorHeight, width: frame.width, height: separatorHeight))
                view.backgroundColor = UIColor.backgroundGray()
                
                return view
            } ()
            view.addSubview(separatorView)

            return view
        } ()
        self.addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleSelectAllCartItems(_ button: UIButton) {
        allCartItemSelected = !allCartItemSelected
        
        if let callback = self.cartItemSelectHandler {
            if let data = self.data {
                for row in data.dataSource {
                    (row as! CartItem).selected = self.allCartItemSelected
                }
                
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    @objc func showMerchantCouponList() {
        if let merchant = data?.merchant {
            viewCouponHandler?(merchant)
        }
    }
    
    @objc func headerTapped() {
        if let callback = self.headerTappedHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }

}
