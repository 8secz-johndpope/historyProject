//
//  SwipeMenuOptionView.swift
//  merchant-ios
//
//  Created by Alan YU on 5/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SwipeMenuOptionView: UIView {
    
    fileprivate(set) var iconView = { () -> UIImageView in
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    } ()
    fileprivate(set) lazy var titleLabel =  { () -> UILabel in
        let label = UILabel()
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    } ()
    private lazy var triggerButton =  { () -> UIButton in
        let button = UIButton(type: .custom)
        return button
    } ()
    private var container = UIView()
    
    var position = MenuOptionPosition.right
    var optionWidth = CGFloat(0)
    var data: SwipeActionMenuCellData? {
        didSet {
            if let data = self.data {
                self.iconView.image = data.icon
                self.titleLabel.text = data.text
                self.backgroundColor = data.backgroundColor
                self.titleLabel.textColor = data.textColor
            }
        }
    }
    
    var actionHander: (() -> Void)?
    
    init(frame: CGRect, position: MenuOptionPosition) {
        super.init(frame: frame)
        self.position = position
        self.backgroundColor = UIColor.gray
        self.triggerButton.addTarget(self, action: #selector(SwipeMenuOptionView.fireAction), for: .touchUpInside)
        self.container.addSubview(self.triggerButton)
        self.container.addSubview(self.iconView)
        self.container.addSubview(self.titleLabel)
        self.addSubview(self.container)
    }

    @objc func fireAction() {
        if let data = self.data, let action = data.action {
            action()
            if let actionHandler = self.actionHander {
                actionHandler()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let widthHeightRatio = CGFloat(9.0 / 13.0)
        let frame = self.bounds
        let height = frame.size.height
        let iconHeight = height * 0.7
        let labelHeight = height - iconHeight
        let imageIconSize = CGSize(width: 40, height: 40)
        
        if self.optionWidth == 0 {
           self.optionWidth = CGFloat(height * widthHeightRatio)
        }
        
        var xPos = CGFloat(0)
        
        if self.position == .left {
            xPos = frame.size.width - self.optionWidth
        }
        self.container.frame = CGRect(x: xPos, y: 0, width: self.optionWidth, height: height)
        self.triggerButton.frame = self.container.bounds
        
        let iconXPos = (self.optionWidth - imageIconSize.width) / 2.0
        let iconYPos = (iconHeight - imageIconSize.height) / 2.0
        self.iconView.frame = CGRect(x: iconXPos, y: iconYPos, width: imageIconSize.width, height: imageIconSize.height)
        self.titleLabel.frame = CGRect(x: 0, y: iconView.frame.maxY, width: self.optionWidth, height: labelHeight)
    }
    
}
