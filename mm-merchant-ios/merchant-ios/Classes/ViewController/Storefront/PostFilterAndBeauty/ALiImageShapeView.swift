//
//  ALiImageShapeView.swift
//  ImageDemo
//
//  Created by Leslie Zhang on 2017/10/17.
//  Copyright © 2017年 Leslie Zhang. All rights reserved.
//

import UIKit

class ALiImageShapeView: UIView {

    var shapePath:UIBezierPath?
   
    var shapePaths:NSArray?
    
    var coverColor:UIColor?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context!.clear(rect)
        
        let clipPath:UIBezierPath = UIBezierPath.init(rect: self.bounds)
                if let shapePath = shapePath  {
                    clipPath.append(shapePath)
                    if let shapePaths = shapePaths {
                        for path in shapePaths {
                            clipPath.append(path as! UIBezierPath)
                        }
                    }
                    clipPath.usesEvenOddFillRule = true;
                    clipPath.addClip()
        
                    if let coverColor = coverColor{
                        coverColor.setFill()
                    }else{
                        context!.setAlpha(0.7)
                        UIColor.black.setFill()
                    }
        
                    clipPath.fill()
                }

    }

}
