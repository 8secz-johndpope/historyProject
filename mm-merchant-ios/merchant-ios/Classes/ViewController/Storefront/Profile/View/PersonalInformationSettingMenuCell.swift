//
//  PersonalInformationSettingMenuCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class PersonalInformationSettingMenuCell: UICollectionViewCell {
    
    enum Style: Int {
        case normal
        case checkout
    }
    
    static let CellIdentifier = "PersonalInformationSettingMenuCellID"
    static let DefaultHeight: CGFloat = 45
    
    private final let MarginLeft: CGFloat = 20
    private final let MenuItemLabelHeight: CGFloat = 42
    private final let ValueImageDimension: CGFloat = 18
    private final let ValueObjectMarginRight: CGFloat = 16
    private final let CenterPaddingWidth: CGFloat = 8
    
    var itemLabel = UILabel()
    var valueLabel = UILabel()
    var itemTextField = UITextField()
    var valueImageView = UIImageView()
    private var disclosureIndicatorImageView = UIImageView()
    private var borderView = UIView()
    private var style = Style.normal
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        itemLabel.formatSize(14)
        addSubview(itemLabel)
        
        itemTextField.isHidden = true
        addSubview(itemTextField)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        addSubview(disclosureIndicatorImageView)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        valueLabel.formatSize(12)
        valueLabel.textAlignment = .right
        addSubview(valueLabel)
        addSubview(valueImageView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        var availableWidth: CGFloat = 0
        
        switch (style) {
        case .normal:
            disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - 35 , y: bounds.midY - disclosureIndicatorImageView.image!.size.height / 2 , width: disclosureIndicatorImageView.image!.size.width, height: disclosureIndicatorImageView.image!.size.height)
            availableWidth = disclosureIndicatorImageView.frame.origin.x - MarginLeft - ValueObjectMarginRight - CenterPaddingWidth
            itemLabel.frame = CGRect(
                x: MarginLeft,
                y: bounds.midY - (MenuItemLabelHeight / 2),
                width: availableWidth / 2,
                height: MenuItemLabelHeight
            )
            
            valueLabel.frame = CGRect(
                x: MarginLeft + availableWidth / 2 + CenterPaddingWidth,
                y: bounds.midY - (MenuItemLabelHeight / 2),
                width: availableWidth / 2,
                height: MenuItemLabelHeight
            )
            
        case .checkout:
            let arrowWidth: CGFloat = 32
            disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - arrowWidth - 17, y: bounds.midY - arrowWidth / 2 , width: arrowWidth, height: arrowWidth)
            availableWidth = disclosureIndicatorImageView.frame.origin.x - MarginLeft - ValueObjectMarginRight - CenterPaddingWidth
            itemLabel.frame = CGRect(
                x: 17,
                y: bounds.midY - (MenuItemLabelHeight / 2),
                width: availableWidth / 2,
                height: MenuItemLabelHeight
            )
            
            valueLabel.adjustsFontSizeToFitWidth = true
            let xValueLabel = itemLabel.frame.maxX + 5
            valueLabel.frame = CGRect(
                x: xValueLabel,
                y: bounds.midY - (MenuItemLabelHeight / 2),
                width: disclosureIndicatorImageView.frame.minX - xValueLabel,
                height: MenuItemLabelHeight
            )
        }
        
        valueImageView.frame = CGRect(
            x: disclosureIndicatorImageView.frame.origin.x - ValueImageDimension - ValueObjectMarginRight,
            y: bounds.midY - (ValueImageDimension / 2),
            width: ValueImageDimension,
            height: ValueImageDimension
        )
    }
    
    func setStyles(_ style: Style) {
        self.style = style
        
        switch(style) {
        case .normal:
            disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        case .checkout:
            disclosureIndicatorImageView.image = UIImage(named: "icon_arrow_small")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setValueImage(imageName: String){
        valueImageView.image = UIImage(named: imageName)
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        disclosureIndicatorImageView.isHidden = !isShow
    }
    
    func showPickerView(){
        itemTextField.becomeFirstResponder()
    }
}
