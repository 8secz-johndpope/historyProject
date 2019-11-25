//
//  IMFilterCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class IMFilterCell: UICollectionViewCell {
    
    var tickImageView : UIImageView!
    var label : UILabel!
    var enable : Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 5.0
        self.layer.borderWidth = 1.0
        
        label = UILabel(frame:CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        label.formatSize(15)
        contentView.addSubview(label)
    
        let tickImageViewWidth = CGFloat(15)
        let tickImageViewPaddingRight = CGFloat(7)
        tickImageView = UIImageView(frame:CGRect(x: contentView.width - tickImageViewWidth - tickImageViewPaddingRight, y: (frame.size.height - tickImageViewWidth)/2, width: tickImageViewWidth, height: tickImageViewWidth))
        tickImageView.image = UIImage(named: "icon_checkbox_checked")
        tickImageView.contentMode = .scaleAspectFit
        tickImageView.isHidden = true
        contentView.addSubview(tickImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadUI() {
        if self.isSelected {
            self.layer.borderColor = UIColor.selectedRed().cgColor
            label.textAlignment = .center
            label.textColor = UIColor.selectedRed()
            tickImageView.isHidden = false
        } else {
            self.layer.borderColor = UIColor.secondary1().cgColor
            label.textAlignment = .center
            if self.enable {
                label.textColor = UIColor.secondary2()
            } else {
                label.textColor = UIColor.secondary3()
            }
            tickImageView.isHidden = true
        }
    }
    
}
