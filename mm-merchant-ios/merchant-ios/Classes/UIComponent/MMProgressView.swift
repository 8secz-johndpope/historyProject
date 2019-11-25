//
//  MMProgressView.swift
//  merchant-ios
//
//  Created by Alan YU on 28/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class MMProgressView: UIView  {

    @IBInspectable var progress: Float = 0.0 {
        didSet {
            if progress > 1.0 {
                progress = 1.0
            } else if progress < 0 {
                progress = 0
            }
            updateProgressView(progress)
        }
    }
    
    @IBInspectable var trackTintColor: UIColor? {
        didSet {
            backgroundColor = trackTintColor
        }
    }
    
    @IBInspectable var progressTintColor: UIColor? {
        didSet {
            progressView.backgroundColor = progressTintColor
        }
    }
    
    private var progressView = UIView()
    
    func commonInit() {
        addSubview(progressView)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgressView(progress)
    }
    
    func updateProgressView(_ progress: Float) {
        progressView.frame = CGRect(x: 0, y: 0, width: frame.width * CGFloat(progress), height: frame.height)
    }
    
}
