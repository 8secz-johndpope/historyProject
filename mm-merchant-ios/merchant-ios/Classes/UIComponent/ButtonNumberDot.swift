//
//  ButtonNumberDot.swift
//  storefront-ios
//
//  Created by Demon on 13/6/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ButtonNumberDot: UIButton {
    
    private var likeNumber: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override var frame: CGRect {
        didSet {
            addSubview(badgeLabel)
        }
    }
    
    func setLikeBadgeNumber(_ count: Int) {
        badgeLabel.isHidden = false
        if count <= 0 {
            badgeLabel.isHidden = true
        }
        likeNumber = count
        badgeLabel.x = frame.width - 18
        if count > 99 {
            badgeLabel.width = 30
        } else if count > 9 {
            badgeLabel.width = 25
        }
        var number = String(count)
        if count > 999 {
            number = "999+"
            badgeLabel.width = 36
        }
        badgeLabel.text = number
        
        badgeLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.5, animations: {
            self.badgeLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }) { (completion) in
        }
    }
    
//    func addOrDeleteLike(_ isAdd: Bool) {
//        if isAdd {
//            addAnimationAction()
//        } else {
//            deleteAnimationAction()
//        }
//    }
    
//    private func addAnimationAction() {
//        likeNumber += 1
////        badgeLabel.text = "+1"
//        badgeLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
//        UIView.animate(withDuration: 0.5, animations: {
//            self.badgeLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
//        }) { (completion) in
//            self.setLikeBadgeNumber(self.likeNumber)
//        }
//    }
    
//    private func deleteAnimationAction() {
//        likeNumber -= 1
////        badgeLabel.text = "-1"
//        badgeLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
//        UIView.animate(withDuration: 0.5, animations: {
//            self.badgeLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
//        }) { (completion) in
//            self.setLikeBadgeNumber(self.likeNumber)
//        }
//    }
    
    private lazy var badgeLabel: UILabel = {
        let lb = UILabel(frame: CGRect(x: frame.width - 18, y: 7, width: 15, height: 15))
        lb.round(lb.height/2.0)
        lb.viewBorder(UIColor.primary1(), width: 0.5)
        lb.textColor = UIColor.primary1()
        lb.backgroundColor = UIColor.white
        lb.textAlignment = .center
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.isHidden = true
        return lb
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

