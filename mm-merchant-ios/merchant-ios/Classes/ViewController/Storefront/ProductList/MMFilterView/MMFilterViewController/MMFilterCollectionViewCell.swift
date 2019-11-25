//
//  MMFilterCollectionViewCell.swift
//  storefront-ios
//
//  Created by Demon on 19/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMFilterCollectionViewCell: UICollectionViewCell {
    
    var isSelectedCell: Bool = false {
        didSet {
            if isSelectedCell == true {
                backgroundColor = UIColor(hexString: "#ED2247").withAlphaComponent(0.05)
                layer.borderColor = UIColor(hexString: "#ED2247").cgColor
                layer.borderWidth = 0.5
                titleLb.textColor = UIColor(hexString: "#ED2247")
            } else {
                backgroundColor = UIColor(hexString: "#F5F5F5")
                layer.borderColor = nil
                layer.borderWidth = 0
                titleLb.textColor = UIColor(hexString: "#6B6B6B")
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadUI()
    }

    private func loadUI() {
        layer.cornerRadius = 4
        layer.masksToBounds = true
        backgroundColor = UIColor(hexString: "#F5F5F5")
        
        contentView.addSubview(titleLb)
        contentView.addSubview(colorImageView)
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        titleLb.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(self.snp.left).offset(3)
            make.right.equalTo(self.snp.right).offset(-3)
        }
        colorImageView.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.height.equalTo(14)
        }
        super.updateConstraints()
    }
    
    lazy var titleLb: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textColor = UIColor(hexString: "#6B6B6B")
        return lb
    }()
    
    lazy var colorImageView: UIImageView = {
        let v = UIImageView()
        v.isHidden = true
        v.layer.cornerRadius = 7
        v.layer.masksToBounds = true
        v.backgroundColor = UIColor(hexString: "#F5F5F5")
        return v
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
