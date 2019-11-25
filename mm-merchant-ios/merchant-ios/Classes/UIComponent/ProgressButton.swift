//
//  ProgressButton.swift
//  merchant-ios
//
//  Created by Tony Fung on 18/7/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

class ProgressButton: UIButton {
    
    var progress : Float = 0
    var loadingLayer : CALayer
    
    
    init() {
        
        let loadLayer = CALayer()
        loadLayer.backgroundColor = UIColor.primary1().cgColor
        

        loadingLayer = loadLayer
        super.init(frame: CGRect.zero)
        
        self.layer.addSublayer(loadLayer)
        loadingLayer.frame = CGRect(x: 0, y: 0, width: 0, height: self.frame.height)
        self.layer.backgroundColor = UIColor.black.withAlphaComponent(0.3).cgColor
        self.titleLabel?.textColor = UIColor.white
        self.setTitle(String.localize("LB_CA_FOLLOW_CURATORS_CONT"), for: UIControlState())
        self.isEnabled = false
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {

        super.layoutSubviews()
    }
    
    func updateProgress(_ _progress: Float){
        self.progress = _progress > 1 ? 1 : _progress
        if self.progress >= 1 {
            self.isEnabled = true
        }
        Log.debug("width: \(self.frame.width)")
        
        UIView.animate(withDuration: 0.3, animations: { 
            self.loadingLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(_progress) * self.frame.width, height: self.frame.height)
        }) 
    }
    
    
    
}
