//
//  SignupLoginPhoneView.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SignupLoginPhoneView: UIView {
    lazy var tapView:UIView = {
        let tapView = UIView()
        return tapView
    }()
    lazy var label:UILabel = {
        let label = UILabel()
        label.text = "中国+86"
        label.font = UIFont.systemFont(ofSize: 22)
        return label
    }()
    lazy var imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "triangle_down_black")
        imageView.sizeToFit()
        return imageView
    }()
    lazy var textField:UITextField = {
        let textField = UITextField()
        textField.placeholder = String.localize("LB_CA_ENTER_MOBILE_NUMBER")
        textField.clearsOnBeginEditing = false
        textField.clearButtonMode = UITextFieldViewMode.whileEditing
        textField.tintColor = UIColor.black
        textField.font = UIFont.systemFont(ofSize: 22)
        textField.keyboardType = UIKeyboardType.numberPad
        return textField
    }()
    lazy var lineView:UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.secondary10()
        return lineView
    }()
    lazy var bottomlineView:UIView = {
        let bottomlineView = UIView()
        bottomlineView.backgroundColor = UIColor.secondary10()
        return bottomlineView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(tapView)
        self.addSubview(label)
        self.addSubview(imageView)
        self.addSubview(textField)
        self.addSubview(lineView)
        self.addSubview(bottomlineView)
        
        tapView.snp.makeConstraints { (make) in
            make.left.height.top.equalTo(self)
            make.right.equalTo(lineView.snp.left)
        }
        bottomlineView.snp.makeConstraints { (make) in
            make.width.equalTo(ScreenWidth - 30)
            make.bottom.equalTo(self).offset(-1)
            make.height.equalTo(1.5)
            make.centerX.equalTo(self)
        }
        label.snp.makeConstraints { (make) in
            make.left.equalTo(bottomlineView)
            make.height.equalTo(self)
            make.centerY.equalTo(self)
        }
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.left.equalTo(label.snp.right).offset(3)
        }
        lineView.snp.makeConstraints { (make) in
            make.width.equalTo(1)
            make.height.equalTo(22)
            make.centerY.equalTo(self)
            make.left.equalTo(imageView.snp.right).offset(14)
        }
        textField.snp.makeConstraints { (make) in
            make.left.equalTo(lineView.snp.right).offset(14)
            make.right.equalTo(bottomlineView)
            make.height.equalTo(self)
            make.centerY.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
