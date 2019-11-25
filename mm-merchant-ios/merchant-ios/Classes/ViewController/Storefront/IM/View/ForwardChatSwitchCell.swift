//
//  ForwardChatSwitchCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/3/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ForwardChatSwitchCell: UICollectionViewCell {
    
    var swt: UISwitch!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let Margin = CGFloat(5)
        
        swt = { () -> UISwitch in
            let swt = UISwitch()
            swt.frame = CGRect(x: frame.width - swt.bounds.width - (2 * Margin), y: (frame.height - swt.bounds.height) / 2.0, width: swt.bounds.width, height: swt.bounds.height)
            
            return swt
        }()
        contentView.addSubview(swt)

        let label = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: Margin, y: 0, width: swt.frame.minX - (2 * Margin), height: frame.height))
            label.formatSize(15)
            label.text = String.localize("LB_CS_CHAT_FORWARD_JOIN")
            return label
        }()
        contentView.addSubview(label)
        
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: Margin, y: frame.size.height - 1, width: frame.width - (2 * Margin), height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        contentView.addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
