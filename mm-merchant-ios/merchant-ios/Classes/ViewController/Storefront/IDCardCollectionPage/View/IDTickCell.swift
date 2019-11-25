//
//  IDTickCell.swift
//  merchant-ios
//
//  Created by HungPM on 2/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

var IDTickViewHeight = CGFloat(28)

class IDTickCell : UICollectionViewCell {
    
    var checkboxButton : UIButton!
    var linkButton : UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: IDTickViewHeight)
        self.backgroundColor = UIColor.white
        
        //Create checkbox button
        self.checkboxButton = { () -> UIButton in
            let MarginLeft = CGFloat(20)
            
            let btn = UIButton(type: .custom)
            btn.frame = CGRect(x: MarginLeft, y: 0, width: 0, height: 0)
            btn.setImage(UIImage(named: "square_check_box"), for: UIControlState())
            btn.setImage(UIImage(named: "square_check_box_selected"), for: UIControlState.selected)
            btn.setTitle(" " + String.localize("LB_CA_TNC_CHECK"), for: UIControlState())
            btn.setTitleColor(UIColor.secondary2(), for: UIControlState())
            btn.titleLabel?.formatSize(11)
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
            btn.sizeToFit()
            
            btn.frame = CGRect(x: MarginLeft, y: (IDTickViewHeight - btn.frame.height) / 2, width: btn.frame.width, height: btn.frame.height)

            return btn
        } ()
        addSubview(self.checkboxButton)
        
        //Create link button
        self.linkButton = { () -> UIButton in
            let btn = UIButton(type: .custom)
            btn.frame = CGRect(x: self.checkboxButton.frame.maxX, y: 0, width: 0, height: 0)
            
            btn.setTitle(String.localize("LB_CA_TNC_LINK"), for: UIControlState())
            btn.titleLabel?.formatSize(11)
            btn.setTitleColor(UIColor.primary1(), for: UIControlState())
            btn.sizeToFit()
            
            btn.frame = CGRect(x: self.checkboxButton.frame.maxX, y: (IDTickViewHeight - btn.frame.height) / 2, width: btn.frame.width, height: btn.frame.height)

            return btn
        } ()
        addSubview(self.linkButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
