//
//  ShoppingCartItemCell.swift
//  merchant-ios
//
//  Created by Alan YU on 5/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import SnapKit

class ShoppingCartItemCell: SwipeActionMenuCell {
    
    enum ProductStatus: Int {
        case normal
        case outOfStock
        case inactive
    }
    
    static let DefaultHeight: CGFloat = 150 // = containerTopPadding(16) + BrandImageHeight(28) + LabelHeight(18) * 5 + Constants.ActionButton.Height(26) + PaddingBottom (5)
    
    private var productImageView: UIImageView!
    private var productNameLabel: UILabel!
    private var productColorLabel: UILabel!
    private var productSizeLabel: UILabel!
    private var productQtyLabel: UILabel!
    private var productPriceLabel: UILabel!
    private var productSelectButton: UIButton!
    private var productEditButton: UIButton!
    private var brandNameLabel: UILabel!
    private var productStatusLabel: UILabel!
    private var separatorView: UIView!
    private var observerContext = 0
    private final let BrandImageHeight: CGFloat = 28
    private final let LabelHeight: CGFloat  = CGFloat(18)
    var productCellHandler: ((_ data: CartItem) -> Void)?
    var editHandler: ((_ data: CartItem) -> Void)?
    var cartItemSelectHandler: ((_ data: CartItem) -> Void)?
    private var productStatus: ProductStatus = .normal
    
    var data: CartItem? {
        didSet {
            if let data = self.data {
                self.productNameLabel.text = data.skuName

                let existOrEmpty = { (value: String?) -> String in
                    if value != nil {
                        return value!
                    }
                    return ""
                }
                
                productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + existOrEmpty(data.skuColor)
                productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + existOrEmpty(data.sizeName)
                
                //productColorLabel.isHidden = (data.colorId == 1)
                //productSizeLabel.isHidden = (data.sizeId == 1)
                
                self.productQtyLabel.text = String.localize("LB_CA_PI_QTY") + " : " + existOrEmpty(data.qty.formatQuantity())

                if let style = data.customStyle {
                    ProductManager.setProductImage(imageView: self.productImageView, style:style, colorKey: data.colorKey, placeholderImage: UIImage(named: "holder"))
                } else {
                    self.productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
                }
                
                self.brandNameLabel.text = data.brandName
                
                self.setCartItemSelected(data.selected)
                self.updatePriceLabel(cartItem: data)
                
                self.productStatus = getProductStatus(cartItem: data)
                switch productStatus {
                case .normal:
                    productSelectButton.isHidden = false
                    productStatusLabel.isHidden = true
                case .outOfStock:
                    productSelectButton.isHidden = true
                    productStatusLabel.isHidden = false
                    productStatusLabel.text = String.localize("LB_CA_CART_WISHLIST_OUTOFSTOCK")
                case .inactive:
                    productSelectButton.isHidden = true
                    productStatusLabel.isHidden = false
                    productStatusLabel.text = String.localize("LB_CA_CART_WISHLIST_OUTOFSTOCK")
                }
                
                productEditButton.isHidden = !data.isProductValid()
                
                layoutSubviews()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        /*
        ___________________
        |  |______________|
        |  |   |_C________|
        |A |B  |_D________|
        |  |   |_E________|
        |  |   |_F________|
        |  |___|_G________|
        |__|______________|
        */
        
        let separatorHeight = CGFloat(1)
        let contentHeight = ShoppingCartItemCell.DefaultHeight - separatorHeight
        let badgeHeight = CGFloat(50)
        let containerTopPadding = CGFloat(16)

        // A
        let checkBoxContainer = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: Constants.Checkbox.Size.width, height: self.frame.height - separatorHeight))
            
            let button = UIButton(type: .custom)
            button.config(
                normalImage: UIImage(named: "icon_checkbox_unchecked"),
                selectedImage: UIImage(named: "icon_checkbox_checked")
            )
            button.addTarget(self, action: #selector(ShoppingCartItemCell.toggleCartItemSelected), for: .touchUpInside)
            button.sizeToFit()
            button.frame = CGRect(x: (view.width - button.frame.width) / 2, y: (view.height - button.frame.height) / 2, width: button.frame.width, height: button.frame.height)
            
            view.addSubview(button)
            self.productSelectButton = button
            
            // Create Product Status Label in align middle of select button
            self.productStatusLabel = self.createProductStatusLabel(selectButton: productSelectButton)
            view.addSubview(self.productStatusLabel)
            
			let singleTap = UITapGestureRecognizer(target: self, action: #selector(ShoppingCartItemCell.toggleCartItemSelected))
			view.addGestureRecognizer(singleTap)

            return view
        } ()
        self.contentView.addSubview(checkBoxContainer)
        
        //
        let rightContainer = { () -> UIView in
            let containerHeight = (BrandImageHeight + LabelHeight * 5)
            
            let view = UIView(frame: CGRect(x: checkBoxContainer.frame.maxX, y: containerTopPadding, width: frame.width, height: containerHeight))
            
            // B
            let productImageContainerView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: ShoppingCartSectionMerchantImageWidth, height: containerHeight))

                let merchantImageRightPadding = CGFloat(20)
                
                let imageView = UIImageView(frame:
                    UIEdgeInsetsInsetRect(
                        view.bounds,
                        UIEdgeInsets(top: 0, left: 0, bottom: 0, right: merchantImageRightPadding)
                    )
                )

                view.addSubview(imageView)
                imageView.contentMode = .scaleAspectFit
                imageView.snp.makeConstraints { (target) in
                    target.top.equalTo(0)
                    target.bottom.equalTo(0)
                    target.left.equalTo(0)
                    target.right.equalTo(-5)
                    
                }
                
                
                self.productImageView = imageView
                
                return view
            } ()
            view.addSubview(productImageContainerView)
            
            //
            let detailWidth = view.frame.width - ShoppingCartSectionMerchantImageWidth
           
            
            let detailViewContainer = { () -> UIView in
                func formatFont(_ label: UILabel) {
                    label.textColor = UIColor.secondary2()
                    label.font = UIFont.systemFont(ofSize: 12)
                }
                
                let view = UIView(frame: CGRect(x: productImageContainerView.frame.maxX, y: 0, width: detailWidth, height: containerHeight))
                
                let brandNameLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: 0, width: detailWidth, height: LabelHeight))
                    formatFont(label)
                    label.formatSize(14)
                    return label
                } ()
                view.addSubview(brandNameLabel)
                self.brandNameLabel = brandNameLabel
                
                // C
                let productNameLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: brandNameLabel.frame.maxY, width: view.frame.width - brandNameLabel.frame.originY - 60, height: LabelHeight))
                    formatFont(label)
                    return label
                } ()
                view.addSubview(productNameLabel)
                self.productNameLabel = productNameLabel
                
                // D
                let colorLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: productNameLabel.frame.maxY, width: detailWidth, height: LabelHeight))
                    formatFont(label)
                    
                    return label
                } ()
                view.addSubview(colorLabel)
                self.productColorLabel = colorLabel
                
                
                // E
                let sizeLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: colorLabel.frame.maxY, width: detailWidth, height: LabelHeight))
                    formatFont(label)
                    
                    return label
                } ()
                view.addSubview(sizeLabel)
                self.productSizeLabel = sizeLabel
                
                // F
                let qtyLabel = { () -> UILabel in
                    
                    let label = UILabel(frame: CGRect(x: 0, y: sizeLabel.frame.maxY, width: detailWidth, height: LabelHeight))
                    formatFont(label)
                    
                    return label
                } ()
                view.addSubview(qtyLabel)
                self.productQtyLabel = qtyLabel
                
                // G
                let priceLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: 0, y: qtyLabel.frame.maxY, width: detailWidth, height: containerHeight - qtyLabel.frame.maxY))
                    label.escapeFontSubstitution = true
                    return label
                } ()
                view.addSubview(priceLabel)
                self.productPriceLabel = priceLabel
                
                return view
                
            } ()
            view.addSubview(detailViewContainer)
            
			let singleTap = UITapGestureRecognizer(target: self, action: #selector(ShoppingCartItemCell.productCellTapped))
			view.addGestureRecognizer(singleTap)

            return view
        } ()
        self.contentView.addSubview(rightContainer)
        
        //
        let editButton = { () -> UIButton in
            let rightMargin: CGFloat = 18
            let size = CGSize(width: 64, height: Constants.ActionButton.Height)
            let xPos = frame.width - size.width - rightMargin
            let yPos = rightContainer.frame.maxY - Constants.ActionButton.Height
            
            let frame = CGRect(x: xPos, y: yPos, width: size.width, height: size.height)
            let button = ActionButton(frame: frame, titleStyle: .highlighted)
            button.setTitle(String.localize("LB_CA_EDIT"), for: UIControlState())
            button.isHidden = true
            button.touchUpClosure = { _ in
                self.edit()
            }
            
            self.productEditButton = button
            self.productEditButton.accessibilityIdentifier = "cart_cell_edit_button"
            
            return button
        } ()
        self.contentView.addSubview(editButton)
        
        //
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: self.frame.height - separatorHeight, width: frame.width, height: separatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        } ()
        self.separatorView = separatorView
        self.contentView.addSubview(separatorView)
        
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var offsetY = productNameLabel.frame.maxY
        
        if !productColorLabel.isHidden {
            productColorLabel.y = offsetY
            offsetY += productColorLabel.height
        }
        
        if !productSizeLabel.isHidden {
            productSizeLabel.y = offsetY
            offsetY += productSizeLabel.height
        }
        
        productQtyLabel.y = offsetY
        
        self.separatorView.frame = CGRect(x: 0, y: self.frame.height - 1, width: frame.width, height: 1)
    }
    
    func getProductStatus(cartItem: CartItem) -> ProductStatus {
       
        if !cartItem.isProductValid() {
            return .inactive
        }
        
        if cartItem.isOutOfStock() {
            return .outOfStock
        }
        
        return .normal
    }
    
    
    @objc func toggleCartItemSelected() {
        if productStatus != .normal {
            return
        }
        
        if let value = self.data {
            self.setCartItemSelected(!value.selected)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let callback = self.cartItemSelectHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    private func setCartItemSelected(_ value: Bool) {
        self.data?.selected = value
        self.productSelectButton.isSelected = value
    }
    
    func edit() {
        if let callback = self.editHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    @objc func productCellTapped() {
        if let callback = self.productCellHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func accessibilityIdentifierIndex(_ index: Int) {
        accessibilityIdentifier = "ShoppingCartCell-\(index)"
        productQtyLabel.accessibilityIdentifier = "ShoppingCartCellQtyLabel-\(index)"
    }
    
    private func updatePriceLabel(cartItem: CartItem) {
        productPriceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: cartItem.priceRetail, salePrice: cartItem.priceSale, isSale: cartItem.isSale, retailPriceWithSaleFontColor: UIColor(hexString: "#757575"))
    }
    
    // Create product status label in middle of selected button, hidden by default
    
    private func createProductStatusLabel(selectButton: UIButton) -> UILabel {
        let statusLabel = UILabel(frame: CGRect(x: selectButton.frame.midX - 32/2, y: selectButton.frame.midY - 21/2, width: 32, height: 21))
        statusLabel.formatSize(12)
        statusLabel.textColor = UIColor.white
        statusLabel.backgroundColor = UIColor.secondary3()
        statusLabel.layer.cornerRadius = 2
        statusLabel.clipsToBounds = true
        statusLabel.textAlignment = NSTextAlignment.center
        statusLabel.isHidden = true
        
        return statusLabel
    }
}
