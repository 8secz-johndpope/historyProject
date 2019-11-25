//
//  ZoneBottomCollectionCell.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/24/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import SnapKit

class ZoneBottomCollectionCell: UICollectionViewCell {
    static let CellIdentifier: String = "ZoneBottomCollectionCellID"
    static let DefaultHeight: CGFloat = 115
    var bottonZoneType: ColorZone = ColorZone.redZone{
        didSet{
            if (bottonZoneType == ColorZone.redZone){
                imageArrow.image = UIImage(named: "arrow_red")
            }
            if (bottonZoneType == ColorZone.blackZone){
                imageArrow.image = UIImage(named: "arrow_black")
            }
        }
    }
    var productCountLabel = UILabel()
    var zoneValueLabel = UILabel()
    private let imageArrow: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "arrow_red"))
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.secondary9()
        productCountLabel.formatSizeBold(12)
        productCountLabel.textAlignment = .center
        productCountLabel.textColor = UIColor(hexString: "#4A4A4A")
        zoneValueLabel.formatSize(12)
        zoneValueLabel.textAlignment = .center
        zoneValueLabel.textColor = UIColor.secondary2()
        addSubview(productCountLabel)
        addSubview(zoneValueLabel)
        addSubview(imageArrow)
        
        productCountLabel.snp.makeConstraints { (target) in
            target.height.equalTo(13)
            target.width.equalTo(width)
            target.top.equalTo(25)
            target.centerX.equalTo(self)
        }
        
        zoneValueLabel.snp.makeConstraints { (target) in
            target.height.equalTo(13)
            target.width.equalTo(width)
            target.top.equalTo(48)
            target.centerX.equalTo(self)
        }
        
        imageArrow.snp.makeConstraints { (target) in
            target.width.height.equalTo(20)
            target.top.equalTo(70)
            target.centerX.equalTo(self)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        productCountLabel.frame = CGRect(origin: CGPoint(x: 0, y: 100), size: CGSize(width: width, height: 30))
//        zoneValueLabel.frame = CGRect(origin: CGPoint(x: 0, y: productCountLabel.frame.maxY-10), size: CGSize(width: width, height: 30))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    func didSelectZoneLabel(_ sender: UILabel){
        
    }
}
