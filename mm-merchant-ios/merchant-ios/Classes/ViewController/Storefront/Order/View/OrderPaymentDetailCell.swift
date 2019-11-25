//
//  OrderPaymentDetailCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 24/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class OrderPaymentDetailCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderPaymentDetailCellID"
    static let BasicHeight: CGFloat = 50
    static let ExtraHeight: CGFloat = 18
    
    private var imageView = UIImageView()
    private var titleLabel = UILabel()
    private var timeLabel = UILabel()
    private var amountLabel = UILabel()
    private var referenceCodeLabel = UILabel()
    private var bottomBorderView = UIView()
    
    var orderTransaction: OrderTransaction? {
        didSet {
            if let orderTransaction = self.orderTransaction {
                switch orderTransaction.paymentRecordType {
                case .alipayPayment:
                    imageView.image = UIImage(named: "icon_transaction_alipay")
                    titleLabel.text = String.localize("LB_CA_ALIPAY_PAYMENT")
                case .customerExtraPayment:
                    imageView.image = UIImage(named: "icon_transaction_extraPaid")
                    titleLabel.text = String.localize("LB_CA_EXTRA_PAYMENT")
                case .alipayRefund:
                    imageView.image = UIImage(named: "icon_transaction_alipay")
                    titleLabel.text = String.localize("LB_CA_ALIPAY_REFUND")
                case .platformExtraRefund:
                    imageView.image = UIImage(named: "icon_transaction_refund")
                    titleLabel.text = String.localize("LB_CA_EXTRA_REFUND")
                case .wechatpayPayment:
                    imageView.image = UIImage(named: "icon_transation_wechat")
                    titleLabel.text = String.localize("LB_CA_PAYMENT_WECHAT")
                case .wechatpayRefund:
                    imageView.image = UIImage(named: "icon_transation_wechat")
                    titleLabel.text = String.localize("LB_CA_REFUND_WECHAT")
                default:
                    break
                }
                
                timeLabel.text = Constants.DateFormatter.getFormatter("yyyy-MM-dd HH:mm:ss").string(from: orderTransaction.lastCompleted)
                
                if orderTransaction.transactionType == .payment {
                    let amount = Double(orderTransaction.amount)
                    amountLabel.text = amount.formatPrice()
                    amountLabel.textColor = UIColor.secondary2()
                } else {
                    let amount = Double(orderTransaction.amount)
                    amountLabel.text = (0 - amount).formatPrice()
                    amountLabel.textColor = UIColor.primary1()
                }
                
                if orderTransaction.referenceNo == "" {
                    referenceCodeLabel.text = ""
                    referenceCodeLabel.isHidden = true
                } else {
                    referenceCodeLabel.text = orderTransaction.referenceNo
                    referenceCodeLabel.isHidden = false
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        contentView.addSubview(imageView)
        
        titleLabel.formatSize(10)
        titleLabel.textColor = UIColor.secondary2()
        contentView.addSubview(titleLabel)
        
        timeLabel.formatSize(10)
        timeLabel.textColor = UIColor.secondary2()
        contentView.addSubview(timeLabel)
        
        amountLabel.formatSize(12)
        amountLabel.textColor = UIColor.secondary2()
        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
        
        referenceCodeLabel.formatSize(12)
        referenceCodeLabel.adjustsFontSizeToFitWidth = true
        referenceCodeLabel.minimumScaleFactor = 0.4
        referenceCodeLabel.numberOfLines = 1
        referenceCodeLabel.textColor = UIColor.secondary2()
        contentView.addSubview(referenceCodeLabel)
        
        bottomBorderView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(bottomBorderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let topMargin: CGFloat = 8
        let leftMargin: CGFloat = 15
        let rightMargin: CGFloat = 25
        let smallLabelHeight: CGFloat = 14
        let largeLabelHeight: CGFloat = 18
        let amountLabelWidth: CGFloat = 100
        let paddingContent: CGFloat = 8
        
        imageView.frame = CGRect(x: leftMargin, y: topMargin, width: 28, height: 28)
        
        amountLabel.frame = CGRect(x: frame.width - rightMargin - amountLabelWidth, y: topMargin, width: amountLabelWidth, height: largeLabelHeight)
        
        let titleLabelWidth = amountLabel.x - leftMargin - imageView.width - 6
        
        titleLabel.frame = CGRect(x: leftMargin + imageView.width + 6, y: topMargin, width: titleLabelWidth, height: smallLabelHeight)
        
        timeLabel.frame = CGRect(x: titleLabel.x, y: imageView.frame.maxY - smallLabelHeight, width: titleLabel.width, height: smallLabelHeight)
        
        referenceCodeLabel.frame = CGRect(x: titleLabel.x, y: imageView.frame.maxY + 4, width: titleLabel.width + amountLabel.width, height: smallLabelHeight)
        
        bottomBorderView.frame = CGRect(x: paddingContent, y: frame.height - 1, width: frame.width - (paddingContent * 2), height: 1)
    }
}
