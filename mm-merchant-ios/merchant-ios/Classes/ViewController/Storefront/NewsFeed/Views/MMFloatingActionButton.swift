//
//  MMFloatingActionButton.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import UIKit


@objc protocol MMFloatingActionButtonDelegate: NSObjectProtocol{
    @objc optional func didSelectedActionButton(_ gesture: UITapGestureRecognizer)
}

class MMFloatingActionButton: UIView {
    
    var imageViewAdd = UIImageView()
    var isAnimating = false
    var animationDuration = TimeInterval(0.2)
    
    weak var mmFloatingActionButtonDelegate: MMFloatingActionButtonDelegate? //Prevent memory leak
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageViewAdd.image = UIImage(named: "create_post_btn")
        imageViewAdd.accessibilityIdentifier = "UIBT_CREATE_POST"
        imageViewAdd.isUserInteractionEnabled = true
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MMFloatingActionButton.didSelectedActionButton))
//        imageViewAdd.addGestureRecognizer(tapGesture)
        
        self.addSubview(imageViewAdd)
        self.transform = CGAffineTransform.identity
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageViewAdd.frame = self.bounds
    }
    
    @objc func didSelectedActionButton(_ gesture: UITapGestureRecognizer) -> Void {
        self.mmFloatingActionButtonDelegate?.didSelectedActionButton!(gesture)
    }
    
    func showFloatingButton() {
        DispatchQueue.main.async {[weak self] in
            self?.isHidden = false
        }
    }
    
    func hiddenFloatingButton() {
        DispatchQueue.main.async { [weak self] in
            self?.isHidden = true
        }
    }
    
    func removeFloatingButton() {
        DispatchQueue.main.async { [weak self] in
            self?.removeFromSuperview()
        }
    }
    
    func fadeOut() {
        if !self.isAnimating && self.isHidden == true {
            self.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            self.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
                self.transform = CGAffineTransform.identity
                self.isAnimating = true
            }) { (animationCompleted: Bool) -> Void in
                self.isAnimating = false
                self.isHidden = false
            }
        }
    }
    
    func fadeIn() {
        if !self.isAnimating &&  self.isHidden == false {
            self.transform = CGAffineTransform.identity
            self.isHidden = false
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.curveLinear], animations: { () -> Void in
                self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.isAnimating = true
                
            }) { (animationCompleted: Bool) -> Void in
                self.isAnimating = false
                self.isHidden = true
                self.transform = CGAffineTransform(scaleX: 0, y: 0)
            }
        }
    }
   
   
}

