//
//  MyReviewPlainTextCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MyReviewPlainTextCell: PlainTextCell {

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let leftPadding = CGFloat(15)
        containerView.frame = CGRect(x: leftPadding, y: PlainTextCell.ContainerVerticalPadding, width: frame.width - (PlainTextCell.ContainerHorizontalPadding * 2), height: frame.height - PaddingContainerBottom)
    }

}
