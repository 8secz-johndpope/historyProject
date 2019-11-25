//
//  ValidationView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 10/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

enum ValidationType: Int {
    case length = 0
    case letter = 1
    case number = 2
    case specialCharacter = 3
    case unknow
}

class ValidationView: UIView {
    
    var imageView = UIImageView()
    var label = UILabel()
    var type: ValidationType = ValidationType.unknow
    static let ValidationViewHeight = CGFloat(22)
    var ImageViewHeight = CGFloat(14)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(frame: CGRect, type : ValidationType) {
        self.init(frame: frame)
        
        
        let margin = CGFloat(3)
        imageView.frame = CGRect(x: 0, y: (frame.size.height - ImageViewHeight) / 2, width: ImageViewHeight,height: ImageViewHeight)
        imageView.image = UIImage(named: "icon_hints_default")
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        self.addSubview(imageView)
        
        label.frame = CGRect(x: imageView.frame.maxX + margin, y: 0, width: frame.sizeWidth - imageView.frame.maxX - margin , height: ValidationView.ValidationViewHeight)
        label.textColor = UIColor.secondary3()
        label.formatSize(12)
        switch type {
        case .length:
            label.text = String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_LENGTH")
        case .letter:
            label.text = String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_LETTER")
        case .number:
            label.text = String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_NUMBER")
        case .specialCharacter:
            label.text = String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_SPECIAL_CHAR")
        default:
            break
        }
        
        self.type = type
        self.addSubview(label)

    }
    
    func validate(_ password: String) -> Bool{
        var isValid = false
        switch type {
        case .length:
            if password.length >= Constants.Value.PasswordMinLength && password.length <= Constants.Value.PasswordMaxLength {
                isValid = true
            }
        case .letter:
            isValid = password.containCharactor()
        case .number:
            isValid = password.containNumber()
        case .specialCharacter:
            isValid = password.containSpecialCharactor()
        default:
            break
        }
        self.label.textColor = isValid ? UIColor.secondary2() : UIColor.secondary4()
        imageView.image = isValid ? UIImage(named: "icon_hints_checked") : UIImage(named: "icon_hints_default")
        return isValid

    }

    class func getWidth(_ type: ValidationType) -> CGFloat {
        var result = CGFloat(22) + CGFloat(5)
        switch type {
        case .length:
            result += StringHelper.getTextWidth(String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_LENGTH"), height: ValidationView.ValidationViewHeight, font: UIFont.systemFont(ofSize: 12))
        case .letter:
            result += StringHelper.getTextWidth(String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_LETTER"), height: ValidationView.ValidationViewHeight, font: UIFont.systemFont(ofSize: 12))
        case .number:
            result += StringHelper.getTextWidth(String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_NUMBER"), height: ValidationView.ValidationViewHeight, font: UIFont.systemFont(ofSize: 12))
        case .specialCharacter:
            result += StringHelper.getTextWidth(String.localize("LB_CA_MY_ACCT_PW_CHECKLIST_SPECIAL_CHAR"), height: ValidationView.ValidationViewHeight, font: UIFont.systemFont(ofSize: 12))

        default:
            break
            
        }
        return result
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
