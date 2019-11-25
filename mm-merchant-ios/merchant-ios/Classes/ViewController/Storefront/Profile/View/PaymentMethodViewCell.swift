//
//  PaymentMethodViewCell.swift
//  merchant-ios
//
//  Created by Gambogo on 3/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

@objc
protocol PaymentMethodViewCellDelegate: NSObjectProtocol {
    @objc optional func onPaymentItemSelect(_ cell: PaymentMethodViewCell)
}

class PaymentMethodViewCell: UICollectionViewCell {
    
    static let CellIdentifier = "PaymentMethodViewCellID"
    
    private final let MarginLeft: CGFloat = 20
    private final let PaddingContent: CGFloat = 15
    private final let MenuItemLabelHeight: CGFloat = 42
    private final let DefaultPaymentLabelHeight: CGFloat = 25
    private final let ValueObjectMarginRight: CGFloat = 16
    private final let CenterPaddingWidth: CGFloat = 8
    private final let CheckboxSize = CGSize(width: 25, height: 25)
    
    var itemLabel = UILabel()
    var defaultPaymentLabel = UILabel()
    private var disclosureIndicatorImageView = UIImageView()
    private var borderView = UIView()
    private var paymentSelectButton: UIButton!
    
    weak var delegate: PaymentMethodViewCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        itemLabel.formatSize(14)
        contentView.addSubview(itemLabel)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        contentView.addSubview(disclosureIndicatorImageView)
        
        borderView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(borderView)
        
        createCheckboxButton()
        createDefaultPaymentLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Views
    
    func createCheckboxButton() {
        paymentSelectButton = UIButton(type: .custom)
        paymentSelectButton.config(
            normalImage: UIImage(named: "icon_checkbox_unchecked"),
            selectedImage: UIImage(named: "icon_checkbox_checked")
        )
        paymentSelectButton.addTarget(self, action: #selector(PaymentMethodViewCell.paymentItemSelect), for: .touchUpInside)
        paymentSelectButton.sizeToFit()
        paymentSelectButton.frame = CGRect(x: MarginLeft, y: (contentView.frame.height - CheckboxSize.height) / 2, width: CheckboxSize.width, height: CheckboxSize.height)
        contentView.addSubview(self.paymentSelectButton)
    }
    
    func createDefaultPaymentLabel() {
        defaultPaymentLabel.formatSize(14)
        defaultPaymentLabel.text = String.localize("LB_CA_DEFAULT")
        defaultPaymentLabel.textAlignment = .center
        contentView.addSubview(defaultPaymentLabel)
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        disclosureIndicatorImageView.isHidden = !isShow
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - 35 , y: bounds.midY - disclosureIndicatorImageView.image!.size.height / 2 , width: disclosureIndicatorImageView.image!.size.width, height: disclosureIndicatorImageView.image!.size.height)
        
        let availableWidth = disclosureIndicatorImageView.frame.origin.x - MarginLeft - ValueObjectMarginRight - CenterPaddingWidth - paymentSelectButton.frame.maxX - PaddingContent
        
        itemLabel.frame = CGRect(
            x: paymentSelectButton.frame.maxX + PaddingContent,
            y: bounds.midY - (MenuItemLabelHeight / 2),
            width: availableWidth,
            height: MenuItemLabelHeight
        )
        
        let widthDefaultPayment = self.itemLabel.frame.originX - PaddingContent
        defaultPaymentLabel.frame = CGRect(
            x: paymentSelectButton.centerX - (widthDefaultPayment/2),
            y: paymentSelectButton.frame.bottom,
            width: widthDefaultPayment,
            height: DefaultPaymentLabelHeight
        )
    }
    
    // MARK: - View Action
    
    @objc func paymentItemSelect() {
        self.delegate?.onPaymentItemSelect!(self)
    }
    
    func showPaymentSelected(_ isPaymentSelected: Bool) {
        paymentSelectButton.isSelected = isPaymentSelected
        defaultPaymentLabel.isHidden = !isPaymentSelected
    }
}
