//
//  VideoPlayManager.swift
//  storefront-ios
//
//  Created by Kam on 18/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import AVKit

class VideoPlayManager: NSObject {
    private let boundsRatio: CGFloat = 0.5
    static let delayInterval = 0.3
    var isFullScreen = false
    
    class var shared : VideoPlayManager {
        struct Static {
            static let instance : VideoPlayManager = VideoPlayManager()
        }
        return Static.instance
    }
    
    weak var delegateShouldResume: PlayVideoDelegate?
    
    private var delegateQueueMap: [String/* temp using PageChannel id in str */: [PlayVideoDelegate]] = [String: [PlayVideoDelegate]]()
    private var delegateQueue: [PlayVideoDelegate] {
        get {
            guard activePageId != "" else { //guard if no active page displaying
                return [PlayVideoDelegate]() //empty array
            }
            
            if let queue = delegateQueueMap[activePageId] {
                return queue
            } else {
                delegateQueueMap[activePageId] = [PlayVideoDelegate]() //create an array if not init yet
                return delegateQueueMap[activePageId]!
            }
        }
        set {
            delegateQueueMap[activePageId] = newValue
        }
    }
    private var activePageId: String = ""
    private var pageIdQueue: [String] = [String]()
    
    private var focusingPlayerDelegate: PlayVideoDelegate? {
        get {
            for delegate in delegateQueue {
                if delegate.isFocusing() {
                    return delegate
                }
            }
            return nil
        }
    }
    
    open func videoPlayInterrupt(trigger delegateTrigger: PlayVideoDelegate? = nil) {
        guard let fDelegate = focusingPlayerDelegate else {
            return
        }
        
        if let trigger = delegateTrigger, trigger === fDelegate {
            return
        }

        fDelegate.videoPlayerInterruption()
    }
    
    open func videoStartFullScreen(_ playerVC: VideoPlayerViewController?, delegate: PlayVideoDelegate) {
        guard let playerVC = playerVC else {
            return
        }
        delegateShouldResume = delegate

        playerVC.player?.isMuted = false
        
        let selectorName : String = {
            if #available(iOS 11.3, *) {
                return "_transitionToFullScreenAnimated:interactive:completionHandler:"
            }
            else if #available(iOS 11, *) {
                return "_transitionToFullScreenAnimated:completionHandler:"
            }
            else {
                return "_transitionToFullScreenViewControllerAnimated:completionHandler:"
            }
        }()
        let selectorToForceFullScreenMode = NSSelectorFromString(selectorName)
        if playerVC.responds(to: selectorToForceFullScreenMode) {
            playerVC.showsPlaybackControls = true
            self.isFullScreen = true
            
            playerVC.perform(selectorToForceFullScreenMode, with: true, with: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + VideoPlayManager.delayInterval) {

                playerVC.videoGravity = AVLayerVideoGravity.resizeAspect.rawValue
                
                if playerVC.isLandscapeVideo {
                    playerVC.landscape()
                }
            }
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch {}
        }
    }
    
    open func focusVideoPlayer(delegate: PlayVideoDelegate?, shouldAutoStart: Bool = true) {
        guard let delegate = delegate else {
            return
        }
        
        if focusingPlayerDelegate == nil { // if no focusing player
            if shouldAutoStart && delegate.videoPlayerAutoStart() {
                delegate.setVideoPlayerIsFocus()
            }
        }
        
        if let index = delegateQueue.index(where: { (_delegate) -> Bool in return _delegate === delegate }) /* is delegate exist */ {
            delegateQueue[index] = delegate
        } else {
            delegateQueue.append(delegate) //append all video delegate which focusing (showing within the screen greater than %)
        }
    }
    
    open func unFocusVideoPlayer(delegate: PlayVideoDelegate?) {
        if let delegate = delegate {
            delegate.setVideoPlayerIsUnfocus()
            if let index = delegateQueue.index(where: { (_delegate) -> Bool in return _delegate === delegate }) {
                delegateQueue.remove(at: index) //remove unfocus delegate
            }
        }
    }
    
    open func isActivePlayerOutOfScreen() {
        var fDelegate: PlayVideoDelegate? /* to be adjust the correct delegate */
        if let delegate = focusingPlayerDelegate {
            fDelegate = delegate
        } else if delegateQueue.count > 0 {
            fDelegate = delegateQueue[0]
        } else { return }
        
        let handleNextVideo = {
            let pendingDelegates = self.delegateQueue.filter { (_delegate) -> Bool in return _delegate !== fDelegate }
            
            for delegate in pendingDelegates {
                if !delegate.isPlayerOutOfScreen(ratio: self.boundsRatio) && delegate.videoPlayerAutoStart() {
                    delegate.setVideoPlayerIsFocus()
                    break
                }
            }
        }
        
        if let fDelegate = fDelegate {
            if fDelegate.isPlayerOutOfScreen(ratio: boundsRatio) {
                if fDelegate.isFocusing() {
                    fDelegate.setVideoPlayerIsUnfocus()
                    
                }
                handleNextVideo()
            } else if !fDelegate.isFocusing() && fDelegate.videoPlayerAutoStart() {
                fDelegate.setVideoPlayerIsFocus()
            }
        }
    }
    
    open func appEnterBackground() {
        self.videoPageWillDisappear(pageId: self.activePageId)
    }
    
    open func appEnterForeground() {
        //do nth
    }
    
    /**
     Below function for CMSPageViewController usage
     **/
    
    open func videoPageWillAppear(pageId: String) {
        self.activePageId = pageId
    }
    
    open func videoPageDidAppear(pageId: String) {
        guard !isFullScreen else {
            return
        }
        
        self.activePageId = pageId
        //handle disappear case before doing appear
        handleDisappeared()
        
        if focusingPlayerDelegate == nil { // if no focusing player
            if let shouldFocusDelegate = delegateShouldResume,
                let index = delegateQueue.index(where: { (_delegate) -> Bool in return _delegate === shouldFocusDelegate }), /* protection guard check, shouldFocusPlayer should belongs to active queue, since new willAppear run before previous page willDisappear */
                shouldFocusDelegate.videoPlayerAutoStart() {
                shouldFocusDelegate.setVideoPlayerIsFocus()
                delegateQueue[index] = shouldFocusDelegate
                
            } else {
                for delegate in delegateQueue {
                    if !delegate.isPlayerOutOfScreen(ratio: boundsRatio) && delegate.videoPlayerAutoStart() {
                        delegate.setVideoPlayerIsFocus()
                        break
                    }
                }
            }
        }
    }
    
    open func videoPageWillDisappear(pageId: String) {
        guard !isFullScreen else {
            return
        }
        
        self.pageIdQueue.append(pageId)
        let tempPId = self.activePageId
        self.activePageId = pageId
        delegateShouldResume = self.focusingPlayerDelegate
        self.focusingPlayerDelegate?.setVideoPlayerIsUnfocus()
        self.activePageId = tempPId
    }
    
    open func videoPageDestroy(pageId: String) {
        self.activePageId = pageId
        
        for delegate in delegateQueue {
            if delegate.isFocusing() {
                delegate.setVideoPlayerIsUnfocus()
            }
        }
        delegateQueue.removeAll()
    }
    
    private func handleDisappeared() {
        let pendingIds = pageIdQueue.filter { (_id) -> Bool in return _id != activePageId }

        for id in pendingIds {
            if let queue = delegateQueueMap[id] {
                for delegate in queue {
                    if delegate.isFocusing() {
                        delegate.setVideoPlayerIsUnfocus()
                    }
                }
            }
        }
        pageIdQueue.removeAll()
    }
    
}
