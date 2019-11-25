//
//  AddressSelectionCell.swift
//  merchant-ios
//
//  Created by hungvo on 2/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class AddressSelectionCell: SwipeActionMenuCell {
    
    static let DefaultBottomViewHeight = CGFloat(20)
    static let FontSize = 14
    static let LabelHeight: CGFloat = 18
    static let DisclosureIndicatorXPosition: CGFloat = 28
    static let TopPadding: CGFloat = 5
    static let VerticalPadding: CGFloat = 6
    static let HorizontalPadding: CGFloat = 6
    private final let DisclosureIndicatorWidth: CGFloat = 22
    
    var checkboxButton: UIButton!
    var receiverLabel: UILabel!
    var phoneLabel: UILabel!
    var descriptionLabel: UILabel!
    var borderView: UIView!
    var disclosureIndicatorImageView: UIImageView!
    
    var setDefaultAddressHandler: (() -> Void)?
    
    var editAddressHandler: ((Address) -> Void)?
    
    var data: Address? {
        didSet {
            if let data = self.data {
                receiverLabel.text = data.recipientName
                phoneLabel.text = "(\(data.phoneCode.replacingOccurrences(of: "+", with: ""))) \(data.phoneNumber)"
                let addressData = AddressData(address: data)
                descriptionLabel.text = addressData.getFullAddress()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let checkBoxContainer = { () -> UIView in
            let view = UIView(frame: CGRect(x:0, y: 0, width: Constants.Checkbox.Size.width, height: frame.height))
            
            // Select Button
            checkboxButton = UIButton(type: .custom)
            checkboxButton.config(normalImage: UIImage(named: "icon_checkbox_unchecked"), selectedImage: UIImage(named: "icon_checkbox_checked"))
            checkboxButton.sizeToFit()
            checkboxButton.addTarget(self, action: #selector(AddressSelectionCell.toggleCheckbox), for: .touchUpInside)
            view.addSubview(checkboxButton)
            
            return view
        } ()
        
        contentView.addSubview(checkBoxContainer)
        
        disclosureIndicatorImageView = UIImageView(frame: CGRect(x:frame.size.width - AddressSelectionCell.DisclosureIndicatorXPosition - 8, y: 0, width: DisclosureIndicatorWidth, height: frame.size.height))
        if let imageEdit = UIImage(named: "ic_mode_edit") {
            
            disclosureIndicatorImageView.image = imageEdit.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
        
        disclosureIndicatorImageView.tintColor = UIColor.primary1()
        disclosureIndicatorImageView.contentMode = .scaleAspectFit
        contentView.addSubview(disclosureIndicatorImageView)
        
        let editAddressButton = UIButton(type: .custom)
        editAddressButton.frame = CGRect(x:frame.size.width - AddressSelectionCell.DisclosureIndicatorXPosition - 30, y: 0, width: AddressSelectionCell.DisclosureIndicatorXPosition + 30, height: frame.size.height)
        editAddressButton.addTarget(self, action: #selector(AddressSelectionCell.editAddressButtonTapped), for: .touchUpInside)
        contentView.addSubview(editAddressButton)
        
        let widthOfLabel = disclosureIndicatorImageView.frame.minX - checkBoxContainer.frame.maxX - 8
        
        receiverLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x:checkBoxContainer.frame.maxX, y: AddressSelectionCell.TopPadding, width: widthOfLabel, height: AddressSelectionCell.LabelHeight))
            label.formatSize(AddressSelectionCell.FontSize)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.textColor = UIColor.grayTextColor()
            return label
        } ()
        contentView.addSubview(receiverLabel)
        
        phoneLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x:checkBoxContainer.frame.maxX, y: frame.size.height - AddressSelectionCell.LabelHeight - AddressSelectionCell.TopPadding, width: widthOfLabel, height: AddressSelectionCell.LabelHeight))
            label.formatSize(AddressSelectionCell.FontSize)
            label.textColor = UIColor.grayTextColor()
            return label
            } ()
        contentView.addSubview(phoneLabel)
        
        descriptionLabel = { () -> UILabel in
            let label = UILabel(frame:
                CGRect(x:checkBoxContainer.frame.maxX, y:
                    receiverLabel.frame.maxY + AddressSelectionCell.VerticalPadding, width: widthOfLabel, height:
                    phoneLabel.frame.minY - receiverLabel.frame.maxY - 2*AddressSelectionCell.VerticalPadding)
            )
            label.formatSize(AddressSelectionCell.FontSize)
            label.textColor = UIColor.grayTextColor()
            label.numberOfLines = 0
            return label
        } ()
        contentView.addSubview(descriptionLabel)
        
        borderView = UIView(frame: CGRect(x:0, y: frame.size.height - 1, width: frame.size.width, height: 1))
        borderView.backgroundColor = UIColor.primary2()
        contentView.addSubview(borderView)
        
        descriptionLabel.numberOfLines = 1
        descriptionLabel.lineBreakMode = .byTruncatingTail
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        disclosureIndicatorImageView.frame.sizeHeight = frame.size.height
        checkboxButton.frame = CGRect(x:(Constants.Checkbox.Size.width - checkboxButton.width) / 2, y: (frame.size.height - checkboxButton.frame.height) / 2, width: checkboxButton.frame.width, height: checkboxButton.frame.height)
        borderView.frame.originY = frame.size.height - 1
        
        phoneLabel.frame = CGRect(x:phoneLabel.frame.originX, y: frame.size.height - AddressSelectionCell.LabelHeight - AddressSelectionCell.TopPadding, width: phoneLabel.frame.width, height: AddressSelectionCell.LabelHeight)
        
        descriptionLabel.frame = CGRect(x:descriptionLabel.frame.originX, y: receiverLabel.frame.maxY + AddressSelectionCell.VerticalPadding, width: descriptionLabel.frame.width, height: phoneLabel.frame.minY - receiverLabel.frame.maxY - 2*AddressSelectionCell.VerticalPadding)
    }
    
    // MARK: - Public func
    
    func setDefaultAddress(_ isDefaultAddress: Bool) {
        checkboxButton.isSelected = isDefaultAddress
    }
    
    // MARK: - Action
    
    @objc func editAddressButtonTapped(button: UIButton) {
        if let callback = self.editAddressHandler, let data = self.data {
            callback(data)
        }
    }
    
    @objc func toggleCheckbox(button: UIButton) {
        if let callback = self.setDefaultAddressHandler {
            callback()
        }
    }
}
