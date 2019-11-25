//
//  AfterSalesAmountCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesAmountCell: UICollectionViewCell {
    
    static let CellIdentifier = "AfterSalesAmountCellID"
    
    var titleLabel = UILabel()
    var valueTextField = UITextField()
    private var borderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        titleLabel.formatSize(14)
        addSubview(titleLabel)
        
        valueTextField.format()
        valueTextField.textAlignment = .right
        addSubview(valueTextField)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginTop: CGFloat = 5
        let marginLeft: CGFloat = 20
        let labelWidth: CGFloat = (frame.width - (marginLeft * 2)) / 2
        let textFieldWidth: CGFloat = 100
        titleLabel.frame = CGRect(x: marginLeft, y: 0, width: labelWidth, height: frame.height)
        
        let currencyLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.maxX - textFieldWidth - 40, y: marginTop, width: 20, height: frame.height - 2*marginTop))
            label.format()
            
            let locale = Locale(identifier: "zh_Hans_CN")
            let currencySymbol = (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as! String
            
            label.text = currencySymbol
            return label
        }()
        addSubview(currencyLabel)
        
        valueTextField.frame = CGRect(x: frame.maxX - textFieldWidth - 20, y: marginTop, width: textFieldWidth, height: frame.height - 2*marginTop)
        borderView.frame = CGRect(x: 10, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
}
