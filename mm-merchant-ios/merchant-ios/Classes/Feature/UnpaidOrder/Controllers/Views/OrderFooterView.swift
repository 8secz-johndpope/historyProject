//
//  OrderFooterView.swift
//  merchant-ios
//
//  Created by Jerry Chong on 6/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

import SnapKit

class OrderFooterView: UIView {
    static let DefaultHeight: CGFloat = 115
    
    var lastCreateDate: Date?
    private var parentOrder: ParentOrder?
    private var fromViewController: UIViewController?
    var payHandler: (() -> Void)?
    private let payButton: UIButton = {
        let button = UIButton()
        button.formatPrimary()
        button.setTitle(String.localize("LB_CA_UNPAID_ORDER_TO_PAY").replacingOccurrences(of: " ({0}s)", with: ""), for: UIControlState())
        return button
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.text = String.localize("LB_CA_EDITITEM_SUBTOTAL")
        label.formatSize(14)
        label.sizeToFit()
        return label
    }()
    
    private let totalValueLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.formatSizeBold(14)
        label.textColor = UIColor.primary1()
        label.sizeToFit()
        return label
    }()
    
    private let totalSavedLabel: UILabel = {
        let label = UILabel()
        label.formatSize(14)
        label.text = String.localize("LB_CA_CHECKOUT_COUPON_SAVED")
        label.textColor = UIColor.secondary3()
        return label
    }()
    
    private let topLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.backgroundGray()
        return view
    }()
    
    deinit{
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.updateTimeNotification, object: nil)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        addSubview(payButton)
        addSubview(totalLabel)
        addSubview(totalValueLabel)
        addSubview(totalSavedLabel)
        addSubview(topLineView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTimeNotification), name: Constants.Notification.updateTimeNotification,object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func updateTimeNotification(_ notification: Notification){
        if let lastCreateDate = lastCreateDate {
            let timeup = lastCreateDate.addingTimeInterval(15*60)
            if let currentTime = TimestampService.defaultService.getServerTime() {
                let distanceBetweenDates = timeup.timeIntervalSince(currentTime as Date)
                if distanceBetweenDates > 0 {
                    var minutesText = Int((distanceBetweenDates / 60).truncatingRemainder(dividingBy: 60)).description
                    if minutesText.count == 1 {
                        minutesText = "0" + minutesText
                    }
                    var secondsText = Int(distanceBetweenDates.truncatingRemainder(dividingBy: 60)).description
                    if secondsText.count == 1 {
                        secondsText = "0" + secondsText
                    }
                    let timeText = minutesText + ":" + secondsText
                    
                    let wholeTimeText = String.localize("LB_CA_UNPAID_ORDER_TO_PAY").replacingOccurrences(of: "{0}", with: timeText)
                    payButton.setTitle(wholeTimeText, for: UIControlState())
                    payButton.addTarget(self, action: #selector(actionPay), for: .touchUpInside)
                    payButton.isUserInteractionEnabled = true
                    payButton.formatPrimary()
                }else{
                    payButton.formatDisable()
                    payButton.isUserInteractionEnabled = false
                    payButton.setTitle(String.localize("LB_CA_UNPAID_ORDER_TO_PAY").replacingOccurrences(of: " ({0}s)", with: ""), for: UIControlState())
                    payButton.layer.borderColor = UIColor.secondary1().cgColor
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        payButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(40)
            target.width.equalTo(100)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            target.centerY.equalTo(strongSelf)
        }
        
        totalLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(20)
            target.width.equalTo(30)
            target.left.equalTo(strongSelf.snp.left).offset(15)
            target.top.equalTo(strongSelf.snp.top).offset(12)
        }
        
        totalValueLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(20)
            target.width.equalTo(100)
            target.left.equalTo(strongSelf.totalLabel.snp.right).offset(5)
            target.top.equalTo(strongSelf.snp.top).offset(12)
        }
        
        totalSavedLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(20)
            target.width.equalTo(100)
            target.left.equalTo(strongSelf.snp.left).offset(15)
            target.top.equalTo(strongSelf.totalLabel.snp.bottom).offset(-2)
        }
        
        
        topLineView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(1)
            target.left.right.equalTo(0)
            target.top.equalTo(strongSelf.snp.top).offset(0)
        }
    }
    
    func setData(_ grandTotal: Double, saveTotal: Double){
        totalLabel.sizeToFit()
        totalValueLabel.text = grandTotal.formatPrice()
        totalSavedLabel.text = String.localize("LB_CA_CHECKOUT_COUPON_SAVED").replacingOccurrences(of: "{SavedAmount}", with: saveTotal.description)
    }
    
    func setParentOrder(_ parentOrder: ParentOrder, vc: UIViewController){
        self.parentOrder = parentOrder
        self.fromViewController = vc
    }
    
    @objc private func actionPay(_ sender: UIButton){
        if let callback = self.payHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}
