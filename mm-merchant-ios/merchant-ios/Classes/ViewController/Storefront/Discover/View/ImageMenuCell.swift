//
//  ImageMenuCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 8/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation


class ImageMenuCell : UICollectionViewCell{
    var imageView = UIImageView()
    var upperLabel = UILabel()
    var lowerLabel = UILabel()
    var borderView = UIView()
    var tickImageView = UIImageView()
    var topLine = UILabel()
    var rightButton = UIButton(type: .custom)
    
    private final let MarginCenter : CGFloat = 21
    private final let LogoMarginRight : CGFloat = 10
    private final let LogoMarginLeft : CGFloat = 10
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let LogoWidth : CGFloat = 44
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let TickImageWidth : CGFloat = 16
    private final let SizeRightButton = CGSize(width: 60, height: 26)
    var rightButtonTappedHandler: (() -> Void)?
    var marginLeftRight : CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addSubview(imageView)
        upperLabel.formatSize(15)
        addSubview(upperLabel)
        lowerLabel.formatSize(12)
        addSubview(lowerLabel)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        addSubview(tickImageView)
        topLine.backgroundColor = UIColor.secondary1()
        addSubview(topLine)
        
        rightButton.isHidden = true
        rightButton.layer.cornerRadius = 2
        rightButton.layer.borderWidth = 0
        
        rightButton.formatPrimary()
        rightButton.setTitle(String.localize("LB_CA_MLP_ENTER"), for: UIControlState())
        rightButton.setTitleColor(UIColor.white, for: UIControlState())
        rightButton.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        addSubview(rightButton)
        
        layoutSubviews()
    }
    
    @objc func rightButtonTapped() {
        if let callback = self.rightButtonTappedHandler {
            callback()
        }
    }
    
    //If don't set style by zone, this will be showed as default setup cell

    func setStyleByZone(_ zone: ColorZone) {
        rightButton.isHidden = false
        rightButton.layer.cornerRadius = 2
        upperLabel.formatSizeBold(15)
        imageView.layer.cornerRadius = LogoWidth/2
        borderView.alpha = 0.2
        
        switch (zone) {
        case .blackZone:
            rightButton.backgroundColor = UIColor.secondary2()
        case .redZone:
            rightButton.backgroundColor = UIColor.primary1()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topLine.frame = CGRect(x: bounds.minX, y: 0, width: bounds.width, height: 1)
        imageView.frame = CGRect(x: bounds.minX + LogoMarginLeft + marginLeftRight, y: bounds.midY - LogoWidth / 2, width: LogoWidth, height: LogoWidth)
        rightButton.frame = CGRect(x: bounds.width - LogoMarginLeft - SizeRightButton.width, y: (bounds.height - SizeRightButton.height) / 2, width: SizeRightButton.width, height: SizeRightButton.height)
        upperLabel.frame = CGRect(x: imageView.frame.maxX + LogoMarginLeft, y: bounds.minY + LabelMarginTop, width: bounds.width - (imageView.frame.maxX + LogoMarginLeft * 2 + TickImageWidth) , height: bounds.height/3 )
        lowerLabel.frame = CGRect(x: imageView.frame.maxX + LogoMarginLeft, y: LabelLowerMarginTop, width: bounds.width - (imageView.frame.maxX + LogoMarginLeft * 2 + TickImageWidth) , height:bounds.height/3 )
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        tickImageView.frame = CGRect(x: bounds.width - (TickImageWidth + LogoMarginLeft), y: bounds.midY - 5, width: TickImageWidth, height: 10)
        
        if !rightButton.isHidden {
            upperLabel.frame.sizeWidth = upperLabel.frame.sizeWidth - rightButton.frame.sizeWidth
            lowerLabel.frame.sizeWidth = lowerLabel.frame.sizeWidth - rightButton.frame.sizeWidth
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ key: String, imageCategory: ImageCategory, size: ResizerSize = .size1000) {
        layoutSubviews()
        let url = ImageURLFactory.URLSize(size, key: key, category: imageCategory)
        imageView.mm_setImageWithURL(url, placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFit)
    }
}
