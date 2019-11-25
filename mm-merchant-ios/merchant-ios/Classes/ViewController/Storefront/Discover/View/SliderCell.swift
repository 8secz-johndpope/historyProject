//
//  SliderCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import NMRangeSlider

class SliderCell : UICollectionViewCell {
    
    var slider : FilterRangeSlider!
    var upperLabel : UILabel!
    var lowerLabel : UILabel!
    var midLabel : UILabel!
    var borderView : UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        slider = FilterRangeSlider(frame:CGRect(x: 15, y: bounds.minY + 10, width: bounds.width - 30, height: bounds.height - 20))
        slider.continuous = true
        slider.tintColor = UIColor.primary1()
        slider.backgroundColor = UIColor.white
        slider.trackBackgroundImage = UIImage(named: "track_normal")
        slider.trackImage = UIImage(named: "track_selected")
        slider.upperHandleImageNormal = UIImage(named: "scrubber_normal")
        slider.lowerHandleImageNormal = UIImage(named: "scrubber_normal")
        slider.lowerHandleImageHighlighted = UIImage(named: "scrubber_pressed")
        slider.upperHandleImageHighlighted = UIImage(named: "scrubber_pressed")
        slider.clipsToBounds = true
        addSubview(slider)
        lowerLabel = UILabel(frame: CGRect(x: bounds.center.x - 110, y: bounds.height - 80, width: 100, height: 30))
        lowerLabel.formatSmall()
        lowerLabel.textAlignment = .right
        addSubview(lowerLabel)
        midLabel = UILabel(frame: CGRect(x: bounds.center.x - 10, y: bounds.height - 80, width: 20, height: 30))
        midLabel.formatSmall()
        midLabel.textAlignment = .center
        midLabel.text = "-"
        addSubview(midLabel)
        upperLabel = UILabel(frame: CGRect(x: bounds.center.x + 10, y: bounds.height - 80 , width: 100, height: 30))
        upperLabel.formatSmall()
        upperLabel.textAlignment = .left
        addSubview(upperLabel)
        borderView = UIView(frame: CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1))
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        slider.frame = CGRect(x: 15, y: bounds.minY + 10, width: bounds.width - 30, height: bounds.height - 20)
        slider.layoutIfNeeded()
       
        upperLabel.frame = CGRect(x: bounds.center.x + 10, y: bounds.height - 80 , width: 100, height: 30)
        lowerLabel.frame = CGRect(x: bounds.center.x - 110, y: bounds.height - 80, width: 100, height: 30)
        midLabel.frame = CGRect(x: bounds.center.x - 10, y: bounds.height - 80, width: 20, height: 30)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
