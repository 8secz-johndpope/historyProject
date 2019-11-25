//
//  TSChatListPredefinedMessageCollectionViewCell.swift
//  merchant-ios
//
//  Created by HungPM on 5/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class TSChatListPredefinedMessageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!

    var labelWidthLayoutConstraint: NSLayoutConstraint?
    
    class func fromNib() -> TSChatListPredefinedMessageCollectionViewCell?
    {
        var cell: TSChatListPredefinedMessageCollectionViewCell?
		if let nibViews = Bundle.main.loadNibNamed("TSChatListPredefinedMessageCollectionViewCell", owner: nil, options: nil) {
			for nibView in nibViews {
				if let cellView = nibView as? TSChatListPredefinedMessageCollectionViewCell {
					cell = cellView
				}
			}
		}
        return cell
    }
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if labelWidthLayoutConstraint == nil {
            labelWidthLayoutConstraint = NSLayoutConstraint(item: messageLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: Constants.ScreenSize.SCREEN_WIDTH - 20)
            labelWidthLayoutConstraint!.isActive = true
            messageLabel.addConstraint(labelWidthLayoutConstraint!)
        }
        
        separatorView.backgroundColor = UIColor.backgroundGray()
    }
}
