//
//  GroupChatName.swift
//  merchant-ios
//
//  Created by HungPM on 6/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class GroupChatName: UIView {
    
    final var lblName = UILabel()
    final var btnTag = UIButton(type: .custom)
    
    private final var lblComma: UILabel!
    final var isCurator = false
    
    final let CommaWidth = CGFloat(10)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = true
        
        lblComma = UILabel(frame: CGRect(x: 0, y: 0, width: CommaWidth, height: 20))
        lblComma.isHidden = true
        lblComma.textColor = .black
        lblComma.font = UIFont.usernameFont()

        lblName.font = UIFont.usernameFont()
        lblName.textColor = .black
        lblName.numberOfLines = 1
        lblName.lineBreakMode = .byTruncatingTail

        btnTag.layer.borderWidth = 0.5
        btnTag.layer.cornerRadius = 3
        btnTag.layer.borderColor = UIColor.lightGray.cgColor
        btnTag.contentEdgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        btnTag.isEnabled = false
        btnTag.setTitleColor(UIColor.darkGray, for: UIControlState())
        btnTag.titleLabel?.lineBreakMode = .byTruncatingTail
        btnTag.titleLabel?.font = UIFont(name: btnTag.titleLabel!.font.fontName, size: CGFloat(12))!
        
        self.addSubview(lblComma)
        self.addSubview(lblName)
        self.addSubview(btnTag)
    }
    
    convenience init(nameModel: NameModel) {
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
        
        self.configViewWithName(nameModel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout() {
        let Margin = CGFloat(5)
        
        lblName.sizeToFit()
        lblName.frame = CGRect(x: lblComma.isHidden ? 0 : lblComma.frame.maxX, y: (frame.height - lblName.frame.height) / 2.0, width: lblName.frame.width, height: lblName.frame.height)
        
        btnTag.sizeToFit()
        btnTag.frame = CGRect(x: lblName.frame.maxX + Margin, y: (frame.height - btnTag.frame.height) / 2.0, width: btnTag.frame.width, height: btnTag.frame.height)
        
        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: btnTag.isHidden ? lblName.frame.maxX : btnTag.frame.maxX, height: self.frame.height)
    }
    
    func configViewWithName(_ nameModel: NameModel) {
        self.isCurator = nameModel.isCurator
        
        if isCurator {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "curator_diamond")
            attachment.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
            
            let attachmentString = NSAttributedString(attachment: attachment)
            
            let attString = NSMutableAttributedString(string: nameModel.name)
            attString.append(attachmentString)
            
            lblName.attributedText = attString
        }
        else {
            lblName.text = nameModel.name
        }
        
        if let tagName = nameModel.merchantName {
            btnTag.setTitle(tagName, for: UIControlState())
            btnTag.isHidden = false
        }
        else {
            btnTag.isHidden = true
        }
        
        setupLayout()
    }
    
    func addComma() {
        lblComma.text = ", "
        lblComma.isHidden = false
        setupLayout()
    }
}

class GroupChatNameContainer: UIView {
    
    private final let Threshold = CGFloat(35)
    
    func setCombineNames(_ groupChatNames: [GroupChatName], maxWidth: CGFloat) {
        for view in self.subviews {
            view.removeFromSuperview()
            self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 0, height: self.frame.height)
        }
        
        for (index, groupChatName) in groupChatNames.enumerated() {
            var width: CGFloat!
            
            if index == 0 {
                width = self.frame.width + groupChatName.frame.width
            } else {
                width = self.frame.width + groupChatName.frame.width + groupChatName.CommaWidth
            }
            
            if width <= maxWidth {
                if index != 0 {
                    groupChatName.addComma()
                }
                
                groupChatName.frame = CGRect(x: self.frame.width, y: 0, width: groupChatName.frame.width, height: groupChatName.frame.height)
                
                self.addSubview(groupChatName)
                self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: self.frame.height)
            } else {
                let previousIndex = index - 1
                if self.frame.width + Threshold >= maxWidth && (groupChatNames.count > previousIndex && previousIndex >= 0) {
                    let previousGroupName = groupChatNames[index - 1]
                    if !previousGroupName.btnTag.isHidden {
                        let tagWidth = maxWidth - previousGroupName.btnTag.frame.minX - previousGroupName.frame.minX
                        
                        let title = previousGroupName.btnTag.titleLabel?.text
                        previousGroupName.btnTag.setTitle(title! + "...", for: UIControlState())
                        previousGroupName.btnTag.frame = CGRect(x: previousGroupName.btnTag.frame.origin
                            .x, y: previousGroupName.btnTag.frame.origin.y, width: tagWidth, height: previousGroupName.btnTag.frame.height)
                        
                        previousGroupName.frame = CGRect(x: previousGroupName.frame.origin.x, y: previousGroupName.frame.origin.y, width: previousGroupName.btnTag.frame.maxX, height: previousGroupName.frame.height)
                    }
                    else {
                        
                        let extendWidth = previousGroupName.frame.width - previousGroupName.CommaWidth + maxWidth - self.frame.width
                        
                        previousGroupName.lblName.text = previousGroupName.lblName.text! + "..."
                        previousGroupName.lblName.frame = CGRect(x: previousGroupName.lblName.frame.origin.x, y: previousGroupName.lblName.frame.origin.y, width: extendWidth, height: previousGroupName.lblName.frame.height)
                        
                        previousGroupName.frame = CGRect(x: previousGroupName.frame.origin.x, y: previousGroupName.frame.origin.y, width: previousGroupName.lblName.frame.maxX, height: previousGroupName.frame.height)
                    }
                    
                }
                else {
                    if index != 0 {
                        groupChatName.addComma()
                    }
                    
                    if self.frame.width + groupChatName.lblName.frame.maxX > maxWidth {
                        if groupChatName.isCurator {
                            let attString = NSMutableAttributedString(attributedString: groupChatName.lblName.attributedText!)
                            attString.append(NSAttributedString(string: "..."))
                            groupChatName.lblName.attributedText = attString
                        }
                        else {
                            groupChatName.lblName.text = groupChatName.lblName.text! + "..."
                        }
                        
                        groupChatName.lblName.frame = CGRect(x: groupChatName.lblName.frame.origin.x, y: groupChatName.lblName.frame.origin.y, width: maxWidth - self.frame.width - groupChatName.CommaWidth, height: groupChatName.lblName.frame.height)
                    }
                    else {
                        if !groupChatName.btnTag.isHidden {
                            let tagWidth = maxWidth - self.frame.width - groupChatName.btnTag.frame.minX
                            
                            if tagWidth < Threshold {
                                groupChatName.btnTag.isHidden = true
                                
                                if groupChatName.isCurator {
                                    let attString = NSMutableAttributedString(attributedString: groupChatName.lblName.attributedText!)
                                    attString.append(NSAttributedString(string: "..."))
                                    groupChatName.lblName.attributedText = attString
                                }
                                else {
                                    groupChatName.lblName.text = groupChatName.lblName.text! + "..."
                                }
                                
                                groupChatName.lblName.frame = CGRect(x: groupChatName.lblName.frame.origin.x, y: groupChatName.lblName.frame.origin.y, width: maxWidth - self.frame.width - groupChatName.CommaWidth, height: groupChatName.lblName.frame.height)
                            }
                            else {
                                groupChatName.btnTag.frame = CGRect(x: groupChatName.btnTag.frame.origin
                                    .x, y: groupChatName.btnTag.frame.origin.y, width: tagWidth, height: groupChatName.btnTag.frame.height)
                            }
                        }
                    }
                    
                    groupChatName.frame = CGRect(x: self.frame.width, y: 0, width: maxWidth - self.frame.width, height: groupChatName.frame.height)
                    self.addSubview(groupChatName)
                }
                
                self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: maxWidth, height: self.frame.height)
                break
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class NameModel {
    var name = ""
    var isCurator = false
    var merchantName: String? = nil
    
    init(name: String, isCurator: Bool = false, merchantName: String? = nil) {
        self.name = name
        self.isCurator = isCurator
        self.merchantName = merchantName
    }
}
