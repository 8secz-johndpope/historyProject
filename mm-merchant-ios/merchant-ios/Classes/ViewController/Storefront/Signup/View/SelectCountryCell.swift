//
//  SelectCountryCell.swift
//  merchant-ios
//
//  Created by Sang on 2/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class SelectCountryCell : UICollectionViewCell{
    var countryNameLabel = UILabel()
    var countryCodeLabel = UILabel()
    var separatorView  = UIView()
    var checkboxButton: UIButton!// = UIButton(type: .custom)
    private final let LabelMarginLeft : CGFloat = 20
    private final let CountryCodeWidth : CGFloat = 60
    private final let HeightSelectButton: CGFloat = 22
    override init(frame: CGRect) {
        super.init(frame: frame)
        countryNameLabel.formatSize(14)
        addSubview(countryNameLabel)
        countryCodeLabel.formatSize(14)
        countryCodeLabel.textAlignment = .right
        addSubview(countryCodeLabel)
        separatorView.backgroundColor = UIColor.secondary1()
        addSubview(separatorView)
        //Select Button
        self.createCheckboxButton()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout(){
        checkboxButton.frame = CGRect(x: LabelMarginLeft, y: (self.contentView.frame.height - HeightSelectButton) / 2,
                                          width: HeightSelectButton, height: HeightSelectButton)
        countryNameLabel.frame = CGRect(x: checkboxButton.frame.maxX + LabelMarginLeft / 2, y: bounds.minY, width: bounds.width - (LabelMarginLeft * 2 + CountryCodeWidth), height: self.bounds.height)
        countryCodeLabel.frame = CGRect(x: bounds.maxX - (LabelMarginLeft + CountryCodeWidth), y: bounds.minY, width: CountryCodeWidth, height: self.bounds.height)
        separatorView.frame = CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)
        
    }
    
    func createCheckboxButton() {
        checkboxButton = UIButton(type: .custom)
        checkboxButton.config(
            normalImage: UIImage(named: "icon_checkbox_unchecked2"),
            selectedImage: UIImage(named: "icon_checkbox_checked")
        )
        checkboxButton.sizeToFit()
        checkboxButton.isUserInteractionEnabled = false
        addSubview(self.checkboxButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
