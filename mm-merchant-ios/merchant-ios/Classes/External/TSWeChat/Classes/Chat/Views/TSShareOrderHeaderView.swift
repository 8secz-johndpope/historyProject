
//
//  TSShareOrderHeaderView.swift
//  merchant-ios
//
//  Created by HungPM on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class TSShareOrderHeaderView: UICollectionReusableView {
    
    var orderNumberLabel: UILabel!
    var shipmentNumberLabel: UILabel!
    var lblShipment: UILabel!
    
    private final var viewSeparator: UIView!
    private final var lblOrder: UILabel!

    private final let Margin = CGFloat(5)
    private final let LabelSize = CGSize(width: 45, height: 18)

    override init(frame: CGRect) {
        super.init(frame: frame)

        lblOrder = UILabel()
        lblOrder.formatSize(11)
        lblOrder.text = String.localize("LB_CA_OMS_ORDER_DETAIL_MERCH_ORDER_NUM")
        self.addSubview(lblOrder)
        
        orderNumberLabel = UILabel()
        orderNumberLabel.formatSizeBold(12)
        orderNumberLabel.lineBreakMode = .byTruncatingTail
        orderNumberLabel.numberOfLines = 1
        self.addSubview(orderNumberLabel)
        
        lblShipment = UILabel()
        lblShipment.formatSize(11)
        lblShipment.text = String.localize("LB_CA_OMS_SHIPMENT_NO")
        self.addSubview(lblShipment)
        
        shipmentNumberLabel = UILabel()
        shipmentNumberLabel.formatSizeBold(12)
        shipmentNumberLabel.lineBreakMode = .byTruncatingTail
        shipmentNumberLabel.numberOfLines = 1
        self.addSubview(shipmentNumberLabel)
        
        viewSeparator = UIView()
        viewSeparator.backgroundColor = UIColor.backgroundGray()
        self.addSubview(viewSeparator)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        viewSeparator.frame = CGRect(x: Margin, y: self.frame.height - 1, width: self.frame.width - (2 * Margin), height: 1)
        
        if shipmentNumberLabel.isHidden {
            lblOrder.frame = CGRect(x: Margin, y: Margin, width: LabelSize.width, height: self.frame.height - (2 * Margin))
        }
        else {
            lblOrder.frame = CGRect(x: Margin, y: Margin, width: LabelSize.width, height: LabelSize.height)
        }
        
        let PosX = lblOrder.frame.maxX + Margin
        orderNumberLabel.frame = CGRect(x: PosX, y: lblOrder.frame.minY, width: self.frame.width - Margin - PosX, height: lblOrder.frame.height)
        
        lblShipment.frame = CGRect(x: Margin, y: lblOrder.frame.maxY, width: LabelSize.width, height: LabelSize.height)
        shipmentNumberLabel.frame = CGRect(x: PosX, y: lblShipment.frame.minY, width: self.frame.width - Margin - PosX, height: LabelSize.height)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
