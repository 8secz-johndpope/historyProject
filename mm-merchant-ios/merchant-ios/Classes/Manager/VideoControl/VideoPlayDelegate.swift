//
//  VideoPlayDelegate.swift
//  storefront-ios
//
//  Created by Kam on 18/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.

import Foundation

protocol PlayVideoDelegate: class {
    func setVideoPlayerIsFocus()
    func setVideoPlayerIsUnfocus()
    func isFocusing() -> Bool
    func isPlayerOutOfScreen(ratio: CGFloat) -> Bool
    
    func videoPlayerAutoStart() -> Bool
    func videoPlayerFinished()
    func videoPlayerInterruption() //other video player interrupted
}



