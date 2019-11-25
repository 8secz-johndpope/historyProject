//
//  OrderStatusCell.swift
//  merchant-ios
//
//  Created by Gambogo on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderStatusCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderStatusCellID"
    
    private var borderBottomView = UIView()
    private var orderStatusLabel = UILabel()
    private var orderStatusImageView = UIImageView()
    private var orderStatusView = UIView()
    private var seperateDateView = UIView()
    private var dateValueLabel = UILabel()
    private var dateTitleLabel = UILabel()
    private var estimateDateValueLabel = UILabel()
    private var estimateDateTitleLabel = UILabel()
    private var orderDateView = UIView()
    
    var showInOrderList = false
    
    var orderCreatedDate: Date? {
        didSet {
            if let orderCreatedDate = self.orderCreatedDate {
                setDateValue(year: orderCreatedDate.year, month: orderCreatedDate.month, day: orderCreatedDate.day)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    var data: OrderStatusData? {
        didSet {
            if let data = self.data {
                let orderStatusDisplayInfo = data.getOrderStatusDisplayInfo(showInOrderList: showInOrderList)
                
                orderStatusLabel.text = orderStatusDisplayInfo.text
                self.orderStatusImageView.image = UIImage(named: orderStatusDisplayInfo.imageName)
                
                var orderDate: String = ""
                orderDate = data.orderDate
                dateValueLabel.text = orderDate
                
                estimateDateValueLabel.text = "- - -"
                estimateDateTitleLabel.text = "- - -"
                
                switch data.orderDisplayStatus {
                case .toBeShipped, .partialShip, .shipped:
                    estimateDateValueLabel.formatSize(10)
                default:
                    estimateDateValueLabel.formatSizeBold(13)
                }
                
                switch data.orderDisplayStatus {
                case .toBeShipped:
                    estimateDateTitleLabel.text = String.localize("LB_CA_OMS_EST_SHIPMENT")
                case .partialShip:
                    estimateDateTitleLabel.text = String.localize("LB_CA_OMS_EST_ARRIVE")
                case .shipped:
                    estimateDateTitleLabel.text = String.localize("LB_CA_OMS_EST_ARRIVE")
                case .received:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_RECEIVED")
                case .collected:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_COLLECTED")
                case .toBeCollected:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_TOBECOLLECTED")
                case .cancelRequested:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_CANCEL_REQUESTED")
                case .cancelAccepted:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_CANCEL_ACCEPTED")
                case .cancelRejected:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_CANCEL_REJECTED")
                case .refundAccepted:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_ACCEPT")
                case .returnRequestSubmitted:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_REQUESTED")
                case .returnRequestAuthorised:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_AUTH")
                case .returnRequestRejected:
                    estimateDateValueLabel.text = String.localize("LB_REJECT_REQUEST")
                case .returnAccepted:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_ACCEPT")
                case .returnRejected:
                    estimateDateValueLabel.text = String.localize("LB_RETURN_REJECT")
                case .disputeOpen:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_REQ")
                case .disputeInProgress:
                    estimateDateValueLabel.text = "\(data.estimatedDaysOfCompletion)" + String.localize("LB_CA_OMS_DAYS_TO_SHIP")
                    estimateDateTitleLabel.text = String.localize("LB_CA_OMS_RTN_RESPONSE")
                case .disputeAccepted:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_SUCCESS")
                case .disputeRejected:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_FAIL")
                case .returnRequestDeclinedCanNotDispute:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_RETURN_REQUEST_DECLINED_CANNOT_DISPUTE")
                case .returnRequestRejectedCanNotDispute:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_RETURN_REJECTED_CANNOT_DISPUTE")
                case .orderClosed:
                    estimateDateValueLabel.text = String.localize("LB_CA_OMS_ORDER_STATUS_CLOSED")
                default:
                    estimateDateValueLabel.text = ""
                    estimateDateTitleLabel.text = ""
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        // Order Status View
        orderStatusLabel.formatSize(13)
        orderStatusLabel.textColor = UIColor.primary1()
        orderStatusLabel.textAlignment = .left
        orderStatusView.addSubview(orderStatusLabel)
        orderStatusView.addSubview(orderStatusImageView)
        self.contentView.addSubview(orderStatusView)
        
        // Order Date View
        seperateDateView.backgroundColor = UIColor.secondary1()
        orderDateView.addSubview(seperateDateView)
        
        dateValueLabel.formatSizeBold(13)
        dateValueLabel.textAlignment = .right
        orderDateView.addSubview(dateValueLabel)
        
        dateTitleLabel.formatSize(10)
        dateTitleLabel.textAlignment = .right
        dateTitleLabel.text = String.localize("LB_CA_OMS_ORDER_DATE")   // TODO:
        orderDateView.addSubview(dateTitleLabel)
        
        estimateDateValueLabel.formatSizeBold(13)
        estimateDateValueLabel.textAlignment = .right
        orderDateView.addSubview(estimateDateValueLabel)
        
        estimateDateTitleLabel.formatSize(10)
        estimateDateTitleLabel.textAlignment = .right
        orderDateView.addSubview(estimateDateTitleLabel)
        
        self.contentView.addSubview(orderDateView)
        
        borderBottomView.backgroundColor = UIColor.backgroundGray()
        self.contentView.addSubview(borderBottomView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let statusImageSize = CGSize(width: 30, height: 30)
        let estimateDateLabelSize = CGSize(width: 60, height: 20)
        let dateLabelHeight: CGFloat = 20
        let dateLabelMargin: CGFloat = 5
        let leftPaddingContent: CGFloat = 20
        let paddingContent: CGFloat = 10
        
        // Layout Order Status View
        let widthOrderStatusView = self.frame.width * 3 / 7
        orderStatusView.frame = CGRect(x: 0, y: 0, width: widthOrderStatusView, height: self.frame.height)
        orderStatusImageView.frame = CGRect(x: leftPaddingContent, y: paddingContent, width: statusImageSize.width, height: statusImageSize.height)
        let OrderLabelMarginLeft = CGFloat(6)
        orderStatusLabel.frame = CGRect(x: orderStatusImageView.frame.maxX + OrderLabelMarginLeft, y: paddingContent, width: widthOrderStatusView - (orderStatusImageView.frame.maxX + 2 * paddingContent), height: self.frame.height - (2 * paddingContent))
        
        // Layout Order Date View
        let widthOrderDateView = self.frame.width * 4 / 7
        orderDateView.frame = CGRect(x: self.frame.maxX - widthOrderDateView - (2 * paddingContent), y: 0, width: widthOrderDateView, height: self.frame.height)
        estimateDateValueLabel.frame = CGRect(x: orderDateView.frame.width + 20, y: paddingContent, width: estimateDateLabelSize.width, height: estimateDateLabelSize.height)
        estimateDateTitleLabel.frame = CGRect(x: orderDateView.frame.width + 20, y: paddingContent + estimateDateLabelSize.height, width: estimateDateLabelSize.width, height: estimateDateLabelSize.height)
        //original: orderDateView.frame.width - (estimateDateLabelSize.width + dateLabelMargin)
        
        seperateDateView.frame = CGRect(x: estimateDateValueLabel.frame.originX - dateLabelMargin, y: paddingContent, width: 1, height: self.frame.sizeHeight - (2 * paddingContent))
        dateValueLabel.frame = CGRect(x: 0, y: paddingContent, width: seperateDateView.frame.minX - paddingContent, height: dateLabelHeight)
        dateTitleLabel.frame = CGRect(x: 0, y: paddingContent + dateLabelHeight, width: seperateDateView.frame.minX - paddingContent, height: dateLabelHeight)
        
        seperateDateView.isHidden = true
        estimateDateValueLabel.isHidden = true
        estimateDateTitleLabel.isHidden = true
        
        borderBottomView.frame = CGRect(x: paddingContent, y: frame.height - 1, width: frame.width - (2 * paddingContent), height: 1)
    }
    
    // MARK: - Views
    
    func setDateValue(year: Int, month: Int, day: Int) {
        dateValueLabel.text = String(year) + String.localize("LB_CA_YEAR") + String(month) + String.localize("LB_CA_MONTH") + String(day) + String.localize("LB_CA_DAY")
    }
    
}
