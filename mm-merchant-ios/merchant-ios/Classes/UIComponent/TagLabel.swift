//
//  TagLabel.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Kam on 28/3/2018.
//  Copyright © 2018 Leslie Zhang. All rights reserved.
//

import UIKit

enum ProductTagType: Int {
    case unknown = 0,
    crossBorder,
    shipping,
    discount,
    celebritySeries,
    merchant
}

class TagLabel: UILabel {

    var type: ProductTagType = .unknown{
        didSet {
            self.applyStyle()
        }
    }
    private static let buttonHeight = 20
    private static let buttonMinWidth = 30
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(type: ProductTagType) {
        let frame = CGRect(x: 0, y: 0, width: TagLabel.buttonMinWidth, height: TagLabel.buttonHeight)
        self.init(frame: frame)
        self.type = type
        self.applyStyle()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1
        self.layer.cornerRadius = self.bounds.height/10
        self.textAlignment = .center
        self.font = UIFont.systemFont(ofSize: 10)
        self.type = .shipping
        self.applyStyle()
        self.frame = CGRect(x: 0, y: 0, width: self.optimumWidth(), height: frame.height)
    }
    
    private func applyStyle() {
        switch type {
        case .shipping:
            self.layer.borderColor = UIColor.red.cgColor
            self.backgroundColor = .white
            self.text = "包郵"
            self.textColor = .red
        case .crossBorder:
            self.text = "海外"
            self.layer.borderColor = UIColor.black.cgColor
            self.backgroundColor = .black
            self.textColor = .white
        case .discount:
            self.text = "滿減"
            self.layer.borderColor = UIColor.red.cgColor
            self.backgroundColor = .red
            self.textColor = .white
        case .celebritySeries:
            self.text = "明星同款"
            self.layer.borderColor = UIColor.red.cgColor
            self.backgroundColor = .white
            self.textColor = .red
        default:
            self.text = "未知"
        }
    }
}
