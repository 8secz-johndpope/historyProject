//
//  MMTabBar.swift
//  storefront-ios
//
//  Created by Demon on 24/8/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

@objc protocol MMTabBarDelegate {
    func tabbarItemSelected(index: Int)
}

class MMTabBar: UITabBar {
    
    weak var itemDelegate: MMTabBarDelegate?
    var buttonItems = [MMTabBarButton]()

    private var currentSelectedItem: MMTabBarButton!
    private var previousSelectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @objc private func tabbarButtonClick(button: MMTabBarButton) {
        if let delegate = itemDelegate {
            delegate.tabbarItemSelected(index: button.tag)
        }
    }
    
    public func changeItemStatus(selectedIndex: Int) {
        let previousBtn = buttonItems[previousSelectedIndex]
        previousBtn.isSelected = !previousBtn.isSelected
        let currentBtn = buttonItems[selectedIndex]
        currentBtn.isSelected = !currentBtn.isSelected
        previousSelectedIndex = selectedIndex
    }
    
    public func buildTabBarItem(infos: [MMTabbarInfo]) {
        buttonItems.removeAll()
        let itemWidth = ScreenWidth/CGFloat(infos.count)
        for (index, info) in infos.enumerated() {
            let tabbarButton = MMTabBarButton(type: .custom)
            tabbarButton.frame = CGRect(x: CGFloat(index) * itemWidth, y: 0, width: itemWidth, height: 49)
            tabbarButton.setImage(UIImage(named: info.tabbarImageName), for: .normal)
            tabbarButton.setImage(UIImage(named: info.tabbarSelectedImageName), for: .selected)
            tabbarButton.setTitle(info.tabbarName, for: .normal)
            tabbarButton.setTitle(info.tabbarName, for: .selected)
            tabbarButton.tag = index
            if index == 0 {
                tabbarButton.isSelected = true
                previousSelectedIndex = tabbarButton.tag
            }
            tabbarButton.addTarget(self, action: #selector(self.tabbarButtonClick), for: UIControlEvents.touchUpInside)
            addSubview(tabbarButton)
            buttonItems.append(tabbarButton)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MMTabBarButton: UIButton {
    
    public var badgeText: String? {
        didSet {
            if let text = badgeText {
                badgeLabel.text = text
                var textWidth = text.getTextWidth(height: 12, font: UIFont.regularFontWithSize(size: 8))
                textWidth = textWidth == 0 ? 0 : textWidth + 6
                badgeLabel.frame = CGRect(x:imageView?.frame.maxX ?? 0 , y: 5, width: textWidth >= 12 ? textWidth : 12 , height: 12)
            } else {
                badgeLabel.frame = CGRect.zero
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitleColor(UIColor.lightGray, for: .normal)
        setTitleColor(UIColor.black, for: .selected)
        titleLabel?.textAlignment = .center
        titleLabel?.font = UIFont.regularFontWithSize(size: 12)
        addSubview(badgeLabel)
    }
    
    override func setImage(_ image: UIImage?, for state: UIControlState) {
        super.setImage(image, for: state)
        setNeedsLayout()
    }
    
    override func setTitle(_ title: String?, for state: UIControlState) {
        super.setTitle(title, for: state)
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize = imageView?.size
        let titleSize = titleLabel?.size
        imageView?.frame = CGRect(x: (width - (imageSize?.width ?? 0))/2.0, y: 6, width: imageSize?.width ?? 0, height: imageSize?.height ?? 0)
        titleLabel?.frame = CGRect(x: 0, y: ((imageSize?.height ?? 0) + 10) , width: width, height: (titleSize?.height)!)
    }
    
    private lazy var badgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.regularFontWithSize(size: 8)
        l.textAlignment = .center
        l.textColor = UIColor.white
        l.backgroundColor = UIColor.primary1()
        l.round(6)
        return l
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


