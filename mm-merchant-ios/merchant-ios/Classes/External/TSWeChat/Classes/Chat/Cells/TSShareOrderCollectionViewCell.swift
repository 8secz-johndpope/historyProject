//
//  TSShareOrderCollectionViewCell.swift
//  merchant-ios
//
//  Created by HungPM on 5/12/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class TSShareOrderCollectionViewCell: UICollectionViewCell {
    
    private final let NoColorId = 1
    private final let NoSizeId = 1
    private final var shouldShowShippedLabel = false

    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var proudctNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var shippedLabel: UILabel!
    
    var orderItem: OrderShareItem? {
        didSet {
            if let orderItem = self.orderItem {
                productImage.mm_setImageWithURL(ImageURLFactory.URLSize750(orderItem.productImage), placeholderImage: UIImage(named: "Spacer"), contentMode: .scaleAspectFit, completion: { [weak self] (image, error, cacheType, imageURL) in
                    
                    guard let strongSelf = self else { return }
                    
                    if image == nil {
                        strongSelf.productImage.image = UIImage(named: "mm_white")
                        strongSelf.productImage.backgroundColor = UIColor.gray
                        strongSelf.productImage.contentMode = .center
                    }
                    else {
                        strongSelf.productImage.backgroundColor = UIColor.clear
                    }
                })
                proudctNameLabel.text = orderItem.skuName
                
                priceLabel.text = orderItem.price.formatPrice()! + " X \(orderItem.quantity)"
                
                colorLabel.text = String.localize("LB_CA_PI_COLOR") + " : " + orderItem.colorName
                sizeLabel.text = String.localize("LB_CA_PI_SIZE") + " : " + orderItem.sizeName
                if let quantityShipped = orderItem.quantityShipped {
                    shippedLabel.text = "\(quantityShipped)" + String.localize("LB_CA_OMS_NUM_SKU_QUANTITY_SHIPPED")
                    shouldShowShippedLabel = true
                }
                else {
                    shouldShowShippedLabel = false
                }
                layoutSubviews()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let MarginLeft = CGFloat(5)
        let MarginTop = CGFloat(2)
        
        productImage.frame = CGRect(x: productImage.frame.origin.x, y: (contentView.height - productImage.height) / 2.0, width: productImage.width, height: productImage.height)
        
        if let orderItem = self.orderItem {
            if orderItem.colorId == NoColorId && orderItem.sizeId == NoSizeId && !shouldShowShippedLabel {
                colorLabel.isHidden = true
                sizeLabel.isHidden = true
                shippedLabel.isHidden = true
            }
            else if orderItem.colorId == NoColorId && orderItem.sizeId == NoSizeId && shouldShowShippedLabel {
                colorLabel.isHidden = true
                sizeLabel.isHidden = true
                shippedLabel.isHidden = false
                
                shippedLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: shippedLabel.frame.width, height: shippedLabel.frame.height)
            }
            else if orderItem.colorId == NoColorId && orderItem.sizeId != NoSizeId && !shouldShowShippedLabel {
                colorLabel.isHidden = true
                sizeLabel.isHidden = false
                shippedLabel.isHidden = true
                
                sizeLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: sizeLabel.frame.width, height: sizeLabel.frame.height)
            }
            else if orderItem.colorId == NoColorId && orderItem.sizeId != NoSizeId && shouldShowShippedLabel {
                colorLabel.isHidden = true
                sizeLabel.isHidden = false
                shippedLabel.isHidden = false
                
                sizeLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: sizeLabel.frame.width, height: sizeLabel.frame.height)
                shippedLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: sizeLabel.frame.maxY + MarginTop, width: shippedLabel.frame.width, height: shippedLabel.frame.height)
            }
            else if orderItem.colorId != NoColorId && orderItem.sizeId == NoSizeId && !shouldShowShippedLabel {
                colorLabel.isHidden = false
                sizeLabel.isHidden = true
                shippedLabel.isHidden = true
                
                colorLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: colorLabel.frame.width, height: colorLabel.frame.height)
            }
            else if orderItem.colorId != NoColorId && orderItem.sizeId == NoSizeId && shouldShowShippedLabel {
                colorLabel.isHidden = false
                sizeLabel.isHidden = true
                shippedLabel.isHidden = false
                
                colorLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: colorLabel.frame.width, height: colorLabel.frame.height)
                shippedLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: colorLabel.frame.maxY + MarginTop, width: shippedLabel.frame.width, height: shippedLabel.frame.height)
            }
            else if orderItem.colorId != NoColorId && orderItem.sizeId != NoSizeId && !shouldShowShippedLabel {
                colorLabel.isHidden = false
                sizeLabel.isHidden = false
                shippedLabel.isHidden = true
                
                colorLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: colorLabel.frame.width, height: colorLabel.frame.height)
                sizeLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: colorLabel.frame.maxY + MarginTop, width: sizeLabel.frame.width, height: sizeLabel.frame.height)
            }
            else {
                colorLabel.isHidden = false
                sizeLabel.isHidden = false
                shippedLabel.isHidden = false

                colorLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: priceLabel.frame.maxY + MarginTop, width: colorLabel.frame.width, height: colorLabel.frame.height)
                sizeLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: colorLabel.frame.maxY + MarginTop, width: sizeLabel.frame.width, height: sizeLabel.frame.height)
                shippedLabel.frame = CGRect(x: productImage.frame.maxX + MarginLeft, y: sizeLabel.frame.maxY + MarginTop, width: shippedLabel.frame.width, height: shippedLabel.frame.height)
            }
        }
    }
}
