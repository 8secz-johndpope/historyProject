//
//  OrderItemActionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderItemActionCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderItemActionCellID"
    static let DefaultHeight: CGFloat = 40
    
    enum ActionButtonType: Int {
        case unknown = 0,
        cancel,
        `return`,
        dispute,
        cancelProgress,
        returnProgress,
        disputeProgress
    }
    
    enum ActionStatus: Int {
        case unknown = 0,
        inProgress,
        accepted,
        rejected
    }
    
    private final let ActionButtonLabels = [
        "",
        String.localize("LB_CA_CANCEL"),
        String.localize("LB_CA_RETURN"),
        String.localize("LB_CA_OMS_DISPUTE_APP"),
        String.localize("LB_CA_OMS_CANCEL_PROGRESS"),
        String.localize("LB_CA_OMS_RETURN_PROGRESS"),
        String.localize("LB_CA_OMS_DISPUTE_TRACK")
    ]
    
    private final let PaddingContent: CGFloat = 14
    private final let ActionButtonSize = CGSize(width: 90, height: Constants.ActionButton.Height)
    
    private var actionButtonView = UIView()
    private var processingItemStatusLabel: UILabel?
    
    private var numOfProcessingQty = 0
    private var afterSalesKey: String?
    
    var data: OrderItemActionData? {
        didSet {
            if let data = self.data {
                orderItem = data.orderItem
                numOfProcessingQty = data.numOfProcessingQty
                afterSalesKey = data.afterSalesKey
                actionButtonType = data.actionButtonType
                actionStatus = data.actionStatus
                reloadActionButtonView()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    private var orderItem: OrderItem?
    private var actionButtonType: ActionButtonType = .unknown
    private var actionStatus: ActionStatus = .unknown
    var didTapActionButton: ((ActionButtonType, OrderItem, String) -> ())?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        actionButtonView.frame = CGRect(x: 0, y: 0, width: frame.width, height: ActionButtonSize.height)
        contentView.addSubview(actionButtonView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        reloadActionButtonView()
    }

    private func reloadActionButtonView() {
        self.processingItemStatusLabel?.removeFromSuperview()
        
        self.removeAllActionButtons()
        
        let paddingBetweenButtons: CGFloat = 5
        var currentButtonFrame = CGRect(x: actionButtonView.frame.width - ActionButtonSize.width - PaddingContent, y: 0, width: ActionButtonSize.width, height: ActionButtonSize.height)
        
        let actionButtonTitleStyle: ActionButton.TitleStyle = actionStatus == .unknown ? .normal: .highlighted
        
        let actionButton = ActionButton(frame: currentButtonFrame, titleStyle: actionButtonTitleStyle)
        actionButton.setTitle(ActionButtonLabels[actionButtonType.rawValue], for: UIControlState())
        
        actionButton.touchUpClosure = { [weak self] _ in
            if let strongSelf = self {
                if let action = strongSelf.didTapActionButton {
                    action(strongSelf.actionButtonType, strongSelf.orderItem ?? OrderItem(), strongSelf.afterSalesKey ?? "")
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        actionButtonView.addSubview(actionButton)
        currentButtonFrame.originX = currentButtonFrame.originX - ActionButtonSize.width - paddingBetweenButtons
        
        if actionStatus != .unknown {
            let label = UILabel(frame: currentButtonFrame)
            label.adjustsFontSizeToFitWidth = true
            label.formatSize(13)
            label.textAlignment = .right
            
            var processingItemStatus = ""
            
            switch actionButtonType {
            case .cancelProgress:
                switch actionStatus {
                case .inProgress:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_CANCEL_SKU_QUANTITY")
                case .accepted:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_CANCEL_SKU_QUANTITY_SUCCEED")
                case .rejected:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_CANCEL_SKU_QUANTITY_FAILED")
                default:
                    break
                }
            case .returnProgress:
                switch actionStatus {
                case .inProgress:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_RETURN_SKU_QUANTITY")
                case .accepted:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_RETURN_SKU_QUANTITY_SUCCEED")
                case .rejected:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_RETURN_SKU_QUANTITY_FAILED")
                default:
                    break
                }
            case .disputeProgress:
                switch actionStatus {
                case .inProgress:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_DISPUTE_SKU_QUANTITY")
                case .accepted:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_DISPUTE_SKU_QUANTITY_SUCCEED")
                case .rejected:
                    processingItemStatus = String.localize("LB_CA_OMS_NUM_DISPUTE_SKU_QUANTITY_FAILED")
                default:
                    break
                }
            default:
                break
            }
            
            if processingItemStatus.length > 0 {
                label.text = "\(numOfProcessingQty) \(processingItemStatus)"
                actionButtonView.addSubview(label)
                
                processingItemStatusLabel = label
            }
            
            currentButtonFrame.originX = currentButtonFrame.originX - ActionButtonSize.width - paddingBetweenButtons
        }
    }
    
    private func removeAllActionButtons() {
        let subviews = actionButtonView.subviews as [UIView]
        
        for view in subviews {
            if let actionButton = view as? ActionButton {
                actionButton.removeFromSuperview()
            }
        }
    }
    
}
