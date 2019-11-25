//
//  OrderItemCell.swift
//  merchant-ios
//
//  Created by Alan YU on 5/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderItemCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderItemCellID"
    static let DefaultHeight: CGFloat = 115
    
    private final let PaddingContent: CGFloat = 10
    private final let DetailLabelHeight: CGFloat = 18
    private final let VerticalPadding: CGFloat = 5
    
    private var productImageView: UIImageView!
    var productNameLabel: UILabel!
    var productColorLabel: UILabel!
    var productSizeLabel: UILabel!
    var afterSaleQuantityLabel: UILabel!
    var productPriceLabel: UILabel!
    var productQtyLabel: UILabel!
    var bottomBorderView: UIView!
    private var priceAndQtyView: UIView!
    
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
    var viewMode: Constants.OmsViewMode = .all
    
    var skuReview: SkuReview? {
        didSet {
            if let data = skuReview {
                self.setReviewData(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    var data: OrderItem? {
        didSet {
            if let data = self.data {
                productNameLabel.text = data.skuName
                
                let existOrEmpty = { (value: String?) -> String in
                    return (value != nil && value != "") ? value! : "---"
                }
                
                productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + existOrEmpty(data.colorName)
                productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + existOrEmpty(data.sizeName)
                
                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: nil)
                
                let priceText = NSMutableAttributedString()
                let saleFont = UIFont.systemFont(ofSize: 14)
                let unitPrice = data.unitPrice
                
                let locale = Locale(identifier: "zh_Hans_CN")
                let currencySymbol = (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as! String
                
                if let price = unitPrice.formatPrice(currencySymbol: currencySymbol) {
                    let attributedString = NSAttributedString(
                        string: price,
                        attributes: [
                            NSAttributedStringKey.foregroundColor: UIColor.secondary2(),
                            NSAttributedStringKey.font: saleFont
                        ]
                    )
                    
                    priceText.append(attributedString)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                productPriceLabel.attributedText = priceText
                
                switch orderDisplayStatus {
                case .toBeShipped, .orderClosed, .partialShip:
                    productQtyLabel.text = "X" + existOrEmpty(data.qtyOrdered.formatQuantity())
                case .shipped, .received, .collected, .toBeCollected:
                    productQtyLabel.text = "X" + existOrEmpty(data.qtyShipped.formatQuantity())
                case .cancelRequested, .cancelAccepted, .cancelRejected, .refundAccepted:
                    var qty = 0
                    
                    if viewMode == .afterSales {
                        qty = data.qtyCancelled
                    } else {
                        qty = data.qtyCancelled + data.qtyCancelRequested
                    }
                    
                    productQtyLabel.text = "X" + existOrEmpty(qty.formatQuantity())
                case .returnRequestSubmitted, .returnRequestAuthorised, .returnRequestRejected, .returnAccepted, .returnRejected, .disputeOpen, .disputeInProgress, .disputeAccepted, .disputeRejected, .returnRequestDeclinedCanNotDispute, .returnRequestRejectedCanNotDispute:
                    productQtyLabel.text = "X" + existOrEmpty(data.qtyReturned.formatQuantity())
                default:
                    productQtyLabel.text = ""
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    var unpaidData: OrderItem? {
        didSet {
            if let data = self.unpaidData {
                productNameLabel.text = data.skuName
                
                let existOrEmpty = { (value: String?) -> String in
                    return (value != nil && value != "") ? value! : "---"
                }
                
                productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + existOrEmpty(data.colorName)
                productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + existOrEmpty(data.sizeName)
//                
//                productColorLabel.isHidden = (data.colorId == 1)
//                productSizeLabel.isHidden = (data.sizeId == 1)
                
                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(data.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: nil)
                
                let priceText = NSMutableAttributedString()
                let saleFont = UIFont.systemFont(ofSize: 14)
                let unitPrice = data.unitPrice
                
                let locale = Locale(identifier: "zh_Hans_CN")
                let currencySymbol = (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as! String
                
                if let price = unitPrice.formatPrice(currencySymbol: currencySymbol) {
                    let attributedString = NSAttributedString(
                        string: price,
                        attributes: [
                            NSAttributedStringKey.foregroundColor: UIColor.secondary2(),
                            NSAttributedStringKey.font: saleFont
                        ]
                    )
                    
                    priceText.append(attributedString)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                productPriceLabel.attributedText = priceText
                productQtyLabel.text = "X" + existOrEmpty(data.qtyOrdered.formatQuantity())
                
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white

        let containerVerticalPadding: CGFloat = 14
        let containterHorizontalPadding: CGFloat = 15
        
        let container = { () -> UIView in
            let containerHeight = OrderItemCell.DefaultHeight - (containerVerticalPadding * 2)
            let view = UIView(frame: CGRect(x: containterHorizontalPadding, y: containerVerticalPadding, width: frame.width - (containterHorizontalPadding * 2), height: containerHeight))
            
            let productImageContainerView = { () -> UIView in
                let width = containerHeight / Constants.Ratio.ProductImageHeight + 10

                let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: containerHeight))
                let merchantImageRightPadding = CGFloat(10)

                let imageView = UIImageView(frame: UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: merchantImageRightPadding)))
                imageView.contentMode = .scaleAspectFit
                
                view.addSubview(imageView)
                self.productImageView = imageView
                
                return view
            } ()
            view.addSubview(productImageContainerView)
            
            let detailWidth = view.frame.width - productImageContainerView.frame.sizeWidth
            let detailFontSize = 14
            
            // Include: name, color, size, price, qty
            let detailViewContainer = { () -> UIView in
                let view = UIView(frame: CGRect(x: productImageContainerView.frame.maxX, y: 0, width: detailWidth, height: containerHeight))
                
                // Include: price, qty
                let rightView = { () -> UIView in
                    let rightViewWidth: CGFloat = 60
                    let view = UIView(frame: CGRect(x: detailWidth - rightViewWidth, y: 0, width: rightViewWidth, height: containerHeight))
                    
                    productPriceLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.sizeWidth, height: DetailLabelHeight))
                        label.adjustsFontSizeToFitWidth = true
                        label.minimumScaleFactor = 0.5
                        label.numberOfLines = 1
                        label.textAlignment = .right
                        return label
                    } ()
                    view.addSubview(productPriceLabel)
                    
                    productQtyLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: productPriceLabel.frame.maxY + VerticalPadding, width: view.frame.sizeWidth, height: DetailLabelHeight))
                        label.formatSize(detailFontSize)
                        label.textAlignment = .right
                        return label
                    } ()
                    view.addSubview(productQtyLabel)
                    
                    afterSaleQuantityLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: productQtyLabel.frame.maxY + VerticalPadding, width: view.frame.sizeWidth, height: DetailLabelHeight))
                        label.formatSize(detailFontSize)
                        label.isHidden = false
                        label.textAlignment = .right
                        label.text = ""
                        return label
                    } ()
                    view.addSubview(afterSaleQuantityLabel)
                    
                    return view
                } ()
                view.addSubview(rightView)
                priceAndQtyView = rightView
                
                // Include: name, color, size
                let leftView = { () -> UIView in
                    let view = UIView(frame: CGRect(x: 0, y: 0, width: detailWidth - rightView.frame.size.width - 5, height: containerHeight))
                    
                    productNameLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.sizeWidth, height: DetailLabelHeight))
                        label.formatSize(detailFontSize)
                        label.numberOfLines = 2
                        label.lineBreakMode = .byTruncatingTail
                        return label
                    } ()
                    view.addSubview(productNameLabel)
                    
                    productColorLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: productNameLabel.frame.maxY + VerticalPadding, width: view.frame.sizeWidth - 5, height: DetailLabelHeight))
                        label.formatSize(detailFontSize)
                        return label
                    } ()
                    view.addSubview(productColorLabel)
                    
                    productSizeLabel = { () -> UILabel in
                        let label = UILabel(frame: CGRect(x: 0, y: productColorLabel.frame.maxY + VerticalPadding, width: view.frame.sizeWidth - 5, height: DetailLabelHeight))
                        label.formatSize(detailFontSize)
                        return label
                    } ()
                    view.addSubview(productSizeLabel)
                    
                    return view
                } ()
                view.addSubview(leftView)
                return view
                
            } ()
            view.addSubview(detailViewContainer)
            return view
        } ()
        contentView.addSubview(container)
        
        bottomBorderView = UIView(frame: CGRect(x: PaddingContent, y: frame.height - 1, width: frame.width - (2 * PaddingContent), height: 1))
        bottomBorderView.backgroundColor = UIColor.backgroundGray()
        bottomBorderView.isHidden = false
        
        contentView.addSubview(bottomBorderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public func
    
    func formatToSecondLayout() {
        priceAndQtyView.frame = CGRect(x: 0, y: productSizeLabel.frame.maxY + VerticalPadding, width: self.width, height: priceAndQtyView.height)
        productPriceLabel.textAlignment = .left
        afterSaleQuantityLabel.isHidden = true
    }
    
    func setReviewData(_ skuReview : SkuReview) {
        productNameLabel.text = skuReview.skuName
        productColorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + skuReview.colorName
        productSizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + skuReview.sizeName
        
        productImageView.mm_setImageWithURL(ImageURLFactory.URLSize512(skuReview.productImage, category: .product), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit, completion: nil)
        afterSaleQuantityLabel.text = ""
    }
    
    func updateLayout() {
        productNameLabel.height = min(productNameLabel.optimumHeight(), 2 * DetailLabelHeight)
        
        // Update the labels below product name
        productColorLabel.frame.originY = productNameLabel.frame.maxY + VerticalPadding
        productSizeLabel.frame.originY = productColorLabel.frame.maxY + VerticalPadding
        
        if productColorLabel.isHidden {
            productSizeLabel.frame = productColorLabel.frame
        }
    }
    
    func setQuantityShipped(_ quantityShipped: Int) {
        afterSaleQuantityLabel.text = "\(quantityShipped)" + String.localize("LB_CA_OMS_NUM_SKU_QUANTITY_SHIPPED")
    }
    
    func setQuantityToShip(_ quantityToShip: Int) {
        afterSaleQuantityLabel.text = "\(quantityToShip)" + String.localize("LB_CA_OMS_NUM_SKU_QUANTITY_NOT_SHIPPED")
    }
    
    func setProductQty(_ qty: Int) {
        productQtyLabel.text = "X\(qty)"
    }
    
    func hideQuantityLabel(_ hide: Bool = true) {
        productQtyLabel.isHidden = hide
        
        if hide {
            afterSaleQuantityLabel.frame = productQtyLabel.frame
        } else {
            if let parentAfterSaleQuantityLabel = afterSaleQuantityLabel.superview {
                afterSaleQuantityLabel.frame = CGRect(x: 0, y: productQtyLabel.frame.maxY + VerticalPadding, width: parentAfterSaleQuantityLabel.width, height: DetailLabelHeight)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    func hideAfterSaleQuantityLabel(_ hide: Bool = true) {
        afterSaleQuantityLabel.isHidden = hide
    }
    
    func hidePriceLabel(_ hide: Bool = true) {
        productPriceLabel.isHidden = hide
    }
    
    func hideBottomBorderView(_ hide: Bool = true) {
        bottomBorderView.isHidden = hide
    }
    
    func hasActions() -> Bool {
        return (orderDisplayStatus != .shipped)
    }

}
