//
//  KeywordCellExtension.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 8/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class KeywordCellExtension: KeywordCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.nameLabel.formatSize(14)
        self.nameLabel.textColor = UIColor.secondary2()
        checkboxImageView.image = UIImage(named: "icon_checkbox_checked")
        self.viewBackground.backgroundColor = UIColor.white
        self.viewBackground.layer.backgroundColor = UIColor.white.cgColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func selected(_ isSelected: Bool, animated: Bool = true) {
        Log.debug("selected")
        self.isCellSelected = isSelected
        self.layoutSubviews()
        if isSelected {
            
            if animated {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
                    self.nameLabel.textColor = UIColor.primary1()
                    
                    self.viewBackground.layer.borderColor = UIColor.primary1().cgColor
                    self.checkboxImageView.isHidden = false
                    
                    }, completion: { (completed) in
                        
                        UIView.animate(withDuration: 0.1, animations: {
                            self.transform = CGAffineTransform.identity
                        })
                })
            } else {
                self.nameLabel.textColor = UIColor.primary1()
                self.viewBackground.layer.borderColor = UIColor.primary1().cgColor
                self.checkboxImageView.isHidden = false
            }
            
            
        }
        else {
            if animated {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
                    
                    }, completion: { (completed) in
                        
                        UIView.animate(withDuration: 0.1, animations: {
                            self.nameLabel.textColor = UIColor.secondary2()
                            self.viewBackground.layer.borderColor = UIColor.secondary1().cgColor
                            self.checkboxImageView.isHidden = true
                            
                            self.transform = CGAffineTransform.identity
                        })
                })
            }
            else {
                self.nameLabel.textColor = UIColor.secondary2()
                self.viewBackground.layer.borderColor = UIColor.secondary1().cgColor
                self.checkboxImageView.isHidden = true
            }
            
        }
    }
}
