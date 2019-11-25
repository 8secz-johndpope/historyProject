//
//  QuantityCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 9/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class QuantityCell: UICollectionViewCell {
    
    enum SeparatorStyle: Int {
        case none = 0
        case checkout
        case afterSales
    }
    
    struct Tag {
        static let AddButton = 1001
        static let MinusButton = 1002
    }
    
    static let CellIdentifier = "QuantityCellID"
    
    var textLabel: UILabel!
    var qtyTextField: UITextField!
    var qtyValueLabel: UILabel! //When creating Dispute only display qtyValue. Don't allow to change
    var addStepButton: UIButton!
    var minusStepButton: UIButton!

    private final let TextLabelWidth: CGFloat = 80
    private final let StepButtonWidth: CGFloat = 15
    private final let QtyTextFieldWidth: CGFloat = 48
    
    private let paddingTop: CGFloat = 20
    private let paddingLeft: CGFloat = 20
    private let paddingTopOfStepButton: CGFloat = 5
    private let xSpacing: CGFloat = 20
    
    private var separatorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        textLabel = UILabel(frame: CGRect(x: bounds.minX + paddingLeft, y: 0, width: TextLabelWidth, height: bounds.height))
        textLabel.formatSize(15)
        textLabel.text = String.localize("LB_CA_EDITITEM_QTY")
        addSubview(textLabel)
        
        let marginRight: CGFloat = 20
        let imageEdgeInsets = UIEdgeInsets(top: 0, left: StepButtonWidth / 2, bottom: 0, right: StepButtonWidth / 2)

        addStepButton = UIButton(frame: CGRect(x: frame.width - marginRight - StepButtonWidth * 1.5, y: paddingTopOfStepButton, width: 2 * StepButtonWidth, height: bounds.height - 2 * paddingTopOfStepButton))
        addStepButton.imageEdgeInsets = imageEdgeInsets
        addStepButton.setImage(UIImage(named: "add_icon"), for: UIControlState())
        addStepButton.imageView?.contentMode = .scaleAspectFill
        addStepButton.tag = Tag.AddButton
        addStepButton.accessibilityIdentifier = "add_icon"
//        addStepButton.layer.borderWidth = 1
//        addStepButton.layer.cornerRadius = 2
        addSubview(addStepButton)

        qtyTextField = UITextField(frame: CGRect(x: addStepButton.frame.minX - xSpacing - QtyTextFieldWidth, y: bounds.minY + paddingTopOfStepButton, width: QtyTextFieldWidth, height: QtyTextFieldWidth))
        qtyTextField.layer.borderColor = UIColor.secondary1().cgColor
        qtyTextField.layer.borderWidth = Constants.TextField.BorderWidth
        qtyTextField.clipsToBounds = true
        qtyTextField.layer.cornerRadius = 2
        qtyTextField.textAlignment = .center
        
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardDoneButtonView.items = [flexibleSpaceBarButton, createDoneButton()]
        
        qtyTextField.inputAccessoryView = keyboardDoneButtonView
        
        addSubview(qtyTextField)
        
        qtyValueLabel = UILabel(frame: qtyTextField.frame)
        qtyValueLabel.formatSize(15)
        qtyValueLabel.textAlignment = .right
        qtyValueLabel.isHidden = true //hidden by default
        addSubview(qtyValueLabel)
        
        addSubview(textLabel)
        minusStepButton = UIButton(frame: CGRect(x: qtyTextField.frame.minX - xSpacing - 2 * StepButtonWidth, y: paddingTopOfStepButton, width: 2 * StepButtonWidth, height: bounds.height - 2 * paddingTopOfStepButton))
        minusStepButton.imageEdgeInsets = imageEdgeInsets
        minusStepButton.setImage(UIImage(named: "icon_order_quatity_minus"), for: UIControlState())
        minusStepButton.imageView?.contentMode = .scaleAspectFill
        minusStepButton.tag = Tag.MinusButton
        minusStepButton.accessibilityIdentifier = "icon_quatity_minus"
//        minusStepButton.layer.borderWidth = 1
//        minusStepButton.layer.cornerRadius = 2
        addSubview(minusStepButton)
        
        addSubview(separatorView)
        
        
        addStepButton.snp.makeConstraints {  [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            let height: CGFloat = 30
            target.height.width.equalTo(height)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            
            target.top.equalTo((frame.sizeHeight - height) / 2)
        }
        
        qtyTextField.snp.makeConstraints {  [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            let height: CGFloat = 30
            target.height.equalTo(height)
            target.width.equalTo(40)
            target.right.equalTo(strongSelf.addStepButton.snp.left).offset(-10)
            target.top.equalTo((frame.sizeHeight - height) / 2)
        }
        
        qtyValueLabel.snp.makeConstraints {  [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            let height: CGFloat = 30
            target.height.equalTo(height)
            target.width.equalTo(40)
            target.right.equalTo(strongSelf.addStepButton.snp.left).offset(-10)
            target.top.equalTo((frame.sizeHeight - height) / 2)
        }
        
        minusStepButton.snp.makeConstraints {  [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            let height: CGFloat = 30
            target.height.width.equalTo(height)
            target.right.equalTo(strongSelf.qtyValueLabel.snp.left).offset(-10)
            target.top.equalTo((frame.sizeHeight - height) / 2)
        }
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSeparatorStyle(_ separatorStyle: SeparatorStyle) {
        switch separatorStyle {
        case .none:
            separatorView.isHidden = true
        case .checkout:
            let marginLeft: CGFloat = 15
            let paddingRight: CGFloat = 15
            
            separatorView.frame = CGRect(x: marginLeft, y: frame.height - 1, width: frame.width - marginLeft - paddingRight, height: 1)
            separatorView.backgroundColor = UIColor.secondary1()
            separatorView.isHidden = false
        case .afterSales:
            separatorView.frame = CGRect(x: 10, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
            separatorView.backgroundColor = UIColor.secondary1()
            separatorView.isHidden = false
        }
        
        layoutSubviews()
    }
    
    @objc func dismissKeyboard(_ sender: Any?) {
        self.endEditing(true)
    }
    
    private func createDoneButton() -> UIBarButtonItem {
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: frame.width - 30, y: 10, width: 50, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.setTitleColor(UIColor.redDoneButton(), for: UIControlState())
        doneButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        
        return UIBarButtonItem(customView: doneButton)
    }
}
