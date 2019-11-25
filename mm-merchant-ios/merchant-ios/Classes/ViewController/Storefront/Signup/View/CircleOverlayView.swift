//
//  CircleOverlayView.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 2/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//
import Foundation
class CircleOverlayView: UIView {
    let circleLayer = CAShapeLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
      //  self.backgroundColor = UIColor.red
        circleLayer.fillColor = UIColor.white.cgColor
        layer.addSublayer(circleLayer)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: width, height: width)).cgPath
        circleLayer.anchorPoint = self.center
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
