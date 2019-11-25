//
//  AfterSalesReasonCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesReasonCell: UICollectionViewCell {
    
    static let CellIdentifier = "AfterSalesReasonCellID"
    
    var viewType: AfterSalesViewController.ViewType = .unknown
    
    var leftLabel: UILabel!
    var textField: UITextField!
    private var disclosureIndicatorImageView = UIImageView()
    private var disclosureIndicatorButton = UIButton()
    private var borderView = UIView()
    
    var rightViewTapHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        leftLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 20, y: 0, width: 70, height: frame.height))
            label.formatSize(15)
            return label
        } ()
        contentView.addSubview(leftLabel)
        
        textField = { () -> UITextField in
            let textField = UITextField()
            textField.noBorderFormatWithSize(15)
            textField.textAlignment = .right
            textField.textColor = UIColor.secondary2()
            return textField
        } ()
        contentView.addSubview(textField)
        
        disclosureIndicatorImageView.image = UIImage(named: "icon_arrow_small")
        addSubview(disclosureIndicatorImageView)
        
        disclosureIndicatorButton = UIButton(type: .custom)
        disclosureIndicatorButton.addTarget(self, action: #selector(buttonOnTap), for: .touchUpInside)
        addSubview(disclosureIndicatorButton)
        
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch viewType {
        case .cancel:
            leftLabel.text = String.localize("LB_CA_REFUND_REASON")
        case .return:
            leftLabel.text = String.localize("LB_CA_RETURN_REASON")
        case .dispute:
            leftLabel.text = String.localize("LB_DISPUTE_REASON")
        case .reportReview:
            leftLabel.text = String.localize("LB_CA_REPORT_POST_REASON")
        default:
            break
        }
        
        borderView.frame = CGRect(x: 10, y: bounds.maxY - 1, width: bounds.width - 20, height: 1)
        
        let arrowSize = CGSize(width: 32, height: 32)
        disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - arrowSize.width - 10, y: bounds.midY - arrowSize.width / 2 - 1, width: arrowSize.width, height: arrowSize.height)
        
        let widthTextField = frame.width - leftLabel.frame.maxX - disclosureIndicatorImageView.frame.width - 30
        textField.frame = CGRect(x: disclosureIndicatorImageView.frame.minX - widthTextField, y: 0, width: widthTextField, height: frame.height)
        disclosureIndicatorButton.frame = CGRect(x: textField.frame.maxX, y: 0, width: bounds.width - textField.frame.maxX, height: frame.height)
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    func viewDidTapped() {
        if let callback = self.rightViewTapHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func buttonOnTap() {
		NotificationCenter.default.post(name: Constants.Notification.reportReviewListShown, object: nil)
        textField.becomeFirstResponder()
    }
}
