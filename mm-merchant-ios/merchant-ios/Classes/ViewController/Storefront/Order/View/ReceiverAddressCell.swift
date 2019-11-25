//
//  AddressCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ReceiverAddressCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    static let CellIdentifier = "ReceiverAddressCellID"
    
    struct Margin {
        static let Top: CGFloat = 0
        static let Left: CGFloat = 22
        static let Right: CGFloat = 10
        static let Bottom: CGFloat = 0
    }
    
    private static let DefaultHeight: CGFloat = 44
    private static let DefaultLabelHeight: CGFloat = 20
    private static let PaddingContent: CGFloat = 30
    private static let PaddingContainerContent: CGFloat = 8
    private static let ShipmentIconSize = CGSize(width: 20, height: 30)
    private static let TextFontSize = 13
    private static let AddressLabelTotalMargin = PaddingContent + (PaddingContainerContent * 2) + ShipmentIconSize.width
    
    private var containerView = UIView()
    private var shipmentAddressContainer = UIView()
    var separateLineView = UIView()
    
    // Shipment location container
    private var addressImageView = UIImageView()
    private var receiverInformationLabel = UILabel()
    private var addressLabel = UILabel()
    
    var data: AddressData? {
        didSet {
            if let data = self.data {
                receiverInformationLabel.text = data.recipientName + "        " + data.recipientPhoneNumber
                addressLabel.text = data.getFullAddress()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    //MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        // Shipment contact container
        shipmentAddressContainer.addSubview(addressImageView)
        
        receiverInformationLabel.formatSize(ReceiverAddressCell.TextFontSize)
        receiverInformationLabel.textColor = UIColor.secondary2()
        shipmentAddressContainer.addSubview(receiverInformationLabel)
        
        addressLabel.formatSize(ReceiverAddressCell.TextFontSize)
        addressLabel.textColor = UIColor.secondary2()
        addressLabel.numberOfLines = 0
        addressLabel.sizeToFit()
        
        shipmentAddressContainer.addSubview(addressLabel)
        
        containerView.addSubview(shipmentAddressContainer)
        addSubview(containerView)
        
        separateLineView.backgroundColor = UIColor.secondary1()
        separateLineView.isHidden = true
        addSubview(separateLineView)
    }
    
    // MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.frame = CGRect(
            x: ReceiverAddressCell.Margin.Left,
            y: ReceiverAddressCell.Margin.Top,
            width: frame.width - Margin.Left - Margin.Right,
            height: frame.height - Margin.Top - Margin.Bottom
        )
        
        // Shipment Detail Container
        
        shipmentAddressContainer.frame = CGRect(
            x: 0,
            y: 0,
            width: containerView.frame.sizeWidth,
            height: containerView.frame.sizeHeight
        )
        
        addressImageView.frame = CGRect(
            x: 0,
            y: 10,
            width: ReceiverAddressCell.ShipmentIconSize.width,
            height: ReceiverAddressCell.ShipmentIconSize.height
        )
        addressImageView.image = UIImage(named: "icon_order_deliverAddress")
        
        receiverInformationLabel.frame = CGRect(
            x: addressImageView.frame.maxX + ReceiverAddressCell.PaddingContent,
            y: ReceiverAddressCell.PaddingContainerContent,
            width: shipmentAddressContainer.width - addressImageView.frame.maxX - ReceiverAddressCell.PaddingContent,
            height: ReceiverAddressCell.DefaultLabelHeight
        )
        
        addressLabel.frame = CGRect(
            x: receiverInformationLabel.frame.minX,
            y: receiverInformationLabel.frame.maxY + 5,
            width: receiverInformationLabel.width,
            height: max(addressLabel.optimumHeight(width: receiverInformationLabel.width), ReceiverAddressCell.DefaultLabelHeight)
        )
        
        separateLineView.frame = CGRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }

    // MARK: - Class func
    
    class func getCellHeight(withAddress address: String, cellWidth: CGFloat) -> CGFloat {
        let cellHeight = ReceiverAddressCell.DefaultHeight
        
        if address.isEmpty {
            return cellHeight - ReceiverAddressCell.PaddingContainerContent
        }
        
        let dummyLabel = UILabel()
        dummyLabel.numberOfLines = 0
        dummyLabel.formatSize(TextFontSize)
        if let font = UIFont(name: Constants.Font.Normal, size: CGFloat(ReceiverAddressCell.TextFontSize)){
            dummyLabel.font = font
        }
        return cellHeight + max(dummyLabel.optimumHeight(text: address, width: cellWidth - Margin.Left - Margin.Right - ShipmentIconSize.width - ReceiverAddressCell.PaddingContent), ReceiverAddressCell.DefaultLabelHeight)
    }
}
