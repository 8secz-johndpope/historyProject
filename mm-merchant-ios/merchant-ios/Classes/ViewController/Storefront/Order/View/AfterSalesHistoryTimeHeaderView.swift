//
//  AfterSalesHistoryTimeHeaderView.swift
//  merchant-ios
//
//  Created by Gambogo on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesHistoryTimeHeaderView : UICollectionReusableView {
    
    static let ViewIdentifier = "AfterSalesHistoryTimeHeaderViewID"
    static let DefaultHeight: CGFloat = 45
    
    private final let LabelHeight: CGFloat = 20
    private final let LabelHorizontalPadding: CGFloat = 20
    
    private var timeLabel = UILabel()
    
    var timeValue: String? {
        didSet {
            if let timeValue = self.timeValue {
                timeLabel.text = timeValue
                
                timeLabel.width = timeLabel.optimumWidth() + (LabelHorizontalPadding * 2)
                timeLabel.x = (frame.width - timeLabel.width) / 2
                timeLabel.isHidden = false
            } else {
                timeLabel.text = ""
                timeLabel.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.primary2()
        
        timeLabel.frame = CGRect(x: 0, y: (frame.height - LabelHeight) / 2, width: frame.width, height: LabelHeight)
        timeLabel.formatSize(12)
        timeLabel.textColor = UIColor.secondary2()
        timeLabel.backgroundColor = UIColor.secondary1()
        timeLabel.textAlignment = .center
        timeLabel.numberOfLines = 1
        timeLabel.layer.cornerRadius = timeLabel.frame.sizeHeight / 2
        timeLabel.layer.masksToBounds = true
        timeLabel.layer.borderWidth = 0
        
        addSubview(timeLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
