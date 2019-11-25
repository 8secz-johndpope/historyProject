//
//  OrderActionCell.swift
//  merchant-ios
//
//  Created by Gambogo on 4/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol OrderActionCellDelegate: NSObjectProtocol {
    func didConfirmShipment(orderShipmentKey: String, order: Order?)
    func didRequestViewReview(_ order: Order)
    func didRequestViewShipment(_ order: Order)
}

class OrderActionCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderActionCellID"
    
    enum OrderActionButtonType: Int {
        case contact = 0
        case viewShipment
        case confirmShipment
        case review
    }
    
    private final let ActionButtonLabels = [
        String.localize("LB_CA_OMS_CONTACT_CS"),
        String.localize("LB_CA_OMS_VIEW_SHIPMENT"),
        String.localize("LB_CA_OMS_CONFIRM_SHIPMENT"),
        String.localize("LB_CA_OMS_REVIEW"),
        String.localize("LB_CA_UNPAID_ORDER_CANCEL_ORDER"),
        String.localize("LB_CA_UNPAID_ORDER_TO_PAY").replacingOccurrences(of: " ({0}s)", with: "")
        
    ]
    
    private final let PaddingContent: CGFloat = 14
    private final let ActionButtonSize = CGSize(width: 90, height: Constants.ActionButton.Height)
    
    var isDisplayShipmentAndReviewButtons = false
    var isShowInDetailView = false
    var orderActionButtonView = UIView()
    var triangleImageView = UIImageView(image: UIImage(named: "triangle_down"))
    
    weak var delegate: OrderActionCellDelegate?
    
    var contactHandler: (() -> Void)?
    
    var data: OrderActionData? {
        didSet {
            if let data = self.data {
                updateViewMode(data.orderDisplayStatus)
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
        
        let triangleImageViewSize = CGSize(width: 18, height: 8)
        
        orderActionButtonView.frame = CGRect(x: 0, y: (frame.height - ActionButtonSize.height) / 2, width: frame.width, height: ActionButtonSize.height)
        contentView.addSubview(orderActionButtonView)
        
        // Triangle Image align middle of right button
        triangleImageView.frame = CGRect(x: frame.width - (ActionButtonSize.width + triangleImageViewSize.width) / 2 - PaddingContent, y: 0, width: triangleImageViewSize.width, height: triangleImageViewSize.height)
        contentView.addSubview(triangleImageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let data = self.data {
            updateViewMode(data.orderDisplayStatus)
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: - Action
    
    private func contactCustomerService() {
        if let callback = self.contactHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }

    private func viewShipment() {
        if let data = self.data {
            if let order = data.order {
                delegate?.didRequestViewShipment(order)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func confirmShipment() {
        if let data = self.data {
            if data.orderShipmentKey.count > 0 {
                delegate?.didConfirmShipment(orderShipmentKey: data.orderShipmentKey, order: data.order)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func writeReview() {
        if let data = self.data {
            if let order = data.order {
                delegate?.didRequestViewReview(order)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    private func updateViewMode(_ orderDisplayStatus: Constants.OrderDisplayStatus) {
        // Clear all action buttons
        removeAllActionButtons()
        
        var orderActionButtonTypes = [OrderActionButtonType]()
        orderActionButtonTypes.append(.contact)
        
        switch orderDisplayStatus {
        case .shipped, .partialShip:
            // Hide .ViewShipment && .ConfirmShipment && .Review in order list when it is partial ship and more than 1 shipment to view/confirm
            if let data = data {
                if isDisplayShipmentAndReviewButtons && data.order?.orderItems?.count > 0{
                    switch data.orderShipmentStatus {
                    case .shipped:
                        if data.orderShipmentToBeReceivedCount == 1{
                            if !isShowInDetailView {
                                orderActionButtonTypes.append(.viewShipment)
                            }
                            
                            orderActionButtonTypes.append(.confirmShipment)
                        }
                    case .toShipToConsolidationCentre, .shippedToConsolidationCentre, .receivedToConsolidationCentre:
                        if data.orderShipmentToBeReceivedCount == 1 && !isShowInDetailView {
                            orderActionButtonTypes.append(.viewShipment)
                        }
                    default:
                        break
                    }
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        case .received, .collected:
            if data == nil || !data!.isReviewSubmitted {
                orderActionButtonTypes.append(.review)
            }
        default:
            orderActionButtonTypes = [.contact]
        }
        
        let paddingBetweenButtons: CGFloat = 5
        var currentButtonFrame = CGRect(x: orderActionButtonView.width - ActionButtonSize.width - PaddingContent, y: 0, width: ActionButtonSize.width, height: ActionButtonSize.height)
        
        // Loop from max to modeButtons.count - 1 to 0
        for index in stride(from: (orderActionButtonTypes.count - 1), through: 0, by: -1) {
            var actionButtonTitleStyle: ActionButton.TitleStyle = .normal
            
            switch orderActionButtonTypes[index] {
            case .contact, .viewShipment:
                actionButtonTitleStyle = .normal
            case .confirmShipment, .review:
                actionButtonTitleStyle = .highlighted
            }
            
            let actionButton = ActionButton(frame: currentButtonFrame, titleStyle: actionButtonTitleStyle)
            actionButton.setTitle(ActionButtonLabels[orderActionButtonTypes[index].rawValue], for: UIControlState())
            
            switch orderActionButtonTypes[index] {
            case .contact:
                actionButton.touchUpClosure = { [weak self] _ in
                    if let strongSelf = self {
                        strongSelf.contactCustomerService()
                    }
                }
            case .viewShipment:
                actionButton.touchUpClosure = { [weak self] _ in
                    if let strongSelf = self {
                        strongSelf.viewShipment()
                    }
                }
            case .confirmShipment:
                actionButton.touchUpClosure = { [weak self] _ in
                    if let strongSelf = self {
                        strongSelf.confirmShipment()
                    }
                }
            case .review:
                actionButton.touchUpClosure = { [weak self] _ in
                    if let strongSelf = self {
                        strongSelf.writeReview()
                    }
                }
            }
            orderActionButtonView.addSubview(actionButton)
            currentButtonFrame.originX = currentButtonFrame.originX - ActionButtonSize.width - paddingBetweenButtons
        }
    }
    
    private func removeAllActionButtons() {
        let subviews = orderActionButtonView.subviews as [UIView]
        
        for view in subviews {
            if let actionButton = view as? ActionButton {
                actionButton.removeFromSuperview()
            }
        }
    }
}
