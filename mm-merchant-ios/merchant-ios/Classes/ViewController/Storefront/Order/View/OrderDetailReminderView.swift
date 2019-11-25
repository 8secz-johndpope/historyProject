//
//  OrderDetailReminderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderDetailReminderView: UICollectionReusableView {
    
    static let ViewIdentifier = "OrderDetailReminderViewID"
    static let DefaultHeight: CGFloat = 30
    
    private var imageView: UIImageView?
    private var messageLabel: UILabel?
    
    var message: String = "" {
        didSet {
            let dummyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.sizeWidth, height: frame.sizeHeight))
            dummyLabel.formatSmall()
            dummyLabel.numberOfLines = 1
            dummyLabel.text = message
            dummyLabel.sizeToFit()
            
            let messageLabelWidth = dummyLabel.frame.sizeWidth
            let padding: CGFloat = 10
            
            if let imageView = self.imageView {
                if let messageLabel = self.messageLabel {
                    imageView.frame = CGRect(x: (frame.width - messageLabelWidth - imageView.frame.sizeWidth - padding) / 2, y: imageView.frame.originY, width: imageView.frame.sizeWidth, height: imageView.frame.sizeHeight)
                    messageLabel.frame = CGRect(x: imageView.frame.maxX + padding, y: messageLabel.frame.originY, width: messageLabelWidth, height: messageLabel.frame.sizeHeight)
                    messageLabel.text = message
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.secondary3()
        
        imageView = UIImageView(frame: UIEdgeInsetsInsetRect(CGRect(x: 0, y: 0, width: frame.height, height: frame.height), UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)))
        imageView!.image = UIImage(named: "icon_order_callDetailAvatar")
        imageView!.contentMode = .scaleAspectFit
        addSubview(imageView!)
        
        messageLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: frame.height))
            label.formatSmall()
            return label
        } ()
        addSubview(messageLabel!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
