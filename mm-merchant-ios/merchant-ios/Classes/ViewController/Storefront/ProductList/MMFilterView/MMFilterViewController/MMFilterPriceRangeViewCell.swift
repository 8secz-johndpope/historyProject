//
//  MMFilterPriceRangeViewCell.swift
//  storefront-ios
//
//  Created by Demon on 20/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

protocol MMFilterPriceRangeViewCellDelegate: NSObjectProtocol {
    
    func filterPriceRangeCell(filterPriceRangeCell: MMFilterPriceRangeViewCell, minPrice: Int?, maxPrice: Int?)
}

class MMFilterPriceRangeViewCell: UICollectionViewCell {
    
    weak var filterPriceRangeViewCellDelegate: MMFilterPriceRangeViewCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadUI()
    }
    
    private func loadUI() {
        contentView.addSubview(minPriceTextField)
        contentView.addSubview(maxPriceTextField)
        contentView.addSubview(line)
        minPriceTextField.placeholder = String.localize("LB_CA_LOWEST_PRICE")
        maxPriceTextField.placeholder = String.localize("LB_CA_HIGHEST_PRICE")
        setNeedsUpdateConstraints()
    }
    
    func setPrice(_ maxPrice: String?, minPirce: String?) {
        maxPriceTextField.text = maxPrice
        minPriceTextField.text = minPirce
    }

    override func updateConstraints() {
        line.snp.makeConstraints { (make) in
            make.center.equalTo(self.snp.center)
            make.width.equalTo(11)
            make.height.equalTo(1)
        }
        minPriceTextField.snp.makeConstraints { (make) in
            make.right.equalTo(line.snp.left).offset(-16)
            make.left.equalTo(self.snp.left).offset(13)
            make.centerY.equalTo(line.snp.centerY)
            make.height.equalTo(32)
        }
        maxPriceTextField.snp.makeConstraints { (make) in
            make.left.equalTo(line.snp.right).offset(16)
            make.right.equalTo(self.snp.right).offset(-16)
            make.centerY.equalTo(line.snp.centerY)
            make.height.equalTo(self.minPriceTextField.snp.height)
        }
        super.updateConstraints()
    }
    
    @objc private func doneButtonDidTap() {
        minPriceTextField.resignFirstResponder()
        maxPriceTextField.resignFirstResponder()
        var minP = Int(minPriceTextField.text!)
        var maxP = Int(maxPriceTextField.text!)
        
        if let min = minP,let max = maxP {
            if min > max {
                let m = min
                minP = max
                maxP = m
            }
        }
        
        if let delegate = filterPriceRangeViewCellDelegate {
            delegate.filterPriceRangeCell(filterPriceRangeCell: self, minPrice: minP, maxPrice: maxP)
        }
    }
  
    private func setTextFiled(_ textField: UITextField) {
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = UIColor(hexString: "#E7E7E7").cgColor
        textField.round(4)
        textField.tintColor = UIColor.secondary2()
        textField.textColor = UIColor.secondary15()
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.font = UIFont.systemFontWithSize(12)
        
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
        doneButton.addTarget(self, action: #selector(MMFilterPriceRangeViewCell.doneButtonDidTap), for: .touchUpInside)
        let doneButtonItem = UIBarButtonItem(customView: doneButton)
        
        doneToolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil), doneButtonItem]
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
    }
    
    private lazy var minPriceTextField: UITextField = {
        let tx = UITextField()
        setTextFiled(tx)
        return tx
    }()
    
    private lazy var maxPriceTextField: UITextField = {
        let tx = UITextField()
        setTextFiled(tx)
        return tx
    }()
    
    lazy var line: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor(hexString: "#B2B2B2")
        return line
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
