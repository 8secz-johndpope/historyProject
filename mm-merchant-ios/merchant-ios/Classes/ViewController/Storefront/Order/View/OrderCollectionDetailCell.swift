//
//  OrderCollectionDetailCell.swift
//  merchant-ios
//
//  Created by Gambogo on 4/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderCollectionDetailCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderCollectionDetailCellID"
    
    private static let CollectAddressContainerBasicHeight: CGFloat = 60
    private static let CollectNumberContainerHeight: CGFloat = 60
    private static let ContainerContentPadding: CGFloat = 7
    private static let ContainerHorizontalPadding: CGFloat = 10
    private static let ContentPadding: CGFloat = 10
    private static let TextFontSize = 13
    private static let AddressLabelTotalMargin = (ContainerHorizontalPadding * 2) + (ContainerContentPadding * 4)
    
    private var containerView = UIView()
    private var collectionAddressContainer = UIView()
    private var collectionNumberContainer = UIView()
    
    // Collection Address Container
    private var copyAddressButton = UIButton(type: .custom)
    private var addressTitleLabel = UILabel()
    private var addressValueLabel = UILabel()
    private var phoneNumberLabel = UILabel()
    private var collectionAddressBottomBorderView = UIView()
    
    // Collection Number Container
    private var collectionNumberTitleLabel = UILabel()
    private var collectionNumberValueLabel = UILabel()
    
    var copyAddressTapHandler: ((_ address: String) -> Void)?
    
    var data: OrderCollectionData? {
        didSet {
            if let data = self.data {
                addressValueLabel.text = data.getCollectionAddress()
                phoneNumberLabel.text = data.collectionPhoneNumber
                collectionNumberValueLabel.text = data.collectionNumber
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
        
        // Collection Address Container
        addressTitleLabel.formatSize(OrderCollectionDetailCell.TextFontSize)
        addressTitleLabel.text = String.localize("LB_CA_COLLECTION_ADDRESS")
        addressTitleLabel.textColor = UIColor.secondary2()
        collectionAddressContainer.addSubview(addressTitleLabel)
        
        addressValueLabel.formatSize(OrderCollectionDetailCell.TextFontSize)
        addressValueLabel.textColor = UIColor.secondary2()
        collectionAddressContainer.addSubview(addressValueLabel)
        
        phoneNumberLabel.formatSize(OrderCollectionDetailCell.TextFontSize)
        phoneNumberLabel.textColor = UIColor.secondary2()
        collectionAddressContainer.addSubview(phoneNumberLabel)
        
        copyAddressButton.layer.borderColor = UIColor.secondary1().cgColor
        copyAddressButton.layer.borderWidth = 1
        copyAddressButton.layer.cornerRadius = 5
        copyAddressButton.setTitle(String.localize("LB_CA_COPY"), for: UIControlState())
        copyAddressButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        copyAddressButton.titleLabel?.formatSize(14)
        copyAddressButton.titleLabel?.numberOfLines = 1
        copyAddressButton.backgroundColor = UIColor.white
        copyAddressButton.addTarget(self, action: #selector(copyAddressButtonTapped), for: .touchUpInside)
        collectionAddressContainer.addSubview(copyAddressButton)
        
        collectionAddressBottomBorderView.backgroundColor = UIColor.secondary1()
        collectionAddressContainer.addSubview(collectionAddressBottomBorderView)
        
        // Collection Number Container
        collectionNumberTitleLabel.formatSizeBold(OrderCollectionDetailCell.TextFontSize)
        collectionNumberTitleLabel.text = String.localize("LB_CA_OMS_ORDER_DETAIL_MERCH_ORDER_NUM")
        collectionNumberTitleLabel.textColor = UIColor.secondary2()
        collectionNumberContainer.addSubview(collectionNumberTitleLabel)
        
        collectionNumberValueLabel.formatSize(OrderCollectionDetailCell.TextFontSize)
        collectionNumberValueLabel.text = ""
        collectionNumberValueLabel.textColor = UIColor.secondary2()
        collectionNumberContainer.addSubview(collectionNumberValueLabel)
        
        containerView.addSubview(collectionAddressContainer)
        containerView.addSubview(collectionNumberContainer)
        addSubview(containerView)
        
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.secondary1().cgColor
    }
    
    // MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelHeight: CGFloat = 20
        let copyButtonSize = CGSize(width: 60, height: 23)
        let labelTopMargin: CGFloat = 2
        let borderHeight: CGFloat = 1
        
        containerView.frame = CGRect(
            x: OrderCollectionDetailCell.ContainerHorizontalPadding,
            y: 0,
            width: frame.sizeWidth - (OrderCollectionDetailCell.ContainerHorizontalPadding * 2),
            height: frame.sizeHeight
        )
        
        // Collect Address Container
        
        var collectionAddressContainerHeight = OrderCollectionDetailCell.CollectAddressContainerBasicHeight
        
        if let phoneNumber = phoneNumberLabel.text, phoneNumber.length == 0 {
            collectionAddressContainerHeight -= labelHeight
        }
        
        collectionAddressContainer.frame = CGRect(
            x: OrderCollectionDetailCell.ContainerContentPadding,
            y: OrderCollectionDetailCell.ContainerContentPadding,
            width: containerView.frame.sizeWidth - (OrderCollectionDetailCell.ContainerContentPadding * 2),
            height: collectionAddressContainerHeight
        )
        
        copyAddressButton.frame = CGRect(
            x: collectionAddressContainer.frame.sizeWidth - copyButtonSize.width,
            y: 0,
            width: copyButtonSize.width,
            height: copyButtonSize.height
        )
        
        addressTitleLabel.frame = CGRect(
            x: OrderCollectionDetailCell.ContainerContentPadding,
            y: 0,
            width: copyAddressButton.frame.originX - (OrderCollectionDetailCell.ContainerContentPadding * 2),
            height: copyAddressButton.frame.sizeHeight
        )
        
        addressValueLabel.frame = CGRect(
            x: OrderCollectionDetailCell.ContainerContentPadding,
            y: addressTitleLabel.frame.maxY + labelTopMargin,
            width: collectionAddressContainer.frame.sizeWidth - (OrderCollectionDetailCell.ContainerContentPadding * 2),
            height: addressValueLabel.optimumHeight(width: width - OrderCollectionDetailCell.AddressLabelTotalMargin)
        )
        
        collectionAddressContainer.height += addressValueLabel.height
        
        phoneNumberLabel.frame = CGRect(
            x: addressValueLabel.frame.originX,
            y: addressValueLabel.frame.maxY + labelTopMargin,
            width: addressValueLabel.frame.sizeWidth,
            height: labelHeight
        )
        
        collectionAddressBottomBorderView.frame = CGRect(
            x: OrderCollectionDetailCell.ContainerContentPadding,
            y: collectionAddressContainer.frame.sizeHeight - 1,
            width: collectionAddressContainer.frame.sizeWidth - (OrderCollectionDetailCell.ContainerContentPadding * 2),
            height: borderHeight
        )
        
        // Collect Number container
        
        collectionNumberContainer.frame = CGRect(
            x: collectionAddressContainer.frame.originX,
            y: collectionAddressContainer.frame.maxY,
            width: collectionAddressContainer.frame.sizeWidth,
            height: OrderCollectionDetailCell.CollectNumberContainerHeight
        )
        
        collectionNumberTitleLabel.frame = CGRect(
            x: addressTitleLabel.frame.originX,
            y: OrderCollectionDetailCell.ContainerContentPadding,
            width: addressTitleLabel.frame.sizeWidth,
            height: addressTitleLabel.frame.sizeHeight
        )
        
        collectionNumberValueLabel.frame = CGRect(
            x: addressValueLabel.frame.originX,
            y: collectionNumberTitleLabel.frame.maxY + labelTopMargin,
            width: addressValueLabel.frame.sizeWidth,
            height: labelHeight
        )
    }
    
    // MARK: - Actions
    
    @objc func copyAddressButtonTapped() {
        if let addressValue = addressValueLabel.text {
            if let callback = self.copyAddressTapHandler {
                callback(addressValue)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    // MARK: - Class func
    
    class func getCellHeight(_ orderCollectionData: OrderCollectionData, cellWidth: CGFloat) -> CGFloat {
        let cellBasicHeight = CollectAddressContainerBasicHeight + CollectNumberContainerHeight + (ContainerContentPadding * 2)
        
        let dummyLabel = UILabel()
        dummyLabel.numberOfLines = 0
        dummyLabel.formatSize(TextFontSize)
        
        let cellHeight = cellBasicHeight + dummyLabel.optimumHeight(text: orderCollectionData.getCollectionAddress(), width: cellWidth - AddressLabelTotalMargin)
        
        if orderCollectionData.collectionPhoneNumber.length == 0 {
            return cellHeight - 20
        }
        
        return cellHeight
    }
}
