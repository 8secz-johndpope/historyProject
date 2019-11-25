//
//  AfterSalesDescriptionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesDescriptionCell: UICollectionViewCell, UITextViewDelegate {
    
    static let CellIdentifier = "AfterSalesDescriptionCellID"
    
    private final let SizeLabelCharactersCount = CGSize(width: 80, height: 13)
    
    var viewType: AfterSalesViewController.ViewType = .unknown
    
    var descriptionTextView = UITextView()
    var characterCountLabel = UILabel()
    private var borderView = UIView()
    
    var characterLimit = 0
    var placeHolder = String.localize("LB_CA_PROD_REVIEW_NOTE")
    
    var textViewBeginEditing: (() -> Void)?
    var textViewEndEditing: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        descriptionTextView.text = placeHolder
        descriptionTextView.textColor = UIColor.secondary1()
        descriptionTextView.delegate = self
        addSubview(descriptionTextView)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        
        characterCountLabel.formatSize(12)
        characterCountLabel.textColor = UIColor.secondary1()
        characterCountLabel.text = "0/\(characterLimit)"
        characterCountLabel.textAlignment = .right
        characterCountLabel.isHidden = false
        addSubview(characterCountLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let descriptionTextViewPadding: CGFloat = 15
        borderView.frame = CGRect(x: 10, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
        
        var paddingBottom: CGFloat = 15
        if !characterCountLabel.isHidden {
            paddingBottom += 12
            characterCountLabel.frame = CGRect(x: frame.width - SizeLabelCharactersCount.width - 10, y: frame.height - SizeLabelCharactersCount.height - 5, width: SizeLabelCharactersCount.width, height: SizeLabelCharactersCount.height)
        }
        
        if let descriptionFont = descriptionTextView.font {
            descriptionTextView.font = UIFont(name: descriptionFont.fontName, size: 14.0)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        descriptionTextView.frame = CGRect(x: descriptionTextViewPadding, y: 10, width: frame.width - 2 * descriptionTextViewPadding, height: frame.height - paddingBottom)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func setDescriptionText(_ text: String) {
        if text.isEmpty {
            descriptionTextView.text = placeHolder
            descriptionTextView.textColor = UIColor.secondary1()
            characterCountLabel.text = "0/\(characterLimit)"
        } else {
            descriptionTextView.text = text
            characterCountLabel.text = "\(text.count)/\(characterLimit)"
            descriptionTextView.textColor = UIColor.secondary2()
        }
    }
    
    func updateDescriptionCharactersCount(_ characterCount: Int) {
        characterCountLabel.text = "\(characterCount)/\(characterLimit)"
        descriptionTextView.textColor = UIColor.secondary2()
    }
    
    func getDescriptionText() -> String {
        if self.isEmptyDescription() {
            return ""
        }
        
        return self.descriptionTextView.text
    }
    
    func isEmptyDescription () -> Bool {
        return descriptionTextView.textColor == UIColor.secondary1()
    }
    
    //MARK: - Text View Delegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.textColor == UIColor.secondary1() {
            textView.textColor = UIColor.secondary2()
            textView.text = nil
        }
        
        if let callback = textViewBeginEditing {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = placeHolder
            textView.textColor = UIColor.secondary1()
        }
        
        if let callback = textViewEndEditing {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.descriptionTextView {
            if textView.text.isEmpty {
                textView.textColor = UIColor.secondary1()
            } else {
                textView.textColor = UIColor.secondary2()
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == self.descriptionTextView {
            let currentText = textView.text as NSString
            let proposedText = currentText.replacingCharacters(in: range, with: text)
            if proposedText.count > characterLimit {
                return false
            }
            
            characterCountLabel.text = "\(proposedText.count)/\(characterLimit)"
        }
        
        return true
    }
}
