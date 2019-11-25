//
//  TextCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class TextCell: UICollectionViewCell {
    
    static let CellIdentifier = "TextCellCellID"
    var label = UILabel()
    
    var data: TextCellData?{
        didSet{
            if let data = self.data{
                label.formatSize(data.fontSize)
                label.text = data.text
                label.textColor = data.textColor
                label.textAlignment = data.textAlignMent
                if data.isFormattedUnderline{
                    label.formatUnderline()
                }
                layoutSubviews()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.formatSize(12)
        self.addSubview(label)
    }
    
    //MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelHeight = label.optimumHeight(width: self.width)
        let labelWidth = label.optimumWidth(height: labelHeight)
        label.frame = CGRect(x: (self.width - labelWidth)/2,y: (self.height - labelHeight)/2,width: labelWidth,height: labelHeight)
    }
}

class TextCellData {
    var text: String = ""
    var textColor = UIColor.black
    var textAlignMent = NSTextAlignment.center
    var isFormattedUnderline = false
    var fontSize: Int = 12
    init(text: String = ""){
        self.text = text
    }
}
