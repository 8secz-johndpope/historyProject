//
//  CourierCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CourierCell: UICollectionViewCell {
    
    static let CellIdentifier = "CourierCellID"
    static let DefaultHeight: CGFloat = 105
    
    private let TopPadding: CGFloat = 20
    private let LabelHeight: CGFloat = 20
    
    var courierImageView = UIImageView()
    var courierNameLabel = UILabel()
    var consignmentNumberLabel = UILabel()
    var hotlineButton: UIButton!
    var courierPhoneNumberLabel: UILabel!
    var hotlineTitleLabel: UILabel!
    
    var data: CourierData? {
        didSet {
            if let data = self.data {
                courierNameLabel.text = data.courierName
                consignmentNumberLabel.text = data.consignmentNumber
                courierPhoneNumberLabel.text = data.courierPhoneCode + " " + data.courierPhoneNumber
                courierImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(data.courierImageName, category: .courier), placeholderImage: nil, contentMode: .scaleAspectFit)
                
                //Wrap content for hotline button
                let HorizontalMargin: CGFloat = 10
                var hotlineButtonFrame = hotlineButton.frame
                let courierPhoneNumberWidth = courierPhoneNumberLabel.optimumWidth()
                courierPhoneNumberLabel.frame.sizeWidth = courierPhoneNumberWidth
                hotlineButtonFrame.sizeWidth = hotlineTitleLabel.optimumWidth() + courierPhoneNumberWidth + 30 //30 is Padding label
                hotlineButtonFrame.originX = frame.maxX - HorizontalMargin - hotlineButtonFrame.sizeWidth
                hotlineButton.frame = hotlineButtonFrame
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        let HorizontalMargin: CGFloat = 10
        let CourierImageViewHeight: CGFloat = 50
        let ConsignmentNumberLabelWidth: CGFloat = 150
        
        courierImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: HorizontalMargin, y: TopPadding, width: CourierImageViewHeight, height: CourierImageViewHeight))
            
            return imageView
        }()
        
        addSubview(courierImageView)
        
        courierNameLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: courierImageView.frame.maxX + HorizontalMargin, y: courierImageView.frame.midY - LabelHeight / 2, width: frame.width - courierImageView.frame.maxX, height: LabelHeight))
            label.formatSize(14)
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 1
            
            return label
        } ()
        addSubview(courierNameLabel)
        
        consignmentNumberLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.maxX - HorizontalMargin - ConsignmentNumberLabelWidth, y: courierImageView.frame.minY, width: ConsignmentNumberLabelWidth, height: LabelHeight))
            label.formatSize(14)
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 1
            label.textAlignment = .right
            
            return label
        } ()
        addSubview(consignmentNumberLabel)
        
        let consignmentNumberTitleLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.maxX - HorizontalMargin - ConsignmentNumberLabelWidth, y: consignmentNumberLabel.frame.maxY, width: ConsignmentNumberLabelWidth, height: LabelHeight))
            label.formatSize(10)
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 1
            label.textAlignment = .right
            label.textColor = UIColor.secondary2()
            label.text = String.localize("LB_CA_OMS_SHIPMENT_NO")
            
            return label
        } ()
        addSubview(consignmentNumberTitleLabel)
        
        let hotlineButtonWidth: CGFloat = 125
        
        let hotlineButton = { () -> UIButton in
            let button = UIButton(frame: CGRect(x: frame.maxX - HorizontalMargin - hotlineButtonWidth, y: consignmentNumberTitleLabel.frame.maxY + 5, width: hotlineButtonWidth, height: 25))
            button.formatSecondary()
            button.backgroundColor = UIColor.clear
            
            let leftButtonLabel = UILabel(frame: CGRect(x: 14, y: 0, width: button.bounds.width / 2 - 14, height: button.bounds.height))
            leftButtonLabel.formatSize(12)
            leftButtonLabel.textColor = UIColor.secondary2()
            leftButtonLabel.text = String.localize("LB_OMS_CS_HOTLINE")
            
            let rightButtonLabel = UILabel(frame: CGRect(x: button.bounds.width / 2, y: 0, width: button.bounds.width / 2 - 14, height: button.bounds.height))
            rightButtonLabel.textAlignment = .right
            rightButtonLabel.formatSize(12)
            rightButtonLabel.text = ""
            
            hotlineTitleLabel = leftButtonLabel
            courierPhoneNumberLabel = rightButtonLabel
            
            button.addSubview(leftButtonLabel)
            button.addSubview(rightButtonLabel)
            
            button.addTarget(self, action: #selector(CourierCell.callHotline), for: .touchUpInside)
            return button
        } ()
        
        self.hotlineButton = hotlineButton
        addSubview(self.hotlineButton)
        
        let separatorHeight: CGFloat = 1
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: frame.height - separatorHeight, width: frame.width, height: separatorHeight))
            view.backgroundColor = UIColor.secondary1()
            return view
        } ()
        addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc func callHotline() {
        if let courierData = self.data {
            if let phoneURL = URL(string: "tel://\(courierData.courierPhoneCode)\(courierData.courierPhoneNumber)") {
                if !courierData.courierPhoneNumber.isEmptyOrNil() {
                    UIApplication.shared.openURL(phoneURL)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}
