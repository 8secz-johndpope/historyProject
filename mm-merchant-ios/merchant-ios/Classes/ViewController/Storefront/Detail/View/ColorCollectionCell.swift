//
//  ColorCollectionCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ColorCollectionCell: UICollectionViewCell {
    
    static let CellIdentifier = "ColorCollectionCellID"
    
    var imageView = UIImageView()
    var topPadding: CGFloat = 0
    
    private var crossView = UIImageView(image: UIImage(named: "size_btn_outline"))
    private var overlayView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        imageView.image = nil
        imageView.layer.borderWidth = 1
        addSubview(imageView)
        
        overlayView.backgroundColor = UIColor.white
        addSubview(overlayView)
        
        addSubview(crossView)
        
        itemDisabled(false)
        itemSelected(false)
        
        self.layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: 0, y: topPadding, width: bounds.width, height: bounds.width)
        imageView.round()
        
        overlayView.frame = imageView.frame
        overlayView.round()
        
        crossView.frame = imageView.frame
        crossView.round()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func itemDisabled(_ disabled: Bool) {
        if disabled {
            overlayView.alpha = 0.7
            crossView.alpha = 1.0
            itemSelected(false)
        } else {
            overlayView.alpha = 0.0
            crossView.alpha = 0.0
        }
    }
    
    func itemSelected(_ selected: Bool) {
        if selected {
            imageView.layer.borderColor = UIColor.black.cgColor
        } else {
            imageView.layer.borderColor = UIColor.secondary1().cgColor
        }
        
        self.accessibilityValue = selected ? "true" : "false"
    }
    
    func setImage(_ imageKey: String, contentMode: UIViewContentMode = .scaleAspectFill){
        imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .product), placeholderImage : UIImage(named: "holder"), contentMode: contentMode)
    }

}
