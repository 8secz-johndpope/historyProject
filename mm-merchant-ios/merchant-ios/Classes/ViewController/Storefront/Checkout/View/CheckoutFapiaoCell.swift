//
//  CheckoutFapiaoCell.swift
//  merchant-ios
//
//  Created by HungPM on 3/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol CheckoutFapiaoCellDelegate: NSObjectProtocol {
    func didClickFapiaoButton(_ sender: UIButton)
}

class CheckoutFapiaoCell: UICollectionViewCell, UITextFieldDelegate {
    
    static let CellIdentifier = "CheckoutFapiaoCellID"
    
    private final let LeftMargin: CGFloat = 20
    private final let RightMargin: CGFloat = 15
    private final let CellHeight: CGFloat = 44
    private final let FapiaoLabelWidth: CGFloat = 70
    
    private var fapiaoLabel: UILabel!
    var fapiaoTextField: UITextField!
    var invoiceButton: UIButton!
    private var separatorView = UIView()
    
    var textFieldBeginEditing : ((_ cell: CheckoutFapiaoCell) -> Void)?
    var textFieldEndEditing : ((_ cell: CheckoutFapiaoCell) -> Void)?
    var textFieldDidChange : ((_ cell: CheckoutFapiaoCell) -> Void)?
    
    weak var delegate: CheckoutFapiaoCellDelegate?
    
    private var isFullSeparator = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        fapiaoLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: LeftMargin, y: 0, width: FapiaoLabelWidth, height: frame.height))
            label.text = String.localize("LB_FAPIAO_REQUEST")
            label.formatSize(15)
            return label
        } ()
        addSubview(fapiaoLabel)

        invoiceButton = UIButton(type: .custom)
        invoiceButton.config(normalImage: UIImage(named: "icon_checkbox_unchecked"), selectedImage: UIImage(named: "icon_checkbox_checked"))
        invoiceButton.addTarget(self, action: #selector(toggleInvoice), for: .touchUpInside)
        invoiceButton.sizeToFit()
        invoiceButton.frame = CGRect(x: frame.width - invoiceButton.width - RightMargin, y: (frame.height - invoiceButton.height) / 2, width: invoiceButton.width, height: invoiceButton.height)
        addSubview(invoiceButton)

        fapiaoTextField = { () -> UITextField in
            let textField = UITextField(frame: CGRect(x: fapiaoLabel.frame.maxX, y: 0, width: invoiceButton.frame.minX - fapiaoLabel.frame.maxX, height: frame.height))
            textField.addTarget(self, action: #selector(CheckoutFapiaoCell.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
            
            let user = Context.getUserProfile()
            textField.placeholder = user.lastName + " " + user.firstName
            
            textField.textColor = UIColor.secondary2()
            textField.font = UIFont(name: textField.font!.fontName, size: CGFloat(15))
            textField.placeholder = String.localize("LB_CA_FAPIAO_TITLE_PLACEHOLDER")

            if textField.delegate == nil {
                textField.delegate = self
            }
            return textField
        } ()
        addSubview(fapiaoTextField)
        fapiaoTextField.isHidden = true
        
        separatorView.backgroundColor = UIColor.backgroundGray()
        addSubview(self.separatorView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        fapiaoLabel.frame = CGRect(x: LeftMargin, y: 0, width: FapiaoLabelWidth, height: frame.height)
        fapiaoTextField.frame = CGRect(x: fapiaoLabel.frame.maxX, y: 0, width: invoiceButton.frame.minX - fapiaoLabel.frame.maxX, height: frame.height)
        
        let separatorLeftMargin = isFullSeparator ? 0 : LeftMargin
        let separatorRightMargin = isFullSeparator ? 0 : RightMargin
        
        separatorView.frame = CGRect(x: separatorLeftMargin, y: frame.height - 1, width: frame.width - separatorLeftMargin - separatorRightMargin, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func toggleInvoice(_ sender: UIButton) {
        self.enableFapiaoTextfield(!sender.isSelected)
        self.delegate?.didClickFapiaoButton(self.invoiceButton)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let callback = self.textFieldDidChange {
            callback(self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let callback = self.textFieldEndEditing {
            callback(self)
        }
    }
    
    func enableFapiaoTextfield(_ isEnable: Bool) {
        self.invoiceButton.isSelected = isEnable
        
        if isEnable {
            fapiaoLabel.text = String.localize("LB_CA_FAPIAO_TITLE")
            fapiaoTextField.isHidden = false
            fapiaoTextField.becomeFirstResponder()
        } else {
            fapiaoLabel.text = String.localize("LB_FAPIAO_REQUEST")
            fapiaoTextField.isHidden = true
            fapiaoTextField.resignFirstResponder()
        }
    }
    
    func setStyle(withSeparator hasSeparator: Bool = true, isFullSeparator: Bool = false) {
        self.isFullSeparator = isFullSeparator
        
        separatorView.isHidden = !hasSeparator
    }
}
