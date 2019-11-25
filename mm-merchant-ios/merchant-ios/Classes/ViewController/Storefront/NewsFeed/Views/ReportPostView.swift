//
//  ReportPostView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 5/17/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ReportPostView: UIView, UITextViewDelegate {
    private final let HeightOfDecriptionView: CGFloat = 150.0
    private final let HeightOfLabel: CGFloat = 44.0
    private final let HeightOfViewBottom: CGFloat = 50
    private final let WidthOfLabelReason : CGFloat = 100
    private final let HeightOfArrow: CGFloat = 5
    private final let WidthOfArrow: CGFloat = 10
    private final let MarginLeftRight: CGFloat = 15
    private final let MarginTop : CGFloat = 64
    private final let WidthOfSubmitButton : CGFloat = 90
    var buttonArrow = UIButton(type: UIButtonType.custom)
    var buttonSelectReason = UIButton(type: UIButtonType.custom)
    var labelReason = UILabel()
    var textViewDescription = MMPlaceholderTextView()
    var textfieldSelectReason = UITextField()
    var viewBottom = UIView()
    var buttonSubmit = UIButton()
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        labelReason.format()
        labelReason.numberOfLines = 1
        labelReason.text =  String.localize("LB_CA_REPORT_POST_REASON")
        self.addSubview(labelReason)
        
        textfieldSelectReason.format()
        textfieldSelectReason.layer.borderWidth = 0
        textfieldSelectReason.placeholder = String.localize("LB_CA_REPORT_POST_SELECT_REASON") + "  "
        textfieldSelectReason.textAlignment = .right
        self.addSubview(textfieldSelectReason)
        buttonArrow.setImage(UIImage(named: "arrow_open"), for: UIControlState.selected)
        buttonArrow.setImage(UIImage(named: "arrow_close"), for: UIControlState())
        self.addSubview(buttonArrow)
      
        textViewDescription.placeholder = String.localize("LB_CA_REPORT_POST_DESC")
        textViewDescription.format()
        textViewDescription.delegate = self
        textViewDescription.layer.borderWidth = 0
        self.addSubview(textViewDescription)
        
        var viewLine = UIView(frame: CGRect(x: 0, y: MarginTop, width: bounds.width, height: 1))
        viewLine.backgroundColor = UIColor.secondary1()
        self.addSubview(viewLine)
        viewLine = UIView(frame: CGRect(x: 0, y: MarginTop + HeightOfLabel, width: bounds.width, height: 1))
        viewLine.backgroundColor = UIColor.secondary1()
        self.addSubview(viewLine)
        viewLine = UIView(frame: CGRect(x: 0, y: MarginTop + HeightOfLabel + HeightOfDecriptionView, width: bounds.width, height: 1))
        viewLine.backgroundColor = UIColor.secondary1()
        self.addSubview(viewLine)
        self.addSubview(buttonSelectReason)
        viewLine = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 1))
        viewLine.backgroundColor = UIColor.secondary1()
        self.viewBottom.addSubview(viewLine)
        buttonSubmit.formatSecondary()
        buttonSubmit.setTitleColor(UIColor.primary1(), for: UIControlState())
        buttonSubmit.setTitle(String.localize("LB_CA_SUBMIT"), for: UIControlState())
        self.viewBottom.addSubview(buttonSubmit)
        self.addSubview(viewBottom)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        labelReason.frame = CGRect(x: MarginLeftRight, y: MarginTop, width: WidthOfLabelReason, height: HeightOfLabel)
        textfieldSelectReason.frame = CGRect(x: WidthOfLabelReason + MarginLeftRight, y: MarginTop, width: bounds.maxX - (WidthOfLabelReason + MarginLeftRight * 2 + WidthOfArrow), height: HeightOfLabel)
        buttonArrow.frame = CGRect(x: self.bounds.width - (WidthOfArrow + MarginLeftRight), y: MarginTop  + ( HeightOfLabel - HeightOfArrow) / 2, width: WidthOfArrow, height: HeightOfArrow)
        buttonSelectReason.frame =  CGRect(x: WidthOfLabelReason + MarginLeftRight * 2, y: MarginTop, width: bounds.maxX - (WidthOfLabelReason + MarginLeftRight), height: HeightOfLabel)
        textViewDescription.frame = CGRect(x: 10, y: self.labelReason.frame.maxY, width: bounds.width - 20, height: HeightOfDecriptionView)
        
        buttonSubmit.frame = CGRect(x: bounds.width - (WidthOfSubmitButton + MarginLeftRight), y: (HeightOfViewBottom - 30) / 2, width: WidthOfSubmitButton , height: 30)
        viewBottom.frame = CGRect(x: 0, y: bounds.height - HeightOfViewBottom, width: bounds.width, height: HeightOfViewBottom)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.text.count + (text.count - range.length) <= 140
    }
    
    func handleKeyboard(_ isShow: Bool, notification: Notification) {
    
            if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
                let keyboardSize = keyboardFrame.cgRectValue.size
                if isShow {
                    viewBottom.frame = CGRect(x: 0, y: bounds.height - (HeightOfViewBottom + keyboardSize.height), width: bounds.width, height: HeightOfViewBottom)
                } else {
                    viewBottom.frame = CGRect(x: 0, y: bounds.height - HeightOfViewBottom, width: bounds.width, height: HeightOfViewBottom)
                }
            }
      

    }
}
