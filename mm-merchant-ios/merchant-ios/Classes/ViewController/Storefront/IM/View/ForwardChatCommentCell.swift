//
//  ForwardChatCommentCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ForwardChatCommentCell: UICollectionViewCell, UITextViewDelegate {
    
    var tvComment: UITextView!
    var textViewBeginEditting: (() -> Void)?
    var textViewEndEditting: (() -> Void)?

    private final let CommentPlaceHolder = String.localize("LB_CS_COMMENT_TEXTBOX")
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let Margin = CGFloat(5)
        
        tvComment = { () -> UITextView in
            let textView = UITextView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
            textView.textColor = UIColor.secondary3()
            textView.font = UIFont.systemFont(ofSize: 14)
            textView.text = CommentPlaceHolder

            if textView.delegate == nil {
                textView.delegate = self
            }
            
            return textView
        }()
        contentView.addSubview(tvComment)
        
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: Margin, y: frame.size.height - 1, width: frame.width - (2 * Margin), height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        contentView.addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textViewBeginEditting?()
        
        if textView.textColor == UIColor.secondary3() {
            textView.text = nil
            textView.textColor = UIColor.black
        }

        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textViewEndEditting?()
        
        if textView.text.isEmpty {
            textView.text = CommentPlaceHolder
            textView.textColor = UIColor.secondary3()
        }

    }
}
