//
//  CMSPageGridBannerVideoCell.swift
//  storefront-ios
//
//  Created by Kam on 30/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageGridBannerVideoCell: BannerVideoCell {
    
    open var deeplink: String? {
        didSet {
            guard let link = deeplink else {
                return
            }
            overlayVideoView.isHidden = link.isEmpty
            if !link.isEmpty {
                overlayVideoView.whenTapped {
                    Navigator.shared.dopen(link)
                }
            }
        }
    }
    
    open var coverImage: String? {
        didSet {
            self.setImageURL(coverImage ?? "")
        }
    }
    
    open var videoUrl: String? {
        didSet {
            self.setVideoURL(videoUrl ?? "")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.hidePlayerComponent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func hidePlayerComponent() {
//        self.soundButton.isHidden = true
//        self.fullScreenButton.isHidden = true
        self.moreImageView.isHidden = true
    }
    
    override func setStatusForVideoView(isPlaying: Bool) {
        super.setStatusForVideoView(isPlaying: isPlaying)
        self.hidePlayerComponent()
    }
}
