//
//  IncorrectView.swift
//  merchant-ios
//
//  Created by Sang on 2/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

@objc
protocol IncorrectViewDelegate: NSObjectProtocol { //Prevent memory leak
    @objc optional func incorrectViewShow(_ isShow: Bool)
}

class IncorrectView: UIView {
    var backgroundView = UIView()
    var messageLabel = UILabel()
    var displayTime : Double = 3 //Default value is 3 seconds, this value can be set outside this class
    var isAnimated = false
    
    weak var delegate: IncorrectViewDelegate? //Prevent memory leak
	
	var timer: Timer!
    
    var tapGesture: UITapGestureRecognizer?
    
    override var frame: CGRect {
        didSet {
            backgroundView.frame = CGRect(x: 0, y: -self.bounds.height, width: self.bounds.width, height: self.bounds.height)
            messageLabel.frame = CGRect(x: 5, y: ((IsIphoneX && self.origin.y == 0) ? 20 : 5), width: self.bounds.width - 10, height: self.bounds.height - 10)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        
        backgroundView.backgroundColor = UIColor.primary1()

        messageLabel.formatSize(14)
        messageLabel.textColor = UIColor.white
        messageLabel.textAlignment = .center
        
        backgroundView.addSubview(messageLabel)
        
        self.addSubview(backgroundView)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(IncorrectView.hideMessage))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func showMessage(_ message: String, animated: Bool) {
		
		if timer != nil {
			timer.invalidate()
		}
		
        self.isHidden = false
        isAnimated = animated
        messageLabel.text = message
        var frame = backgroundView.frame
        frame.origin.y = 0
        if isAnimated {
            UIView.animate(
                withDuration: 0.2,
                animations: { () -> Void in
                    self.backgroundView.frame = frame
                    guard let delegate = self.delegate, let incorrectViewShow = delegate.incorrectViewShow else {
                        return
                    }
                    incorrectViewShow(true)
                },
                completion: { (success) in }
            )
        }
        else {
            backgroundView.frame = frame
        }
        timer = Timer.scheduledTimer(timeInterval: displayTime, target: self, selector: #selector(IncorrectView.hideMessage), userInfo: nil, repeats: false)
        
        if let strongTapGesture = tapGesture {
            self.addGestureRecognizer(strongTapGesture)
        }
    }
    
    @objc func hideMessage() {
        var frame = backgroundView.frame
        frame.origin.y = -self.bounds.height
        if isAnimated {
            UIView.animate(
                withDuration: 0.2,
                animations: { () -> Void in
                    self.backgroundView.frame = frame
                    guard let delegate = self.delegate, let incorrectViewShow = delegate.incorrectViewShow else {
                        return
                    }
                    incorrectViewShow(false)
                },
                completion: { (success) in
                    self.isHidden = true
                }
            )
        }
        else {
            backgroundView.frame = frame
        }
        
        if let strongtTapGesture = tapGesture {
            self.removeGestureRecognizer(strongtTapGesture)
        }
    }
}
