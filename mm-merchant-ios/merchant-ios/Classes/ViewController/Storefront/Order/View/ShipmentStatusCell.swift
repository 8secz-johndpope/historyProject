//
//  ShipmentStatusCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ShipmentStatusCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    static let CellIdentifier = "ShipmentStatusCellID"
    static let DefaultHeight: CGFloat = 50
    
    private static let TopPadding: CGFloat = 0
    private static let TopPaddingLabel: CGFloat = 5
    private static let LeftPaddingContent: CGFloat = 20
    private static let LeftPaddingLabel: CGFloat = 53
    private static let LeftPaddingImageShipment: CGFloat = 15
    private static let ShipmentIconSize = CGSize(width: 30, height: 30)
    private static let ArrowSize = CGSize(width: 32, height: 32)
    private static let FapiaoLabelFont = 13
    
    var imageView: UIImageView!
    var nameLabel: UILabel!
    var eventLabel: UILabel!
    private var overseasLabel: UILabel!
    private var fapiaoLabel: UILabel!
    private var containerView: UIView!
    
    var disclosureIndicatorImageView: UIImageView?
    var cellTappedHandler: (() -> Void)?
    
    var isEnablePaddingLeft = false
    var isEnablePaddingRight = false
    
    var data: ShipmentStatusData? {
        didSet {
            let fapiaoValue = ShipmentStatusCell.getFapiaoValue(shipmentStatusData: data)
            fapiaoLabel.text = fapiaoValue
            eventLabel.text = "-"
            if let data = data{
                data.getUpdatedStatus({ (status) in
                    DispatchQueue.main.async {
                        if let shipmentStatus = status {
                            self.eventLabel.text = shipmentStatus.getStateMessage()
                        }else{
                            self.eventLabel.text = "-"
                        }
                        
                    }
                })
            } else {
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let containerView = { () -> UIView in
            let labelHeight: CGFloat = 20
            
            let view = UIView(frame: CGRect(x: 0, y: ShipmentStatusCell.TopPadding, width: frame.width, height: frame.height - ShipmentStatusCell.TopPadding))
            view.backgroundColor = UIColor.white
            
            let nameWidth = ShipmentStatusCell.getLabelWidth(cellWidth: view.bounds.sizeWidth)
            
            let imageContainerView = { () -> UIView in
                let view = UIView(frame: CGRect(x: ShipmentStatusCell.LeftPaddingContent, y: ShipmentStatusCell.TopPadding, width: ShipmentStatusCell.ShipmentIconSize.width, height: ShipmentStatusCell.ShipmentIconSize.height))
                
                let imageView = UIImageView(frame: CGRect(x: ShipmentStatusCell.LeftPaddingImageShipment, y: (frame.sizeHeight - ShipmentStatusCell.ShipmentIconSize.height)/2, width: ShipmentStatusCell.ShipmentIconSize.width, height: ShipmentStatusCell.ShipmentIconSize.height))
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: "icon_order_shipped")
                view.addSubview(imageView)
                self.imageView = imageView
                return view
            } ()
            view.addSubview(imageContainerView)
            
            eventLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: imageContainerView.frame.maxX + ShipmentStatusCell.LeftPaddingLabel, y: ShipmentStatusCell.TopPaddingLabel, width: nameWidth, height: labelHeight))
                label.adjustsFontSizeToFitWidth = true
                label.formatSize(13)
                label.text = "-"
                label.textColor = UIColor.primary1()
                return label
            } ()
            view.addSubview(eventLabel)
            
            nameLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: eventLabel.x, y: eventLabel.frame.maxY, width: nameWidth, height: labelHeight))
                label.adjustsFontSizeToFitWidth = true
                label.formatSize(13)
                label.text = String.localize("LB_CA_OMS_VIEW_SHIPMENT")
                return label
            } ()
            view.addSubview(nameLabel)
            
            fapiaoLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: eventLabel.x, y: nameLabel.frame.maxY, width: nameWidth, height: view.frame.sizeHeight - nameLabel.frame.maxY))
                label.adjustsFontSizeToFitWidth = true
                label.formatSize(13)
                label.text = String.localize("LB_FAPIAO_NO")
                return label
            } ()
            view.addSubview(fapiaoLabel)
            
            let clearButton = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: view.frame.minX, y: 0, width: frame.width - imageContainerView.frame.minX, height: frame.height)
                button.backgroundColor = UIColor.clear
                button.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)
                return button
            } ()
            view.addSubview(clearButton)
            
            let arrowView = { () -> UIImageView in
                let imageView = UIImageView(frame: CGRect(x: frame.width - ShipmentStatusCell.ArrowSize.width, y: (view.frame.sizeHeight - ShipmentStatusCell.ArrowSize.height) / 2, width: ShipmentStatusCell.ArrowSize.width, height: ShipmentStatusCell.ArrowSize.height))
                imageView.image = UIImage(named: "icon_arrow_small")
                imageView.contentMode = .scaleAspectFit
                imageView.isHidden = false
                return imageView
            } ()
            disclosureIndicatorImageView = arrowView
            view.addSubview(disclosureIndicatorImageView!)
            
            return view
        } ()
        self.containerView = containerView
        addSubview(containerView)
        
        let separatorHeight: CGFloat = 1
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 10, y: self.frame.height - separatorHeight, width: frame.width - 20, height: separatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            return view
        } ()
        addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let arrowRightMargin: CGFloat = 10
        let paddingLeft: CGFloat = isEnablePaddingLeft ? 10 : 0
        let paddingRight: CGFloat = isEnablePaddingRight ? 10 : 0
        
        contentView.frame.originX = paddingLeft
        contentView.frame.sizeWidth = contentView.frame.sizeWidth - paddingLeft - paddingRight
        
        self.containerView.frame = CGRect(x: 0, y: ShipmentStatusCell.TopPadding, width: frame.width, height: frame.height - ShipmentStatusCell.TopPadding)
        disclosureIndicatorImageView!.frame.originX = contentView.frame.sizeWidth - ShipmentStatusCell.ArrowSize.width - arrowRightMargin
    }
    
    @objc func headerTapped() {
        if let callback = self.cellTappedHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        if let disclosureIndicatorImageView = self.disclosureIndicatorImageView {
            disclosureIndicatorImageView.isHidden = !isShow
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    //MARK: Helpers
    
    class func getCellHeight(shipmentStatusData: ShipmentStatusData, cellWidth: CGFloat) -> CGFloat {
        let dummyLabel = UILabel()
        dummyLabel.formatSize(ShipmentStatusCell.FapiaoLabelFont)
        dummyLabel.numberOfLines = 0
        
        let fapiaoValue = ShipmentStatusCell.getFapiaoValue(shipmentStatusData: shipmentStatusData)
        
        if !fapiaoValue.isEmptyOrNil() {
            return ShipmentStatusCell.DefaultHeight + dummyLabel.optimumHeight(text: fapiaoValue, width: ShipmentStatusCell.getLabelWidth(cellWidth: cellWidth))
        }
        
        return ShipmentStatusCell.DefaultHeight
    }
    
    private class func getLabelWidth(cellWidth: CGFloat) -> CGFloat {
        return cellWidth - ShipmentStatusCell.LeftPaddingContent - ShipmentStatusCell.ShipmentIconSize.width - ArrowSize.width - ShipmentStatusCell.LeftPaddingLabel
    }
    
    private class func getFapiaoValue(shipmentStatusData: ShipmentStatusData?) -> String {
        if let shipmentStatusData = shipmentStatusData {
            if let orderShipment = shipmentStatusData.orderShipment {
                let invoiceNumber = orderShipment.taxInvoiceNumber
                let invoiceTitle = orderShipment.taxInvoiceName
                
                if !invoiceNumber.isEmptyOrNil() && !invoiceTitle.isEmptyOrNil() {
                    return String.localize("LB_FAPIAO_NO") + " : \(invoiceNumber) (\(invoiceTitle))"
                } else if !invoiceNumber.isEmptyOrNil() && invoiceTitle.isEmptyOrNil() {
                    return String.localize("LB_FAPIAO_NO") + " : \(invoiceNumber)"
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        return ""
    }
}
