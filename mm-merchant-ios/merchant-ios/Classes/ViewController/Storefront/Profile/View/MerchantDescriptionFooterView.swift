//
//  MerchantDescriptionFooterView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MerchantDescriptionFooterView: UICollectionReusableView {
    
    static let FooterView = "FooterView"
    static let Height = CGFloat(60)
    
    var productLabel = UILabel()
    var serviceLabel = UILabel()
    var shipmentLabel = UILabel()
    let containerView = UIView()
    let lineView1 = UIView()
    let lineView2 = UIView()
    
    var merchantSummaryResponse: MerchantSummaryResponse? {
        didSet {
            if let merchant = merchantSummaryResponse {
                if merchant.ratingProductDescriptionAverage > 0 {
                    
                    productLabel.text = String(format:"%@ %.1f", String.localize("LB_CA_PROD_DESC"), merchant.ratingProductDescriptionAverage)
                } else {
                    productLabel.isHidden = true
                    lineView1.isHidden = true
                }
                
                if merchant.ratingServiceAverage  > 0 {
                    serviceLabel.text = String(format: "%@ %.1f", String.localize("LB_CA_CUST_SERVICE"), merchant.ratingServiceAverage)
                } else {
                    serviceLabel.isHidden = true
                    lineView2.isHidden = true
                }
                
                if merchant.ratingLogisticsAverage > 0 {
                    shipmentLabel.text = String(format: "%@ %.1f", String.localize("LB_CA_SHIPMENT_RATING"), merchant.ratingLogisticsAverage)
                } else {
                    shipmentLabel.isHidden = true
                }
                
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        let margin = CGFloat(12)
        let lineView = UIView()
        lineView.frame = CGRect(x: margin, y: 8, width: self.bounds.sizeWidth - 2 * margin, height: 1)
        lineView.backgroundColor = UIColor.primary2()
        self.addSubview(lineView)
        
        
        containerView.frame = CGRect(x: margin, y: lineView.frame.maxY, width: self.bounds.sizeWidth - 2 * margin, height: self.bounds.sizeHeight - lineView.frame.maxY )
        
        let width = containerView.frame.sizeWidth / 3
        productLabel.frame = CGRect(x: 0, y: 0, width: width, height: containerView.frame.sizeHeight)
        productLabel.formatSize(12)
        productLabel.text = String(format:"%@ 0.0",String.localize("LB_CA_PROD_DESC"))
        productLabel.textColor = UIColor.secondary3()
        productLabel.textAlignment = NSTextAlignment.center
        containerView.addSubview(productLabel)
        
        serviceLabel.formatSize(12)
        serviceLabel.text = String(format: "%@ 0.0",String.localize("LB_CA_CUST_SERVICE"))
        serviceLabel.textColor = UIColor.secondary3()
        serviceLabel.textAlignment = NSTextAlignment.center
        serviceLabel.frame = CGRect(x: width, y: 0, width: width, height: containerView.frame.sizeHeight)
        containerView.addSubview(serviceLabel)
        
        shipmentLabel.formatSize(12)
        shipmentLabel.text = String(format: "%@ 0.0",String.localize("LB_CA_SHIPMENT_RATING"))
        shipmentLabel.textColor = UIColor.secondary3()
        shipmentLabel.textAlignment = NSTextAlignment.center
        shipmentLabel.frame = CGRect(x: width * 2, y: 0, width: width, height: containerView.frame.sizeHeight)
        containerView.addSubview(shipmentLabel)
        
        self.addSubview(containerView)
        
        let height = CGFloat(19)
        
        
        lineView1.backgroundColor = UIColor.secondary1()
        lineView1.frame = CGRect(x: productLabel.frame.maxX, y: (containerView.frame.sizeHeight - height) / 2 , width: 1, height: height)
        containerView.addSubview(lineView1)
        

        lineView2.backgroundColor = UIColor.secondary1()
        lineView2.frame = CGRect(x: serviceLabel.frame.maxX, y: (containerView.frame.sizeHeight - height) / 2 , width: 1, height: height)
        containerView.addSubview(lineView2)
        
        
        
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
