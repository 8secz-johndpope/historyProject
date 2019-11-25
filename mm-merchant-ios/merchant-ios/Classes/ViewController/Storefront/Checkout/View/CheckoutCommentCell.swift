//
//  CheckoutCommentCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 23/12/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CheckoutCommentCell: UICollectionViewCell, UITextViewDelegate {
    
    static let CellIdentifier = "CheckoutCommentCellID"
    static let CommentPlaceholder = String.localize("LB_CA_OMS_ORDER_DETAIL_NOTE")
    
    var textView: UITextView!
    
    var textViewBeginEditing: ((_ cell: CheckoutCommentCell) -> Void)?
    var textViewEndEditing: ((_ cell: CheckoutCommentCell) -> Void)?
    var textViewDidChange: ((_ cell: CheckoutCommentCell) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let leftPadding: CGFloat = 12
        let topPadding: CGFloat = 13
        let containerHeight: CGFloat = 74
        
        textView = { () -> UITextView in
            let textView = UITextView(frame: CGRect(x: leftPadding, y: topPadding, width: self.width - 2 * leftPadding, height: containerHeight))
            textView.textColor = UIColor.secondary3()
            textView.font = UIFont.systemFont(ofSize: 14)
            textView.text = CheckoutCommentCell.CommentPlaceholder
            textView.returnKeyType = .done
            textView.delegate = self
            
            return textView
        } ()
        
        addSubview(textView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let callback = self.textViewBeginEditing {
            callback(self)
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let callback = self.textViewEndEditing {
            callback(self)
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if let callback = self.textViewDidChange {
            callback(self)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        if textView == self.textView {
            let currentText = textView.text as NSString
            let proposedText = currentText.replacingCharacters(in: range, with: text)
            
            if proposedText.count > Constants.CharacterLimit.CheckoutComment {
                return false
            }
        }
        
        return true
    }
    
    func setEnable(_ enable: Bool){
        textView.isUserInteractionEnabled = enable
    }
    
}
