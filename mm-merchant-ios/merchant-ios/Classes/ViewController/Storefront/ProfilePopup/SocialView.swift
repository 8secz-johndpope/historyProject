//
//  SocialView.swift
//  merchant-ios
//
//  Created by LongTa on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class SocialView: UIView {

    let ovalButton = UIButton()
    static let ovalSize = CGSize(width:42,height: 41)

    let label = UILabel()
    static let labelPaddingTop:CGFloat = 0
    static let labelHeight:CGFloat = 20
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        ovalButton.contentMode = .scaleAspectFit
        addSubview(ovalButton)
        
        label.formatSmall()
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 0
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    func setupLayouts() {
        
        ovalButton.frame = CGRect(x: (self.bounds.sizeWidth - SocialView.ovalSize.width)/2 , y: 0, width: SocialView.ovalSize.width, height: SocialView.ovalSize.height)
        
        label.frame = CGRect(x: 0, y: ovalButton.frame.maxY + SocialView.labelPaddingTop, width: self.frame.sizeWidth, height: SocialView.labelHeight)
    }
    
    class func defaultHeight() -> CGFloat{
        return SocialView.ovalSize.height + SocialView.labelPaddingTop + SocialView.labelHeight
    }
}
