//
//  FilterSizeViewCell.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/10/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class FilterSizeViewCell : UICollectionViewCell {
    var label = UILabel()
    var imageView = UIImageView()
    var crossView = UIImageView(image: UIImage(named: "size_btn_outline"))
    var view = UIView()
    var isCrossed = false
    private final let LabelWidth : CGFloat = 40
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.image = nil
        imageView.layer.borderColor = UIColor.secondary1().cgColor
        imageView.layer.borderWidth = 1
        addSubview(imageView)
        label.formatSize(14)
        label.textAlignment = .center
        addSubview(label)
        view.backgroundColor = UIColor.white
        view.alpha = 0.0
        addSubview(view)
        crossView.alpha = 0.0
        addSubview(crossView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
        label.frame = CGRect(x: bounds.midX - LabelWidth / 2, y: bounds.minY, width: LabelWidth, height: bounds.height)
        imageView.round()
        view.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height)
        view.round()
        crossView.frame = CGRect(x: bounds.minX , y: bounds.minY , width: bounds.width, height: bounds.height)
        crossView.round()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cross(){
        view.alpha = 0.7
        crossView.alpha = 1.0
        isCrossed = true
    }
    
    func unCross(){
        view.alpha = 0.0
        crossView.alpha = 0.0
        isCrossed = false
    }
    
    func border(){
        imageView.layer.borderColor = UIColor.black.cgColor
        
    }
    
    func unBorder(){
        imageView.layer.borderColor = UIColor.secondary1().cgColor
        
    }
    
}
