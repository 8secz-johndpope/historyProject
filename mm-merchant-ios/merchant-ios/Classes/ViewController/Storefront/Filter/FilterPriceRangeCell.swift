//
//  FilterPriceRangeCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

protocol FilterPriceRangeCellDelegate: NSObjectProtocol {
    func filterPriceRangeCell(didChangePriceRange  filterPriceRangeCell: FilterPriceRangeCell, minPrice: Int?, maxPrice: Int?)
}

class FilterPriceRangeCell: UICollectionViewCell, UITextFieldDelegate{
    
    private var minPriceTextField = UITextField()
    private var maxPriceTextField = UITextField()
    private var seperatorView = UIView()
    private var bottomLine = UIView()
    
    weak var filterPriceRangeCellDelegate: FilterPriceRangeCellDelegate?
    
    fileprivate(set) var lowestPrice = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        setupPriceTextField(minPriceTextField)
        minPriceTextField.placeholder = String.localize("LB_CA_LOWEST_PRICE")
        addSubview(minPriceTextField)
        
        maxPriceTextField.placeholder = String.localize("LB_CA_HIGHEST_PRICE")
        setupPriceTextField(maxPriceTextField)
        addSubview(maxPriceTextField)
        
        seperatorView.backgroundColor = UIColor.secondary4()
        addSubview(seperatorView)
        
        bottomLine.backgroundColor = UIColor.secondary1()
        addSubview(bottomLine)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 16
        let seperatorSize: CGSize = CGSize(width: 15, height: 1)
        let priceTextFieldWidth = (width - 4*padding - seperatorSize.width)/2
        let priceTextFieldHeight: CGFloat = 36
        
        minPriceTextField.frame = CGRect(x: padding, y: 0, width: priceTextFieldWidth, height: priceTextFieldHeight)
        maxPriceTextField.frame = CGRect(x: width - padding - priceTextFieldWidth, y: 0, width: priceTextFieldWidth, height: priceTextFieldHeight)
        
        seperatorView.frame = CGRect(origin: CGPoint(x: (width - seperatorSize.width)/2, y: maxPriceTextField.frame.midY), size: seperatorSize)
        
        bottomLine.frame = CGRect(x: 0, y: height - 1, width: width, height: 1)
    }
    
    private func setupPriceTextField(_ textField: UITextField){
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.secondary1().cgColor
        textField.round(5)
        textField.tintColor = UIColor.secondary2()
        textField.textColor = UIColor.secondary2()
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        
        if let font = UIFont(name: Constants.Font.Normal, size: 14){
            textField.font = font
        }
        else{
            textField.font = UIFont.systemFontWithSize(12)
        }
        
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: 0, y: 10, width: 70, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.backgroundColor = UIColor.white
        doneButton.layer.borderColor = UIColor.secondary1().cgColor
        doneButton.layer.borderWidth = 1
        doneButton.layer.cornerRadius = 5
        doneButton.setTitleColor(UIColor.black, for: UIControlState())
        doneButton.addTarget(self, action: #selector(FilterPriceRangeCell.doneButtonDidTap), for: .touchUpInside)
        let doneButtonItem = UIBarButtonItem(customView: doneButton)
        
        doneToolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                             doneButtonItem]
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
        
        textField.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setMinPrice(_ price: Int?){
        if let price = price{
            minPriceTextField.text = "\(price)"
        }else{
            minPriceTextField.text = ""
        }
    }
    
    func setMaxPrice(_ price: Int?){
        if let price = price{
            maxPriceTextField.text = "\(price)"
        }else{
            maxPriceTextField.text = ""
        }
    }
    
    func getMinPrice() -> Int?{
        return Int(minPriceTextField.text ?? "")
    }
    
    func getMaxPrice() -> Int?{
        return Int(maxPriceTextField.text ?? "")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        if prospectiveText.isEmpty{
            return true
        }
        
        if prospectiveText.length > 5{
            return false
        }
        
        guard let _ = Int(prospectiveText) else{
            return false
        }

        return true
    }
    
    @objc func doneButtonDidTap(_ sender: UIButton){
        minPriceTextField.resignFirstResponder()
        maxPriceTextField.resignFirstResponder()
        filterPriceRangeCellDelegate?.filterPriceRangeCell(didChangePriceRange: self, minPrice: getMinPrice(), maxPrice: getMaxPrice())
    }
}
