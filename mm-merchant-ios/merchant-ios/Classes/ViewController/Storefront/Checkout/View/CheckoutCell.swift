//
//  CheckoutCell.swift
//  merchant-ios
//
//  Created by HungPM on 3/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CheckoutCell: UICollectionViewCell {
    var touchHandler: (() -> Void)?

    static let CellIdentifier = "CheckoutCellID"
    
    private final let LeftMargin: CGFloat = 20
    private final let RightMargin: CGFloat = 10
    
    
    var leftLabel: UILabel!
    var rightLabel: UILabel!
    
    private var arrowView = UIImageView()
    private var topSeparatorView = UIView()
    private var bottomSeparatorView = UIView()
    private var touchButton = UIButton()
    private var rightView = UIView()
    
    var rightViewTapHandler: (() -> Void)?
    
    private var hasArrow = true
    private var isFullSeparator = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        leftLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: LeftMargin, y: 0, width: 100, height: frame.height))
            label.formatSize(15)
            
            return label
        }()
        addSubview(leftLabel)
        
        rightView = { () -> UIView in
            let view = UIView(frame: CGRect(x: leftLabel.frame.maxX, y: 0, width: frame.width - leftLabel.frame.maxX, height: frame.height))
            
            let arrowRightMargin: CGFloat = 10
            let arrowWidth: CGFloat = 32
            
            arrowView.frame = CGRect(x: view.width - arrowWidth - arrowRightMargin, y: (view.height - arrowWidth) / 2, width: arrowWidth, height: arrowWidth)
            arrowView.image = UIImage(named: "icon_arrow_small")
            arrowView.contentMode = .scaleAspectFit
            view.addSubview(arrowView)

            self.rightLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: arrowView.frame.minX, height: view.height))
                label.formatSize(15)
                label.textAlignment = .right
                
                return label
            }()
            view.addSubview(self.rightLabel)
            
            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewDidTapped))
            view.addGestureRecognizer(singleTapGesture)
            
            return view
        }()
        addSubview(rightView)
        
        topSeparatorView.backgroundColor = UIColor.backgroundGray()
        addSubview(topSeparatorView)
        
        bottomSeparatorView.backgroundColor = UIColor.backgroundGray()
        addSubview(bottomSeparatorView)
        
        touchButton.backgroundColor = UIColor.clear
        touchButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
        addSubview(touchButton)
    }
    
    @objc private func actionTap(_ sender: UIButton){
        if let callback = self.touchHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leftLabel.frame = CGRect(x: LeftMargin, y: 0, width: 100, height: frame.height)
        rightView.frame = CGRect(x: leftLabel.frame.maxX, y: 0, width: frame.width - leftLabel.frame.maxX, height: frame.height)
        
        let arrowRightMargin = CGFloat(10)
        let arrowWidth: CGFloat = hasArrow ? 32 : 0
        arrowView.frame = CGRect(x: rightView.width - arrowWidth - arrowRightMargin, y: (rightView.height - arrowWidth) / 2, width: arrowWidth, height: arrowWidth)
        rightLabel.frame = CGRect(x: 0, y: 0, width: hasArrow ? arrowView.frame.minX : arrowView.frame.minX - arrowRightMargin, height: rightView.height)
        
        let separatorLeftMargin = isFullSeparator ? 0 : LeftMargin
        let separatorRightMargin = isFullSeparator ? 0 : RightMargin
        
        topSeparatorView.frame = CGRect(x: separatorLeftMargin, y: 0, width: frame.width - separatorLeftMargin - separatorRightMargin, height: 1)
        bottomSeparatorView.frame = CGRect(x: separatorLeftMargin, y: frame.sizeHeight - 1, width: frame.width - separatorLeftMargin - separatorRightMargin, height: 1)
        touchButton.frame = CGRect(x: 0, y: 0, width: UIScreen.width(), height: bottomSeparatorView.frame.maxY)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setStyle(withArrow hasArrow: Bool = true, topSeparator hasTopSeparator: Bool = true, bottomSeparator hasBottomSeparator: Bool = true, isFullSeparator: Bool = false) {
        self.hasArrow = hasArrow
        self.isFullSeparator = isFullSeparator
        arrowView.isHidden = !hasArrow
        
        rightLabel.width = arrowView.frame.minX
        
        let arrowRightMargin = CGFloat(10)
        let arrowWidth: CGFloat = hasArrow ? 32 : 0
        arrowView.frame = CGRect(x: rightView.width - arrowWidth - arrowRightMargin, y: (rightView.height - arrowWidth) / 2, width: arrowWidth, height: arrowWidth)
        rightLabel.frame = CGRect(x: 0, y: 0, width: hasArrow ? arrowView.frame.minX : arrowView.frame.minX - arrowRightMargin, height: rightView.height)
        
        topSeparatorView.isHidden = !hasTopSeparator
        bottomSeparatorView.isHidden = !hasBottomSeparator
    }
    
    func setDefaultFont() {
        rightLabel.formatSize(15)
    }
    
    func setPriceFont() {
        rightLabel.textColor = UIColor.primary1()
    }
    
    func setNormalFont() {
        rightLabel.textColor = UIColor.black
    }
    
    func setSecondaryFont() {
        rightLabel.textColor = UIColor.secondary2()
    }
    
    @objc func viewDidTapped() {
        if let callback = self.rightViewTapHandler {
            callback()
        }
    }
}
