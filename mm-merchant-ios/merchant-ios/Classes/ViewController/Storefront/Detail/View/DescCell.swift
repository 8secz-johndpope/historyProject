//
//  DescCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class DescCell: UICollectionViewCell {
    
    static let CellIdentifier = "DescCellIdentifier"
    static let MarginDescLabel: CGFloat = 10
    
    var descLabel = UILabel()
    var upperBorderView = UIView()
    var lowerBorderView = UIView()
    
    var heightTopBorder: CGFloat = 1 {
        didSet {
            var frameTopBorder = upperBorderView.frame
            frameTopBorder.size.height = self.heightTopBorder
            upperBorderView.frame = frameTopBorder
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        DescCell.formatDescriptionTextStyle(descLabel)
        addSubview(descLabel)
        
        upperBorderView.backgroundColor = UIColor.secondary1()
        addSubview(upperBorderView)
        
        lowerBorderView.backgroundColor = UIColor.secondary1()
        addSubview(lowerBorderView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        descLabel.frame = CGRect(x: bounds.minX + DescCell.MarginDescLabel , y: bounds.minY, width: bounds.width - 2*DescCell.MarginDescLabel, height: bounds.height)
        upperBorderView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: heightTopBorder)
        lowerBorderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDescription(_ text: String){
        descLabel.text = text
        DescCell.formatDescriptionTextStyle(descLabel)
    }
    
    class func formatDescriptionTextStyle(_ label: UILabel){
        label.format()
        label.textColor = UIColor.black
        if let font = UIFont(name: "PingFangSC-Light", size: 14) {
            label.font = font
        } else {
            label.formatSizeBold(14)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        let attrString = NSMutableAttributedString(string: label.text ?? "")
        attrString.addAttribute(NSAttributedStringKey.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attrString.length))
        label.attributedText = attrString
    }
    
    class func getHeight(_ text: String, width: CGFloat) -> CGFloat {
        if text.length == 0 {
            return 0
        }
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width - 2*DescCell.MarginDescLabel, height: CGFloat.greatestFiniteMagnitude))
        label.text = text
        DescCell.formatDescriptionTextStyle(label)
        label.sizeToFit()
        
        return label.height + 40 // Margin top 20 + margin bottom 20
    }
}
