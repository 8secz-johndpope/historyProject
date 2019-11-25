//
//  OrderUnpaidActionCell.swift
//  merchant-ios
//
//  Created by Jerry Chong on 1/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import SnapKit

class OrderUnpaidActionCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderUnpaidActionCellID"

    open var payHandler: (() -> Void)?
    open var cancelOrderHandler: (() -> Void)?
    var parentOrder: ParentOrder?
    
    enum OrderActionButtonType: Int {
        case pay = 0,
        cancel
    }
    
    private final var ActionButtonLabels = [String.localize("LB_CA_UNPAID_ORDER_TO_PAY"),
                                            String.localize("LB_CA_COUPON_UNBUNDLE_CANCEL_ORDER")]
    
    private final let PaddingContent: CGFloat = 14
    private final let MainActionButtonSize = CGSize(width: 120, height: Constants.ActionButton.Height)
    private final let ActionButtonSize = CGSize(width: 90, height: Constants.ActionButton.Height)
    
    var lastCreateDate: Date?
    
    private let payButton: ActionButton = {
        let button = ActionButton(frame: CGRect.zero)
        button.tag = OrderActionButtonType.pay.rawValue
        button.backgroundColor = UIColor.primary1()
        button.layer.borderColor = UIColor.primary1().cgColor
        button.setTitleColor(UIColor.white, for: UIControlState())
        return button
    }()
    
    private let cancelButton: ActionButton = {
        let button = ActionButton(frame: CGRect.zero)
        button.tag = OrderActionButtonType.cancel.rawValue
        button.setTitleColor(UIColor.secondary2(), for: UIControlState())
        return button
    }()
    
    var triangleImageView = UIImageView(image: UIImage(named: "triangle_down"))

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        let triangleImageViewSize = CGSize(width: 18, height: 8)
        triangleImageView.frame = CGRect(x: frame.width - (ActionButtonSize.width + triangleImageViewSize.width) / 2 - PaddingContent, y: 0, width: triangleImageViewSize.width, height: triangleImageViewSize.height)
        contentView.addSubview(triangleImageView)
        uiUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTimeNotification), name: Constants.Notification.updateTimeNotification,object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self, name: Constants.Notification.updateTimeNotification, object: nil)
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
                    
                    let wholeTimeText = ActionButtonLabels[OrderActionButtonType.pay.rawValue].replacingOccurrences(of: "{0}", with: timeText)
                    payButton.setTitle(wholeTimeText, for: UIControlState())
                    payButton.isUserInteractionEnabled = true
                    payButton.formatPrimary()
                } else {
                    payButton.formatDisable()
                    payButton.isUserInteractionEnabled = false
                    payButton.setTitle(ActionButtonLabels[OrderActionButtonType.pay.rawValue].replacingOccurrences(of: " ({0}s)", with: ""), for: UIControlState())
                    payButton.layer.borderColor = UIColor.secondary1().cgColor
                    
                    cancelButton.formatDisable()
                    cancelButton.isUserInteractionEnabled = false
                    cancelButton.layer.borderColor = UIColor.secondary1().cgColor
                }
            }
        }
    }
    
    
    private func uiUpdate(){
        addSubview(payButton)
        addSubview(cancelButton)
        
        payButton.setTitle(String.localize("LB_CA_UNPAID_ORDER_TO_PAY").replacingOccurrences(of: " ({0}s)", with: ""), for: UIControlState())
        payButton.addTarget(self, action: #selector(actionButtonControl), for: .touchUpInside)
        
        cancelButton.setTitle(ActionButtonLabels[OrderActionButtonType.cancel.rawValue], for: UIControlState())
        cancelButton.addTarget(self, action: #selector(actionButtonControl), for: .touchUpInside)
        
        payButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(Constants.ActionButton.Height)
            target.width.equalTo(120)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            target.bottom.equalTo(0)
        }
        
        cancelButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(Constants.ActionButton.Height)
            target.width.equalTo(90)
            target.right.equalTo(strongSelf.payButton.snp.left).offset(-15)
            target.bottom.equalTo(0)
        }
    }
    
    // MARK: - Action
    @objc private func actionButtonControl(_ sender: UIButton){
        print("actionButtonControl")
        if let tag = OrderActionButtonType(rawValue: sender.tag) {
            switch tag {
            case .pay:
                doPay()
            case .cancel:
                doCancelOrder()
            }
        }
    }
    
    private func doPay(){
        print("pay")
        if let callback = self.payHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func doCancelOrder() {
        if let callback = self.cancelOrderHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}

