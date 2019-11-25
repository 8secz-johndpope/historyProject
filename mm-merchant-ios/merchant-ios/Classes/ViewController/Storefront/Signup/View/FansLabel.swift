//
//  FansLabel.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 11/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class FansLabel : UIView{
    var topLabel = UILabel()
    var midLabel = UILabel()
    var bottomLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        addSubview(topLabel)
        addSubview(midLabel)
        addSubview(bottomLabel)
        topLabel.formatSize(14)
        topLabel.adjustsFontSizeToFitWidth = true;
        topLabel.minimumScaleFactor = 0.5;
        topLabel.textColor = UIColor.white
        midLabel.formatSizeBold(14)
        midLabel.adjustsFontSizeToFitWidth = true;
        midLabel.minimumScaleFactor = 0.5;
        midLabel.textColor = UIColor.white
        bottomLabel.formatSize(13)
        bottomLabel.textColor = UIColor.white
        layout()
    }
    
    override func layoutSubviews() {
        layout()
    }
    func layout(){
        topLabel.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 20)
        midLabel.frame = CGRect(x: bounds.minX, y: bounds.minY + 20 , width: bounds.width, height: 20)
        bottomLabel.frame = CGRect(x: bounds.minX, y: bounds.minY + 40, width: bounds.width, height: 20)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
