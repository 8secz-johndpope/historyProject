//
//  TagCell.swift
//  UICollectionViewTest
//
//  Created by HVN_Pivotal on 1/28/16.
//  Copyright © 2016 HVN_Pivotal. All rights reserved.
//

import Foundation
import UIKit
class KeywordCell: UICollectionViewCell {
    private final let ImageHeight: CGFloat = 15
    private final let TextMarginLeft: CGFloat = 14
    private final let BackgroundMarginLeft: CGFloat = 2
    
    private final let MarginTop: CGFloat = 4
    var nameLabel = UILabel()
    var viewBackground = UIView()
    var checkboxImageView = UIImageView()
    var isCellSelected = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewBackground.backgroundColor = UIColor.clear
        viewBackground.layer.borderColor = UIColor.white.cgColor
        viewBackground.layer.cornerRadius = 2
        viewBackground.clipsToBounds = true
        viewBackground.layer.borderWidth = 1.0
        addSubview(viewBackground)
        
        nameLabel.formatSize(13)
        nameLabel.textColor = UIColor.white
        nameLabel.textAlignment = .center

        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        addSubview(nameLabel)
        checkboxImageView.image = UIImage(named: "tick_icon")
        checkboxImageView.isHidden = true
        addSubview(checkboxImageView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var textMarginLeft = TextMarginLeft
        if self.isCellSelected {
            textMarginLeft = TextMarginLeft / 2
        }
        nameLabel.frame = CGRect(x: textMarginLeft , y: 0, width: self.bounds.maxX - TextMarginLeft * 2, height: self.bounds.maxY)
        viewBackground.frame = CGRect(x: BackgroundMarginLeft, y: MarginTop, width: self.bounds.maxX - BackgroundMarginLeft * 2, height: self.bounds.maxY - MarginTop * 2)
        checkboxImageView.frame = CGRect(x: self.bounds.maxX - (ImageHeight + 10), y: (self.bounds.height - ImageHeight) / 2, width: ImageHeight, height: ImageHeight)
    }
    
    func selected(_ isSelected: Bool, animated: Bool = true) {
        Log.debug("selected")
        self.isCellSelected = isSelected
        self.layoutSubviews()
        if isSelected {
            
            if animated {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
                    self.nameLabel.textColor = UIColor.secondary2()
                    self.viewBackground.backgroundColor = UIColor.white
                    self.viewBackground.layer.backgroundColor = UIColor.white.cgColor
                    self.checkboxImageView.isHidden = false
                    
                    }, completion: { (completed) in
                        
                        UIView.animate(withDuration: 0.1, animations: {
                            self.transform = CGAffineTransform.identity
                        })
                })
            } else {
                self.nameLabel.textColor = UIColor.secondary2()
                self.viewBackground.backgroundColor = UIColor.white
                self.viewBackground.layer.backgroundColor = UIColor.white.cgColor
                self.checkboxImageView.isHidden = false
            }
           
            
        }
        else {
            if animated {
                UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
                    
                    }, completion: { (completed) in
                        
                        UIView.animate(withDuration: 0.1, animations: {
                            self.nameLabel.textColor = UIColor.white
                            self.viewBackground.backgroundColor = UIColor.clear
                            self.viewBackground.layer.backgroundColor = UIColor.black.withAlphaComponent(0.3).cgColor
                            self.checkboxImageView.isHidden = true
                            
                            self.transform = CGAffineTransform.identity
                        })
                })
            }
            else {
                self.nameLabel.textColor = UIColor.white
                self.viewBackground.backgroundColor = UIColor.clear
                self.viewBackground.layer.backgroundColor = UIColor.black.withAlphaComponent(0.3).cgColor
                self.checkboxImageView.isHidden = true
            }

        }
    }
    
}
