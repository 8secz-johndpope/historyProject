//
//  FilterRangeSlider.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 4/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Foundation
import NMRangeSlider
class FilterRangeSlider: NMRangeSlider {
    private let RangeItemHeight : CGFloat = 2
    var numberOfSegments : Int = 4  //you can change number of segments
    var startShapeLayer : CAShapeLayer?
    var endShapeLayer : CAShapeLayer?
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        for i in 0 ..< numberOfSegments + 1 {
            self.addRangeAtIndex(i, rect: rect)
        }
        self.startShapeLayer?.isHidden = true
        self.endShapeLayer?.isHidden = true
    }
    
    func addRangeAtIndex(_ index : Int , rect: CGRect) {
        
        let shapeLayer = CAShapeLayer()
        if (index == 0) {
            startShapeLayer = shapeLayer
        } else if index == numberOfSegments {
            endShapeLayer = shapeLayer
        }
        let width = rect.width - self.upperHandleImageNormal.size.width
        let circlePath = UIBezierPath(arcCenter: CGPoint(x:self.upperHandleImageNormal.size.width / 2 + (CGFloat(index) * width / CGFloat(numberOfSegments)),y: rect.height  / 2), radius: RangeItemHeight, startAngle: CGFloat(0), endAngle:CGFloat.pi * 2, clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
        //change the fill color
        shapeLayer.fillColor = UIColor.black.cgColor
        //you can change the stroke color
        shapeLayer.strokeColor = UIColor.black.cgColor
        //you can change the line width
        shapeLayer.lineWidth = 0.5
        self.layer.addSublayer(shapeLayer)
    }
    
    func refresh() {
        let offset = Float(self.upperHandleImageNormal.size.width / 2)
        if (self.lowerValue - offset) > self.minimumValue {
            if let startShapeLayer = startShapeLayer{
                startShapeLayer.isHidden = false
            }
        }
        if (self.upperValue + offset) < self.maximumValue {
            if let endShapeLayer = endShapeLayer {
                endShapeLayer.isHidden = false
            }
        }
    }

}
