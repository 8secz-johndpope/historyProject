//
//  SearchHeaderView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class HeaderView : UICollectionReusableView{
    var label = UILabel()
    var imageView = UIImageView()
    var borderView = UIView()
    var bottomLineView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        label.text = String.localize("LB_CA_COLOUR")
        label.formatSmall()
        addSubview(label)
        addSubview(imageView)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        imageView.frame = CGRect(x: bounds.maxX - 60, y: bounds.minY + 5, width: 40, height: 40)
        label.frame = CGRect(x: bounds.minX + 15, y: bounds.minY + 10, width: bounds.width - 30, height: bounds.height)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 1)
        bottomLineView.backgroundColor = UIColor.secondary1()
        bottomLineView.isHidden = true
        bottomLineView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        addSubview(bottomLineView)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showSubviews(_ isShow: Bool){
        for subview in subviews{
            subview.isHidden = !isShow
        }
    }
}
