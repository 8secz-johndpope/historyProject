//
//  FrameManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 6/1/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
enum FrameIndex: Int {
    case frame1 = 0,
    frame2a,
    frame2b,
    frame3,
    frame4a,
    frame4b,
    frame5
}
class FrameManager{
    static func setupFrameArray() -> [[CGRect]]{
        var frameArray = [[CGRect]]()
        let screenWidth = UIScreen.main.bounds.size.width
        // frame 1
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth, height: screenWidth)])
        
        // frame 2
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth, height: screenWidth / 2),
            CGRect(x: 0, y: screenWidth / 2, width: screenWidth, height: screenWidth / 2)])
        
        // frame 3
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth / 2, height: screenWidth),
            CGRect(x: screenWidth / 2, y: ScreenTop, width: screenWidth / 2, height: screenWidth)])
        
        // frame 4
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth * 0.60, height: screenWidth),
            CGRect(x: screenWidth * 0.60, y: ScreenTop, width: screenWidth * 0.40, height: screenWidth * 0.40),
            CGRect(x: screenWidth * 0.60, y: screenWidth * 0.40, width: screenWidth * 0.40, height: screenWidth * 0.60)])
        
        // frame 5
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth, height: screenWidth * 0.60),
            CGRect(x: 0, y: screenWidth * 0.60, width: screenWidth / 3, height: screenWidth * 0.40),
            CGRect(x: screenWidth / 3, y: screenWidth * 0.60, width: screenWidth / 3, height: screenWidth * 0.40),
            CGRect(x: (screenWidth / 3) * 2, y: screenWidth * 0.60, width: screenWidth / 3, height: screenWidth * 0.40)])
        
        // frame 6
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth / 2, height: screenWidth / 2),
            CGRect(x: screenWidth / 2, y: ScreenTop, width: screenWidth / 2, height: screenWidth / 2),
            CGRect(x: 0, y: screenWidth / 2, width: screenWidth / 2, height: screenWidth / 2),
            CGRect(x: screenWidth / 2, y: screenWidth / 2, width: screenWidth / 2, height: screenWidth / 2)])
        
        
        // frame 7
        frameArray.append([CGRect(x: 0, y: ScreenTop, width: screenWidth, height: screenWidth),
            CGRect(x: screenWidth * 0.03, y: screenWidth * 0.20, width: screenWidth * 0.30, height: screenWidth * 0.30),
            CGRect(x: screenWidth * 0.08, y: screenWidth * 0.55, width: screenWidth * 0.35, height: screenWidth * 0.35),
            CGRect(x: screenWidth * 0.65, y: screenWidth * 0.10, width: screenWidth * 0.30, height: screenWidth * 0.30),
            CGRect(x: screenWidth * 0.55, y: screenWidth * 0.45, width: screenWidth * 0.40, height: screenWidth * 0.40)])
        
        return frameArray
    }
    
    static func getNumberSubFrameFromFrameIndex(_ frameIndex: Int) -> Int{
        switch frameIndex {
        case FrameIndex.frame1.rawValue:
            return 1
        case FrameIndex.frame2a.rawValue,FrameIndex.frame2b.rawValue:
            return 2
        case FrameIndex.frame3.rawValue:
            return 3
        case FrameIndex.frame4a.rawValue,FrameIndex.frame4b.rawValue:
            return 4
        case FrameIndex.frame5.rawValue:
            return 5
        default:
            return 0
        }
    }

    
}
