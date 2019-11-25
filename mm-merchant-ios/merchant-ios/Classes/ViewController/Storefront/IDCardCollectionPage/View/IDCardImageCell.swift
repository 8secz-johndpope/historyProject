//
//  IDCardImageCell.swift
//  merchant-ios
//
//  Created by HungPM on 2/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

let IDCardImagelViewHeight = CGFloat(174)

class IDCardImageCell : UICollectionViewCell {
    
    var imageView: UIImageView!
    var label: UILabel!

    var imageHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: IDCardImagelViewHeight)
        self.backgroundColor = UIColor.white
        
        let marginBot = CGFloat(18)
        let LabelHeight = CGFloat(16)
        
        self.label = { () -> UILabel in
            let view = UILabel(frame: CGRect(x: 0, y: IDCardImagelViewHeight - marginBot - LabelHeight, width: self.frame.width, height: LabelHeight))
            view.textAlignment = .center
            view.formatSize(10)
            view.textColor = UIColor.secondary2()
            return view
        } ()
        
        addSubview(self.label)

        let marginTop = CGFloat(25)
        let marginLeft = CGFloat(7)
        let marginRight = CGFloat(7)
        let marginWithLabel = CGFloat(5)
        
        self.imageView = { () -> UIImageView in
            let view = UIImageView(frame: CGRect(x: marginLeft, y: marginTop, width: self.frame.width - marginLeft - marginRight, height: self.label.frame.origin.y - marginWithLabel - marginTop))
            view.contentMode = .scaleAspectFit
            view.image = UIImage(named: "Spacer")

            view.isUserInteractionEnabled = true
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(IDCardImageCell.imageTapped))
            view.addGestureRecognizer(singleTap)

            return view
            } ()
        addSubview(self.imageView)
        
        let separatorHeight = CGFloat(1)
        let paddingTop = CGFloat(7)
        
        let separatorView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: self.label.frame.maxY + paddingTop, width: frame.width, height: separatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        } ()
        addSubview(separatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func imageTapped() {
        if let callback = self.imageHandler {
            callback()
        }
    }
}
