//
//  IDCardNumberCell.swift
//  merchant-ios
//
//  Created by HungPM on 2/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

var IDCardNumberViewHeight = CGFloat(84)

class IDCardNumberCell : UICollectionViewCell {
    
    var textField: UITextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: IDCardNumberViewHeight)
        self.backgroundColor = UIColor.white
        
        let marginLeft = CGFloat(11)
        let marginTop = CGFloat(19)

        let viewContainer = { () -> UIView in
            let view = UIView(frame: CGRect(x: marginLeft, y: marginTop, width: frame.width - 2 * marginLeft, height: IDCardNumberViewHeight - 2 * marginTop))
            view.layer.borderWidth = 1.0
            view.layer.borderColor = UIColor.secondary1().cgColor
            
            self.textField = { () -> UITextField in
                let Padding = CGFloat(22)
                let view = UITextField(frame: CGRect(x: Padding, y: 0, width: view.frame.width - 2 * Padding, height: view.frame.height))
                view.placeholder = String.localize("LB_ID_NO")
                view.textColor = UIColor.secondary3()
				view.font = UIFont(name: view.font!.fontName, size: 14)
                return view
                } ()
            view.addSubview(self.textField)
            
            return view
        } ()
        addSubview(viewContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
