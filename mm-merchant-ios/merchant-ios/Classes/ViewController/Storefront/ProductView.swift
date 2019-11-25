//
//  ProductView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ProductView: UIView {
    private final let ImagePadding : CGFloat = 2
    private final let LabelPadding : CGFloat = 10
    var imageView = UIImageView()
    var labelName = UILabel()
    private var isAnimating = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        labelName.formatSmall()
        labelName.textColor = UIColor.white
        self.addSubview(imageView)
        self.addSubview(labelName)
        self.clipsToBounds = true
        self.layer.cornerRadius = 3
        self.backgroundColor = UIColor.darkGray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth = (self.frame.height - ImagePadding * 2) / Constants.Ratio.ProductImageHeight
        imageView.frame = CGRect(x: ImagePadding, y: ImagePadding, width: imageWidth, height: self.frame.height - ImagePadding * 2)
        labelName.frame = CGRect(x: imageView.frame.maxX + LabelPadding, y: 0, width: self.frame.width - (imageView.frame.maxX + LabelPadding * 2), height: self.frame.height)
    }
    
    func setProductImage(_ imageKey : String, contentMode : UIViewContentMode = .scaleAspectFill) {
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageKey), placeholderImage: UIImage(named: "holder"), contentMode: contentMode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showProductWithAnimation(_ animated: Bool) {
        if self.isAnimating {
            self.removeFromSuperview()
        }
        let window = UIApplication.shared.delegate?.window
        if window != nil {
            self.alpha = 0
            window!!.addSubview(self)
            if animated {
                isAnimating = true
                UIView.animate(withDuration: 0.5, delay: 0.0, options:
                    UIViewAnimationOptions.curveEaseIn, animations: {
                        self.alpha = 1.0
                }, completion: { finished in
                    self.isAnimating = false
                })
                
            } else {
                self.alpha = 1.0
            }
        }
    }
    
    func hideProductWithAnimation(_ animated: Bool) {
        if animated {
            isAnimating = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options:
                UIViewAnimationOptions.curveEaseIn, animations: {
                    self.alpha = 0.0
            }, completion: { finished in
                self.removeFromSuperview()
                self.isAnimating = false
            })
        } else {
            self.removeFromSuperview()
            self.isAnimating = false
        }
    }
    
    
    func setData(_ sku: Sku) {
        labelName.text =  sku.skuName
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(sku.productImage), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
        
        
    }
    
    func setTagData(name:String?,imageUrl:String?,type:ProductTagStyle){
        if let name = name {
            labelName.text = name
        }
        
        if let  imageUrl =  imageUrl{
            if type == .Commodity {
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(imageUrl), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
            }else if type == .Brand{
                imageView.mm_setImageWithURL(ImageURLFactory.URLSize128(imageUrl, category: .brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
            }
        }
        else{
            imageView.image = UIImage(named: "holder")
        }
        
    }
    
}

