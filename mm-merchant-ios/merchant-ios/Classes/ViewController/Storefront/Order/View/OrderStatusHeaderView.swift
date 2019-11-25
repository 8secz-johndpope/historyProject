//
//  OrderStatusHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderStatusHeaderView: UICollectionReusableView {
    
    private let MaxStatusNumber = 5
    
    struct OrderStatusItem {
        var title = ""
        var activeImageName = ""
        var inactiveImageName = ""
        var dateText = ""
        var timelineStatus: TimelineStatus = .unknown
        
        init(title: String, imageNamePrefix: String, dateText: String, timelineStatus: TimelineStatus = .unknown) {
            self.title = title
            self.activeImageName = "\(imageNamePrefix)_active"
            self.inactiveImageName = "\(imageNamePrefix)_inactive"
            self.dateText = dateText
            self.timelineStatus = timelineStatus
        }
    }
    
    static let ViewIdentifier = "OrderStatusHeaderViewID"
    static let DefaultHeight: CGFloat = 139
    
    enum TimelineStatus: Int {
        case unknown = 0,
        created,
        toBeShipped,
        shipped,
        received,
        reviewed
    }
    
    var titleText = ""
    var descriptionText = "---"
    
    private var titleLabel: UILabel?
    private var descriptionLabel: UILabel?
    
    private var currentTimelineStatus: TimelineStatus = .unknown {
        didSet {
            self.loadSubviews()
        }
    }
    
    private let OrderStatusItems = [
        OrderStatusItem(title: String.localize("LB_CA_OMS_TIMELINE_STATUS_PAID"), imageNamePrefix: "icon_order_timeline_created", dateText: String.localize("LB_CA_DAY"), timelineStatus: .created),
        OrderStatusItem(title: String.localize("LB_CA_OMS_TIMELINE_STATUS_TO_BE_SHIPPED"), imageNamePrefix: "icon_order_timeline_waitingShipped", dateText: String.localize("LB_CA_DAY"), timelineStatus: .toBeShipped),
        OrderStatusItem(title: String.localize("LB_CA_OMS_TIMELINE_STATUS_IN_TRANSIT"), imageNamePrefix: "icon_order_timeline_shipped", dateText: String.localize("LB_CA_DAY"), timelineStatus: .shipped),
        OrderStatusItem(title: String.localize("LB_CA_OMS_TIMELINE_STATUS_CONF_RCVD"), imageNamePrefix: "icon_order_timeline_received", dateText: String.localize("LB_CA_DAY"), timelineStatus: .received),
        OrderStatusItem(title: String.localize("LB_CA_OMS_TIMELINE_STATUS_RATE"), imageNamePrefix: "icon_order_timeline_commented", dateText: String.localize("LB_CA_DAY"), timelineStatus: .reviewed)
    ]
    
    private var currentOrderStatusItems = [OrderStatusItem]()
    
    var data: OrderSectionData?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func loadSubviews(){
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        
        let orderStatusLabelWidth: CGFloat = 50
        let labelHeight: CGFloat = 18
        let marginTop: CGFloat = 14
        var marginHorizontal: CGFloat = 16
        let imageViewSize = CGSize(width: 32, height: 32)
        var imageViewSpacingX: CGFloat = (bounds.width - (marginHorizontal * 2) - (imageViewSize.width * CGFloat(currentOrderStatusItems.count))) / CGFloat(currentOrderStatusItems.count - 1)
        let defaltImageViewSpacingX = (bounds.width - (marginHorizontal * 2) - (imageViewSize.width * CGFloat(MaxStatusNumber))) / CGFloat(MaxStatusNumber - 1)
        
        if currentOrderStatusItems.count < MaxStatusNumber {
            imageViewSpacingX = defaltImageViewSpacingX
            marginHorizontal = (bounds.width - CGFloat(currentOrderStatusItems.count) * imageViewSize.width - CGFloat(currentOrderStatusItems.count - 1) * defaltImageViewSpacingX) / 2
        }
        
        let imageViewSpacingY: CGFloat = 10
        
        titleLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 0, y: marginTop, width: ScreenWidth, height: labelHeight))
            label.formatSizeBold(15)
            label.textAlignment = .center
            label.text = titleText
            return label
        } ()
        addSubview(titleLabel!)
        
        descriptionLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 0, y: titleLabel!.frame.maxY, width: ScreenWidth, height: labelHeight))
            label.formatSize(13)
            label.tintColor = UIColor.secondary2()
            label.textAlignment = .center
            label.text = descriptionText
            return label
        } ()
        addSubview(descriptionLabel!)
        
        for index in 0..<currentOrderStatusItems.count {
            let orderStatusItem = currentOrderStatusItems[index]
            
            let orderStatusImageView = { () -> UIImageView in
                let imageView = UIImageView(frame: CGRect(x: marginHorizontal + CGFloat(index) * (imageViewSize.width + imageViewSpacingX), y: marginTop + titleLabel!.height + descriptionLabel!.height + imageViewSpacingY, width: imageViewSize.width, height: imageViewSize.height))
                
                imageView.image = UIImage(named: (index < currentTimelineStatus.rawValue) ? orderStatusItem.activeImageName : orderStatusItem.inactiveImageName)
                
                return imageView
            } ()
            addSubview(orderStatusImageView)
            
            let orderStatusLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: orderStatusImageView.frame.originX + (imageViewSize.width - orderStatusLabelWidth) / 2, y: orderStatusImageView.frame.maxY, width: orderStatusLabelWidth, height: labelHeight))
                label.textAlignment = .center
                label.formatSize(11)
                
                if index < currentTimelineStatus.rawValue {
                    label.textColor = UIColor.primary1()
                }
                
                label.text = orderStatusItem.title
                
                return label
            } ()
            addSubview(orderStatusLabel)
            
            if index < currentTimelineStatus.rawValue {
                let orderStatusDayLabel = { () -> UILabel in
                    let label = UILabel(frame: CGRect(x: orderStatusLabel.frame.originX, y: orderStatusLabel.frame.maxY, width: orderStatusLabelWidth, height: labelHeight))
                    label.textAlignment = .center
                    label.formatSize(11)
                    
                    if index <= currentTimelineStatus.rawValue {
                        label.textColor = UIColor.primary1()
                    }
                    
                    if let data = data {
                        if let order = data.order {
                            var date: Date? = nil
                            
                            switch orderStatusItem.timelineStatus {
                            case .created:
                                date = order.lastCreated as Date?
                            case .toBeShipped:
                                date = order.lastConfirmed as Date?
                            case .shipped:
                                date = order.lastShipped as Date?
                            case .received:
                                date = order.lastReceived as Date?
                            case .reviewed:
                                date = order.lastReviewed as Date?
                            default:
                                break
                            }
                            
                            if let date = date {
                                label.text = "\(date.month)" + String.localize("LB_CA_MONTH") + "\(date.day)" + String.localize("LB_CA_DAY")
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                    
                    return label
                } ()
                addSubview(orderStatusDayLabel)
            }
            
            if index > 0 {
                let lineImageView = { () -> UIImageView in
                    let imageView = UIImageView(frame: CGRect(x: marginHorizontal + (CGFloat(index) * imageViewSize.width) + (CGFloat(index - 1) * imageViewSpacingX), y: marginTop + titleLabel!.height + descriptionLabel!.height + imageViewSpacingY + imageViewSize.height / 2, width: imageViewSpacingX, height: 2))
                    imageView.image = UIImage(named: (index >= currentTimelineStatus.rawValue) ? "icon_order_timeline_dashLine" : "icon_order_timeline_solidLine")
                    return imageView
                } ()
                addSubview(lineImageView)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let titleLabel = self.titleLabel {
            titleLabel.text = titleText
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let descriptionLabel = self.descriptionLabel {
            descriptionLabel.text = descriptionText
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func setTimelineStatus(withOrderStatus orderStatus: Order.OrderStatus, isCrossBorder: Bool) {
        titleText = ""
        descriptionText = "---"
        currentOrderStatusItems = OrderStatusItems
        
        switch orderStatus {
        case .initiated, .confirmed, .paid:
            currentTimelineStatus = .toBeShipped
            titleText =  String.localize("LB_CA_ORDER_SHIPPING_DAY_ESTIMATE") + "\(OrderManager.ToBeShipDays)" + String.localize("LB_CA_ORDER_SHIPPING_DAY_TO_SHIP")
            descriptionText = String.localize("LB_CA_ORDER_SHIPPING_DAY_EXCETPION")
        case .partialShipped, .shipped:
            currentTimelineStatus = .shipped
            
            if isCrossBorder {
                titleText = String.localize("LB_CA_ORDER_SHIPPING_DAY_ESTIMATE") + "\(OrderManager.DomesticArriveDays)-\(OrderManager.CrossBorderArriveDays)" + String.localize("LB_CA_ORDER_SHIPPING_DAY_TO_BE_SHIPPED")
                descriptionText = String.localize("LB_CA_ORDER_SHIPPING_DAY_DEPENDENCE_XBORDER")
            } else {
                titleText = String.localize("LB_CA_ORDER_SHIPPING_DAY_ESTIMATE") + "\(OrderManager.DomesticArriveDays)" + String.localize("LB_CA_ORDER_SHIPPING_DAY_TO_BE_SHIPPED_DOMESTIC")
                descriptionText = String.localize("LB_CA_ORDER_SHIPPING_DAY_DEPENDENCE_DOMESTIC")
            }
            
            
        case .received:
            titleText = String.localize("LB_CA_OMS_RECEIVED")
            
            var isReviewSubmitted = true
            
            if data?.order?.orderShipments == nil || data?.order?.orderShipments?.count == 0 {
                isReviewSubmitted = false
            }
            
            if let orderShipments = data?.order?.orderShipments {
                for orderShipment in orderShipments {
                    if !orderShipment.isReviewSubmitted {
                        isReviewSubmitted = false
                        break
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            currentTimelineStatus = isReviewSubmitted ? .reviewed : .received
        case .closed:
            currentTimelineStatus = .unknown
            if let orderShipment = data?.order?.orderShipments?.first{
                switch orderShipment.orderShipmentStatus {
                case .received, .collected:
                    currentTimelineStatus = .received
                    titleText = String.localize("LB_CA_OMS_RECEIVED")
                default:
                    currentTimelineStatus = .shipped
                    if isCrossBorder {
                        titleText = "\(OrderManager.CrossBorderArriveDays)" + String.localize("LB_CA_OMS_DAYS_TO_SHIP")
                    } else {
                        titleText = "\(OrderManager.DomesticArriveDays)" + String.localize("LB_CA_OMS_DAYS_TO_SHIP")
                    }
                    descriptionText = String.localize("LB_CA_OMS_EST_SHIPMENT")
                }
            }
            else{
                titleText = "\(OrderManager.ToBeShipDays)" + String.localize("LB_CA_OMS_DAYS_TO_SHIP")
                currentTimelineStatus = .toBeShipped
                descriptionText = String.localize("LB_CA_OMS_EST_SHIPMENT")
            }
            
        default:
            currentTimelineStatus = .unknown
        }
    }
}
