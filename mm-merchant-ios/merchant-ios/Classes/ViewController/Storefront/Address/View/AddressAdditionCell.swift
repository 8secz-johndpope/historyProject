//
//  AddressAdditionCell.swift
//  merchant-ios
//
//  Created by hungvo on 2/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class AddressAdditionCell: UICollectionViewCell, UITextViewDelegate {
    
    private final let FontSize = 14
    private final let ArrowSize = CGSize(width: 7, height: 15)
    
    private let textFieldMarginLeft: CGFloat = 11
    private let textFieldPaddingLeft: CGFloat = 23
    private let arrowViewPaddingRight: CGFloat = 13
    
    private let textContainerInset  = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: Constants.TextField.LeftPaddingWidth * 2)
    
    private let textHolderColor = UIColor(hexString:"#CDCFD2")
    
    var textField: UITextField!
    var textView: MMPlaceholderTextView!
    var arrowView: UIImageView!
    
    var removeMarginLeft = false
    var removeMarginRight = false
    
    var textViewBeginEditing: (() -> Void)?
    var textViewEndEditing: (() -> Void)?
    var textViewTextChanged: ((_ text: String) -> Void)?
    
    var placeholder: String? {
        didSet {
            if let placeholder = self.placeholder {
                self.textField.placeholder = placeholder
                self.textView.placeholder = placeholder
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let textField = UITextField(frame: CGRect(x: textFieldMarginLeft, y: 0, width: frame.size.width - (textFieldMarginLeft * 2), height: frame.size.height + 1))
        textField.format()
//        textField.layer.borderColor = UIColor.secondary1().cgColor
//        textField.layer.borderWidth = Constants.TextField.BorderWidth
//        
//        let paddingView = UIView(frame: CGRect(x:0, y: 0, width: textFieldPaddingLeft, height: frame.height))
//        textField.leftView = paddingView
//        textField.leftViewMode = UITextFieldViewMode.Always
//        textField.font = UIFont(name: textField.font!.fontName, size: CGFloat(FontSize))
//        textField.textColor = UIColor.secondary2()
        self.textField = textField
        
        let textView = MMPlaceholderTextView(frame: textField.frame)
        textView.layer.borderColor = UIColor.secondary1().cgColor
        textView.layer.borderWidth = Constants.TextField.BorderWidth
        textView.font = UIFont(name: textField.font!.fontName, size: CGFloat(FontSize))
        textView.textColor = UIColor.secondary2()
        textView.placeholderColor = textHolderColor
        textView.textContainerInset = textContainerInset
        textView.delegate = self
        self.textView = textView
        
        
        arrowView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: textField.bounds.width - ArrowSize.width - arrowViewPaddingRight, y: (textField.bounds.height - ArrowSize.height) / 2, width: ArrowSize.width, height: ArrowSize.height))
            imageView.image = UIImage(named: "icon_arrow")
            imageView.contentMode = .scaleAspectFit
            return imageView
        } ()
        textField.addSubview(arrowView)
        
        contentView.addSubview(textField)
        contentView.addSubview(textView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var textFieldOriginX = textFieldMarginLeft
        var textFieldWidth = frame.size.width - (textFieldMarginLeft * 2)
        
        if removeMarginLeft {
            textFieldOriginX = -1
            textFieldWidth = textFieldWidth + textFieldMarginLeft + 1
        }
        
        if removeMarginRight {
            textFieldWidth = textFieldWidth + textFieldMarginLeft
        }
        
        textField.frame = CGRect(x: textFieldOriginX, y: 0, width: textFieldWidth, height: frame.size.height + 1)
        textView.frame = textField.frame
        arrowView.frame = CGRect(x: textField.bounds.width - ArrowSize.width - arrowViewPaddingRight, y: (textField.bounds.height - ArrowSize.height) / 2, width: ArrowSize.width, height: ArrowSize.height)
    }
    
    func hiddenTextField(_ hidden: Bool) {
        self.textField.isHidden = hidden
        self.textView.isHidden = !hidden
    }

    func hiddenArrowView(_ hidden: Bool) {
        self.arrowView.isHidden = hidden
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let callback = textViewBeginEditing {
            callback()
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let callback = textViewEndEditing {
            callback()
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        if let textViewText = textView.text {
            let prospectiveText = (textViewText as NSString).replacingCharacters(in: range, with: text)
            
            if let callback = self.textViewTextChanged {
                    callback(prospectiveText)
            }
        }
        
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
