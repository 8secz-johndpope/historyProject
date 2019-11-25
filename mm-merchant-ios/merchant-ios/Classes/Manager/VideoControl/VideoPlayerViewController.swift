//
//  VideoPlayerViewController.swift
//  storefront-ios
//
//  Created by Kam on 2/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import AVKit

class VideoPlayerViewController: AVPlayerViewController {

    var isLandscapeVideo: Bool {
        get {
            return self.videoBounds.width > self.videoBounds.height
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        if !VideoPlayManager.shared.isFullScreen && UIDevice.current.orientation != .portrait {
            self.portrait()
        }
    }
    
    open func landscape() {
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    open func portrait() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
}
