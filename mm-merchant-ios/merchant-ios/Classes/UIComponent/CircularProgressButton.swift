//
//  CircularProgressButton.swift
//  merchant-ios
//
//  Created by Tony Fung on 4/8/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

public enum CircularProgressButtonState : Int {
    case normal
    case loading
    
}


class CircularProgressButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(self.didClickedAction), for: UIControlEvents.touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var currentState = CircularProgressButtonState.normal
    private var normalWidth : CGFloat = 0
    private var normalText : String = ""
    
    @objc func didClickedAction() {
        
        self.transformToState(.loading)
    }
    
    
    private var transitions : [(()-> Void)] = []
    
    func transformToState(_ state: CircularProgressButtonState){
        
        guard currentState != state else {
            return
        }

        let blockObject = {
            
            self.currentState = state
            
            let currentHeight = self.frame.height
            let center = self.center
            
            switch state {
            case .normal:
                self.removeLoadingCircle()
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.frame.size = CGSize(width: self.normalWidth, height: currentHeight)
                    self.center = center

                 
                }, completion: { (completed) in
                    self.formatPrimary()
                    self.setTitle(self.normalText, for: UIControlState())
                    self.titleLabel?.isHidden = false


                    if self.transitions.count > 0 {
                        self.transitions.removeFirst(1)
                        if let blockCode = self.transitions.first {
                            blockCode()
                        }
                    }
                }) 
                
                break
                
            case .loading:
                
                self.normalWidth = self.frame.width
                self.normalText = self.titleLabel?.text ?? ""
                self.setTitle("", for: UIControlState())
                
                UIView.animate(withDuration: 0.2, animations: {
                    
                    self.layer.cornerRadius = self.frame.height / 2
                    self.frame.size = CGSize(width: currentHeight, height: currentHeight)
                    self.center = center

                    
                }, completion: { (completed) in
                    self.displayLoadingCircle()
                    
                    if self.transitions.count > 0 {
                        self.transitions.removeFirst(1)
                        if let blockCode = self.transitions.first {
                            blockCode()
                        }
                    }
                }) 
                
                break
                
            }
        }
        
        transitions.append(blockObject)
        
        if transitions.count == 1, let blockCode = transitions.first {
            blockCode()
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleLayer?.frame = self.bounds
        
    }
    
    var circleLayer : CAShapeLayer?
    
    func removeLoadingCircle(){
        
        Log.debug("removeLoadingCircle")
        self.circleLayer?.removeAllAnimations()
        self.circleLayer?.isHidden = true

    }
    
    func displayLoadingCircle(){
        
        Log.debug("displayLoadingCircle")
        self.layer.cornerRadius = self.frame.height / 2
        
        if self.circleLayer == nil {
            self.circleLayer = CAShapeLayer()
            
            let buttonCenter = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
            
            let path = UIBezierPath()
            
            path.addArc(withCenter: buttonCenter, radius: (self.frame.width - 8) / 2, startAngle: 0, endAngle: CGFloat.pi * 0.6, clockwise: true)
            path.lineWidth = 4
            self.circleLayer!.strokeColor = UIColor.white.cgColor
            self.circleLayer!.path = path.cgPath
            self.circleLayer!.fillRule = kCAFillRuleNonZero
            self.circleLayer!.isOpaque = true
            self.circleLayer!.opacity = 1
            self.circleLayer!.lineCap = kCALineCapRound
            
            self.circleLayer!.lineWidth = path.lineWidth
            self.circleLayer!.fillColor = UIColor.clear.cgColor
            self.circleLayer!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.circleLayer!.backgroundColor = UIColor.clear.cgColor
            self.layer.insertSublayer(self.circleLayer!, above: self.layer)
            
        }
        
        self.circleLayer?.isHidden = false
        self.circleLayer?.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1
        animation.isRemovedOnCompletion = false
        animation.repeatCount = .greatestFiniteMagnitude
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        
        self.circleLayer!.add(animation, forKey: nil)

    
        
    }
    
    
}
