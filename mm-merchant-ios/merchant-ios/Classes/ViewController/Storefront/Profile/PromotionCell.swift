//
//  PromotionCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol PromotionCellDelegate: NSObjectProtocol {
    func promotionCellDidEndEditText(_ cell : PromotionCell, text : String)
}

class PromotionCell: UICollectionViewCell, UITextFieldDelegate {
    
    private var descriptionLabel : UILabel!
    private var limitationLabel : UILabel!
    private var textField : UITextField!
    
    private var topLineView : UIView!
    private var middleLineView : UIView!
    private var bottomLineView : UIView!
    
    var indexPath : IndexPath!
    
    
    private var limitationCharacter = Int(50)
    
    weak var delegate : PromotionCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let topViewHeight = CGFloat(30)
        let limitationLabelWidth = CGFloat(30)
        let leftMargin = CGFloat(13)
        let rightMargin = CGFloat(13)
        
        topLineView = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: 1))
        topLineView.backgroundColor =  UIColor.secondary1()
        
        let topView = UIView(frame: CGRect(x: 0, y: 0, width: contentView.frame.sizeWidth, height: topViewHeight))
        topView.backgroundColor = UIColor.secondary5()
        
        topView.addSubview(topLineView)
        
        descriptionLabel = UILabel(frame: CGRect(x: leftMargin, y: 0, width: contentView.frame.sizeWidth - limitationLabelWidth - rightMargin - leftMargin, height: topViewHeight))
        descriptionLabel.textColor = UIColor.secondary2()
        descriptionLabel.formatSize(15)
        
        
        limitationLabel = UILabel(frame: CGRect(x: contentView.frame.sizeWidth - limitationLabelWidth - rightMargin, y: 0, width: limitationLabelWidth, height: topViewHeight))
        limitationLabel.textColor = UIColor.secondary2()
        limitationLabel.formatSize(12)
        limitationLabel.textAlignment = .right
        
        middleLineView = UIView(frame: CGRect(x: 0, y: descriptionLabel.frame.maxY, width: contentView.frame.sizeWidth, height: 1))
        middleLineView.backgroundColor = UIColor.secondary1()
        
        topView.addSubview(descriptionLabel)
        topView.addSubview(limitationLabel)
        topView.addSubview(middleLineView)
        
        contentView.addSubview(topView)
        
        textField = UITextField(frame: CGRect(x: leftMargin, y: topViewHeight, width: contentView.frame.sizeWidth - leftMargin - rightMargin , height: contentView.frame.sizeHeight - topViewHeight))
        textField.delegate = self;
        textField.placeholder = String.localize("LB_CA_CURATOR_PROFILE_RECOM_FILL")
        textField.textColor = UIColor.secondary2()
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.clearButtonMode = .whileEditing
        textField.addTarget(self, action: #selector(PromotionCell.textFieldDidChange), for: .editingChanged)
        
        contentView.addSubview(textField)
        
        bottomLineView = UIView(frame: CGRect(x: 0, y: contentView.frame.maxY - 1, width: contentView.frame.sizeWidth, height: 1))
        bottomLineView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(bottomLineView)
        
        
    }
    
    func configCellAtIndexPath(_ indexPath : IndexPath) {
        self.indexPath = indexPath
        var recommentText = String.localize("LB_CA_CURATOR_PROFILE_RECOM")
        if recommentText.range(of: "{0}") != nil {
            recommentText = recommentText.replacingOccurrences(of: "{0}", with: String(format: "%d",(indexPath.row + 1)))
        }
        descriptionLabel.text = recommentText
        limitationLabel.text = String(format : "%d",textField.text!.length)
        switch indexPath.row {
        case 0:
            bottomLineView.isHidden = true
            break
        case 1:
            bottomLineView.isHidden = true
            break
        case 2:
            bottomLineView.isHidden = false
            break
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            delegate?.promotionCellDidEndEditText(self, text: text)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let currentString  = textField.text {
            limitationLabel.text = String(format : "%d",currentString.length)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = limitationCharacter
        let currentString: NSString = textField.text! as NSString
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        return  newString.length <= maxLength
    }
    
    
}
