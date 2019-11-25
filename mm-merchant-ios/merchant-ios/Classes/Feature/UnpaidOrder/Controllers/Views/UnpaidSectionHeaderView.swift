//
//  UnpaidSectionHeaderView.swift
//  merchant-ios
//
//  Created by Jerry Chong on 1/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import SnapKit

class UnpaidSectionHeaderView: UICollectionReusableView {
    
    static let ViewIdentifier = "UnpaidSectionHeaderView"
    static let DefaultHeight: CGFloat = 70
    
    private final let ArrowSize = CGSize(width: 32, height: 32)
    
    private var mainView = UIView()
    private var borderTopView = UIView()
    private var borderBottomView = UIView()
    private var orderStatusImageView = UIImageView()
    private var statusLabel = UILabel()
    private var dateValueLabel = UILabel()
    private var dateTitleLabel = UILabel()
    private var orderDateView = UIView()
    
    private let transparentButton: UIButton = {
        let button = ActionButton(frame: CGRect.zero)
        button.backgroundColor = UIColor.clear
        button.layer.borderWidth = 0
        return button
    }()
    
    var headerTapHandler: (() -> Void)?
    
    var orderCreatedDate: Date? {
        didSet {
            if let orderCreatedDate = self.orderCreatedDate {
                setDateValue(year: orderCreatedDate.year, month: orderCreatedDate.month, day: orderCreatedDate.day)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    var data: ParentOrder? {
        didSet {
                self.orderStatusImageView.image = UIImage(named: "icon_order_timeline_created_active")
                statusLabel.text = String.localize("LB_CA_UNPAID_ORDER_PENDING_PAYMENT")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        
        mainView.backgroundColor = UIColor.white
        addSubview(mainView)
        // Order Date View
        mainView.addSubview(orderStatusImageView)
        
        statusLabel.formatSize(13)
        statusLabel.textColor = UIColor.primary1()
        statusLabel.textAlignment = .left
        mainView.addSubview(statusLabel)

        dateValueLabel.formatSizeBold(13)
        dateValueLabel.textAlignment = .right
        mainView.addSubview(dateValueLabel)
        
        dateTitleLabel.formatSize(10)
        dateTitleLabel.textAlignment = .right
        dateTitleLabel.text = String.localize("LB_CA_OMS_ORDER_DATE")   // TODO:
        mainView.addSubview(dateTitleLabel)
        
//        mainView.addSubview(orderDateView)
        borderTopView.backgroundColor = UIColor.backgroundGray()
        mainView.addSubview(borderTopView)
        borderBottomView.backgroundColor = UIColor.backgroundGray()
        mainView.addSubview(borderBottomView)
        
        
        mainView.addSubview(transparentButton)
        transparentButton.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let dateLabelHeight: CGFloat = 20
        let paddingContent: CGFloat = 10
        
        mainView.snp.makeConstraints{
            (target) in
            target.top.equalTo(10)
            target.bottom.equalTo(0)
            target.left.right.equalTo(0)
        }
        
        orderStatusImageView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.width.equalTo(32)
            target.left.equalTo(strongSelf.snp.left).offset(15)
            target.centerY.equalTo(mainView)
        }
        
        statusLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(dateLabelHeight)
            target.width.equalTo(200)
            target.left.equalTo(strongSelf.orderStatusImageView.snp.right).offset(5)
            target.centerY.equalTo(mainView)
        }
        
        dateValueLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(dateLabelHeight)
            target.width.equalTo(200)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            target.top.equalTo(paddingContent)
        }
        
        dateTitleLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(dateLabelHeight)
            target.width.equalTo(200)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            target.top.equalTo(strongSelf.dateValueLabel.snp.bottom).offset(1)
            
        }
        
        borderBottomView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(1)
            target.left.right.equalTo(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(0)
        }
        
        borderTopView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(1)
            target.left.right.equalTo(0)
            target.top.equalTo(strongSelf.snp.top).offset(0)
        }
        
        transparentButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(0)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.right.equalTo(strongSelf.snp.right).offset(0)
        }
 
    }
    
    @objc func headerTapped() {
        if let callback = self.headerTapHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func setDateValue(year: Int, month: Int, day: Int) {
        dateValueLabel.text = String(year) + String.localize("LB_CA_YEAR") + String(month) + String.localize("LB_CA_MONTH") + String(day) + String.localize("LB_CA_DAY")
    }
}
