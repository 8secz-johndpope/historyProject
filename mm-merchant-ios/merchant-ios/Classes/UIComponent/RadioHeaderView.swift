//
//  RadioHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/28/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class RadioHeaderView: UICollectionReusableView {
    static let ViewIdentifier = "RadioHeaderViewID"
    static let DefaultHeight: CGFloat = 40
    static let CheckBoxWidth: CGFloat = 50
    
    var label = UILabel()
    var selectAllLabel = UILabel()
    var borderView = UIView()
    private var selectAllCartItemButton = UIButton()
    
    var didTappSelectAll: ((Bool) -> ())?
    
    var isChecked = false{
        didSet{
            selectAllCartItemButton.isSelected = isChecked
            if isChecked{
                selectAllLabel.textColor = UIColor.primary1()
            }
            else{
                selectAllLabel.textColor = UIColor.secondary2()
            }
        }
    }
    
    struct Margin {
        static let Top: CGFloat = 0
        static let Left: CGFloat = 15
        static let Bottom: CGFloat = 0
        static let Right: CGFloat = 15
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        label.formatSmall()
        label.textAlignment = .left
        addSubview(label)
        
        let checkBoxContainer = { () -> UIView in
            let view = CenterLayoutView(frame: CGRect(x: frame.maxX - RadioHeaderView.Margin.Right - RadioHeaderView.CheckBoxWidth, y: 0, width: RadioHeaderView.CheckBoxWidth, height: frame.height))
            
            let button = UIButton(type: .custom)
            button.config(
                normalImage: UIImage(named: "icon_checkbox_unchecked"),
                selectedImage: UIImage(named: "icon_checkbox_checked")
            )
            button.sizeToFit()
            button.addTarget(self, action: #selector(RadioHeaderView.toggleSelectAllCartItems), for: .touchUpInside)
            view.addSubview(button)
            selectAllCartItemButton = button
            return view
        } ()
        addSubview(checkBoxContainer)

        
        let selectAllLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect.zero)
            label.text = String.localize("LB_CA_SELECT_ALL_PI")
            label.formatSmall()
            label.sizeToFit()
            label.textAlignment = NSTextAlignment.right
            label.frame = CGRect(x: checkBoxContainer.frame.minX - label.optimumWidth(), y: 0, width: label.optimumWidth(), height: frame.height)
            return label
            
        } ()
        self.selectAllLabel = selectAllLabel
        addSubview(selectAllLabel)
        
        borderView.isHidden = true
        borderView.isUserInteractionEnabled = false
        borderView.layer.borderColor = UIColor.secondary1().cgColor
        borderView.layer.borderWidth = 1.0
        borderView.backgroundColor = UIColor.clear
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        label.frame = CGRect(x: bounds.minX + RadioHeaderView.Margin.Left, y: bounds.minY, width: bounds.width - 64 , height: bounds.height)
        borderView.frame = CGRect(x: bounds.minX - 1, y: bounds.minY, width: bounds.width + 2, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: Actions
    
    @objc func toggleSelectAllCartItems(_ button: UIButton) {
        isChecked = !isChecked
        if let action = self.didTappSelectAll{
            action(isChecked)
        }
    }
}
