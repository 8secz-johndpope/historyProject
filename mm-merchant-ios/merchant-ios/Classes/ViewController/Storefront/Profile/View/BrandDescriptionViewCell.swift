//
//  BrandDescriptionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 7/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class BrandDescriptionViewCell: UICollectionViewCell {
 
    var textLabel : UILabel?
    
    var brand: Brand? {
        didSet {
            if let brand = brand {
                self.textLabel?.text = brand.brandDesc
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        let bounds = CGRect(x: 16, y: 0, width: frame.maxX, height: frame.maxY)
        let label = UILabel(frame: bounds)
        label.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        label.formatSize(14)
        label.textColor = UIColor.secondary3()
        label.numberOfLines = 0
        self.textLabel = label
        self.textLabel?.text = ""
        self.addSubview(label)
     
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = StringHelper.heightForText(self.textLabel!.text!, width: self.bounds.width - 32, font: self.textLabel!.font)
        self.textLabel?.frame = CGRect(x: 16, y: Margin.top * 4 , width: self.bounds.width - 32, height: height)
        
    }
}
