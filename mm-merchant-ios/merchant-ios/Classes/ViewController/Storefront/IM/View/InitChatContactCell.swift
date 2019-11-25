//
//  InitChatContactCell.swift
//  merchant-ios
//
//  Created by HungPM on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class InitChatContactCell: UICollectionViewCell {
    
    var profileImageView: UIImageView!
    let nameLabel = UILabel()
    let tagLabel = UILabel()
    var buttonTick: UIButton!
    
    var buttonTickHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let Margin = CGFloat(10)
        let imageWidth = CGFloat(40)
        
        profileImageView = UIImageView(frame: CGRect(x: Margin, y: Margin, width: imageWidth, height: imageWidth))
        profileImageView.round()
        profileImageView.contentMode = .scaleAspectFill
        contentView.addSubview(profileImageView)
        
        nameLabel.font = UIFont.usernameFont()
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(nameLabel)
        
        tagLabel.formatSize(15)
        tagLabel.layer.borderWidth = 1
        tagLabel.layer.cornerRadius = 3
        tagLabel.layer.borderColor = UIColor.backgroundGray().cgColor
        tagLabel.textAlignment = .center
        tagLabel.numberOfLines = 1
        tagLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(tagLabel)
        
        let buttonWidth = CGFloat(30)
        buttonTick = UIButton(type: .custom)
        buttonTick.setImage(UIImage(named: "icon_checkbox_unchecked2"), for: UIControlState())
        buttonTick.frame = CGRect(x: frame.width - buttonWidth - Margin, y: (frame.size.height - buttonWidth) / 2.0, width: buttonWidth, height: buttonWidth)
        buttonTick.addTarget(self, action: #selector(toggleCheckBox), for: .touchUpInside)
        contentView.addSubview(buttonTick)

        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: frame.size.height - 1, width: frame.width, height: 1))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        }()
        contentView.addSubview(separatorView)
        
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let Margin = CGFloat(10)
        
        let maxWidth = buttonTick.frame.minX - 5
        nameLabel.sizeToFit()
        nameLabel.frame = CGRect(x: profileImageView.frame.maxX + Margin, y: (frame.height - nameLabel.frame.height) / 2.0, width: nameLabel.frame.width, height: nameLabel.frame.height)
        
        tagLabel.sizeToFit()
        tagLabel.frame = CGRect(x: nameLabel.frame.maxX + Margin, y: (frame.height - tagLabel.frame.height - 10) / 2.0, width: tagLabel.frame.width + 10, height: tagLabel.frame.height + 10)
        
        if !tagLabel.isHidden {
            if nameLabel.frame.maxX >= maxWidth {
                nameLabel.frame = CGRect(x: profileImageView.frame.maxX + Margin, y: (frame.height - nameLabel.frame.height) / 2.0, width: maxWidth - (profileImageView.frame.maxX + Margin), height: nameLabel.frame.height)
                tagLabel.isHidden = true
            }
            else if tagLabel.frame.maxX >= maxWidth {
                let threshold = CGFloat(35)
                let width = maxWidth - (nameLabel.frame.maxX + 2 * Margin) + 10
                
                if width < threshold {
                    tagLabel.isHidden = true
                    nameLabel.text = nameLabel.text! + " ..."
                    nameLabel.frame = CGRect(x: profileImageView.frame.maxX + Margin, y: (frame.height - nameLabel.frame.height) / 2.0, width: maxWidth - (profileImageView.frame.maxX + Margin), height: nameLabel.frame.height)
                }
                else {
                    tagLabel.frame = CGRect(x: nameLabel.frame.maxX + Margin, y: (frame.height - tagLabel.frame.height - 10) / 2.0, width: width, height: tagLabel.frame.height + 10)
                }
            }
        }
        else {
            if nameLabel.frame.maxX >= maxWidth {
                nameLabel.frame = CGRect(x: profileImageView.frame.maxX + Margin, y: (frame.height - nameLabel.frame.height) / 2.0, width: maxWidth - (profileImageView.frame.maxX + Margin), height: nameLabel.frame.height)
            }
        }
    }
    
    @objc func toggleCheckBox() {
        buttonTickHandler?()
    }
    
    func setGrayCheckBox() {
        buttonTick.setImage(UIImage(named: "icon_checkbox_checked_gray"), for: .selected)
    }
    
    func setRedCheckBox() {
        buttonTick.setImage(UIImage(named: "icon_checkbox_checked"), for: .selected)
    }
}
