//
//  TSShareOrderFooterView.swift
//  merchant-ios
//
//  Created by HungPM on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class TSShareOrderFooterView: UICollectionReusableView {
    
    var summaryLabel: UILabel!
    var orderInfoLabel: UILabel!
    var lblTimestamp: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let Margin = CGFloat(5)
        let LabelSummaryHeight = CGFloat(32)
        let LabelInfoHeight = CGFloat(21)
        
        summaryLabel = UILabel(frame: CGRect(x: Margin, y: 0, width: self.frame.width - (2 * Margin), height: LabelSummaryHeight))
        summaryLabel.textColor = UIColor.secondary2()
        summaryLabel.textAlignment = .right
        self.addSubview(summaryLabel)
        
        orderInfoLabel = UILabel(frame: CGRect(x: Margin, y: summaryLabel.frame.maxY, width: self.frame.width - (2 * Margin), height: LabelInfoHeight))
        orderInfoLabel.formatSize(17)
        orderInfoLabel.text = String.localize("LB_CA_OMS_INFO")
        self.addSubview(orderInfoLabel)
        
        lblTimestamp = UILabel(frame: CGRect(x: 0, y: self.frame.height - 20, width: self.frame.width - 7, height: 20))
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)
        lblTimestamp.textAlignment = .right
        self.addSubview(lblTimestamp)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
