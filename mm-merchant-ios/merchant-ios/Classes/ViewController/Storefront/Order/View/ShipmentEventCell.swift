//
//  ShipmentEventCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ShipmentEventCell: UICollectionViewCell {
    
    static let CellIdentifier = "ShipmentEventCellID"
    static let DefaultHeight: CGFloat = 100
    static let ShipmentEventImageViewLeftMargin: CGFloat = 32
    static let HorizontalMargin: CGFloat = 10
    static let ShipmentEventImageViewWidth: CGFloat = 6
    private var shipmentEventImageView = UIImageView()
    private var lineShipmentEventImageView = UIImageView()
    
    var dateTimeLabel = UILabel()
    var statusAndContextLabel = UILabel()
    
    var isCurrentEvent = false {
        didSet {
            lineShipmentEventImageView.image = UIImage(named: isCurrentEvent ? "icon_shipment_event_selected" : "icon_shipment_event_not_selected")
        }
    }
    
    var data: KuaiDi100Data? {
        didSet {
            if let strongData = data {
        
                dateTimeLabel.text = Constants.DateFormatter.getFormatter("yyyy-MM-dd HH:mm:ss").string(from: strongData.ftime)
                statusAndContextLabel.text = strongData.context
                statusAndContextLabel.frame = CGRect(x: statusAndContextLabel.frame.minX, y: statusAndContextLabel.frame.minY, width: statusAndContextLabel.width, height: statusAndContextLabel.optimumHeight())
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        let DefaultLabelHeight: CGFloat = 20
        let ShipmentEventImageViewHeight: CGFloat = self.height
        
        shipmentEventImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: ShipmentEventCell.ShipmentEventImageViewLeftMargin, y: (self.height - ShipmentEventImageViewHeight) / 2, width: ShipmentEventCell.ShipmentEventImageViewWidth, height: ShipmentEventImageViewHeight))
            imageView.image = UIImage(named: "image_shipment_event_line")

            return imageView
        } ()
        
        addSubview(shipmentEventImageView)
        
        lineShipmentEventImageView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: shipmentEventImageView.frame.midX - 12, y: (self.height - 24) / 2, width: 24, height: 24))
            return imageView
        } ()
        lineShipmentEventImageView.isHidden = false
        addSubview(lineShipmentEventImageView)
        
        dateTimeLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: shipmentEventImageView.frame.maxX + ShipmentEventCell.HorizontalMargin + 22, y: self.height / 2 - DefaultLabelHeight, width: self.width - shipmentEventImageView.frame.maxX - ShipmentEventCell.HorizontalMargin - 22, height: DefaultLabelHeight))
            label.formatSize(14)
            label.minimumScaleFactor = 0.5
            label.numberOfLines = 1
            label.textColor = UIColor.secondary3()
            
            return label
        } ()
        addSubview(dateTimeLabel)
        
        statusAndContextLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.width - shipmentEventImageView.frame.maxX - 2*ShipmentEventCell.HorizontalMargin - 22, height: 0))
            label.formatSize(14)
            label.minimumScaleFactor = 0.5
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            label.textColor = UIColor.secondary2()
            label.frame = CGRect(x: shipmentEventImageView.frame.maxX + ShipmentEventCell.HorizontalMargin + 22, y: self.height / 2, width: self.width - shipmentEventImageView.frame.maxX - 2*ShipmentEventCell.HorizontalMargin - 22, height: label.optimumHeight())
            return label
        } ()
        addSubview(statusAndContextLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getHeight(statusAndContextText statusAndContext: String) -> CGFloat{
        let label = UILabel(frame: CGRect(x: 0,y: 0,width: Constants.ScreenSize.SCREEN_WIDTH - ShipmentEventCell.ShipmentEventImageViewLeftMargin - ShipmentEventCell.ShipmentEventImageViewWidth - 2*ShipmentEventCell.HorizontalMargin - 22,height: 0))
        label.text = statusAndContext
        let optimumHeight = label.optimumHeight()
        return (optimumHeight > ShipmentEventCell.DefaultHeight/2 ) ? optimumHeight + ShipmentEventCell.DefaultHeight/2 : ShipmentEventCell.DefaultHeight
    }
}
