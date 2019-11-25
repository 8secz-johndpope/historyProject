//
//  AudioPlayerManager.swift
//  TSWeChat
//
//  Created by Hilen on 12/22/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire

let AudioPlayInstance = AudioPlayManager.sharedInstance

class AudioPlayManager: NSObject {
    private var audioPlayer: AVAudioPlayer?
    private var updater: CADisplayLink?
    weak var delegate: PlayAudioDelegate?
    
    class var sharedInstance : AudioPlayManager {
        struct Static {
            static let instance : AudioPlayManager = AudioPlayManager()
        }
        return Static.instance
    }
    
    private override init() {
        super.init()
        //监听听筒和扬声器
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, name: NSNotification.Name.UIDeviceProximityStateDidChange.rawValue, object: UIDevice.current, handler: {
            observer, notification in
            if UIDevice.current.proximityState {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                } catch _ {}
            } else {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                } catch _ {}
            }
        })
    }
    
    func startPlaying(_ audioModel: ChatAudioModel) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {}
        
        if audioModel.dataBody != nil { /* play with data, rely on websocket */
            self.playSoundWithData(audioModel.dataBody! as Data)
            return
        }
        
        guard let keyHash = audioModel.keyHash else {
            self.delegate?.audioPlayFailed()
            return
        }
        //已有 wav 文件，直接播放
        let wavFilePath = AudioFilesManager.wavPathWithName(keyHash)
        if FileManager.default.fileExists(atPath: wavFilePath.path) {
            self.playSoundWithPath(wavFilePath.path)
            return
        }
        
        //已有 amr 文件，转换，再进行播放
        let amrFilePath = AudioFilesManager.amrPathWithName(keyHash)
        if FileManager.default.fileExists(atPath: amrFilePath.path) {
            self.convertAmrToWavAndPlaySound(audioModel)
            return
        }
        
        //都没有，就进行下载
        self.downloadAudio(audioModel)
    }
    
    func getDurationFromPlayer(_ audioData: Data) -> Float {
        let audioPlayer = try! AVAudioPlayer(data: audioData, fileTypeHint: AVFileType.wav.rawValue)
        var duration: Float = 0.0
        duration = Float(audioPlayer.duration)
        return duration
    }
    
    private func resetUpdater() {
        
        let updater = CADisplayLink(target: self, selector: #selector(AudioPlayManager.trackAudio))
        updater.frameInterval = 1
        updater.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)

        self.updater?.invalidate()
        self.updater = updater
    }
    
    @objc func trackAudio(_ updater: CADisplayLink) {
        if let player = self.audioPlayer {
            delegate?.audioProgressDidUpdate(Float(player.currentTime / player.duration))
        }
    }
    
    // AVAudioPlayer 只能播放 wav 格式，不能播放 amr
    private func playSoundWithData(_ data: Data) {
        let fileData = data
        do {
            self.audioPlayer = try AVAudioPlayer(data: fileData)
            
            self.resetUpdater()
            
            guard let player = self.audioPlayer else {
                return
            }
            
            player.delegate = self
            player.prepareToPlay()
            
            guard let delegate = self.delegate else {
                log.error("delegate is nil")
                return
            }
            
            if player.play() {
                UIDevice.current.isProximityMonitoringEnabled = true
                delegate.audioPlayStart()
            } else {
                delegate.audioPlayFailed()
            }
            
            self.resetUpdater()
            
        } catch {
            self.destroyPlayer()
        }
    }
    
    // AVAudioPlayer 只能播放 wav 格式，不能播放 amr
    private func playSoundWithPath(_ path: String) {
        let fileData = try? Data(contentsOf: URL(fileURLWithPath: path))
        do {
            self.audioPlayer = try AVAudioPlayer(data: fileData!)
            
            guard let player = self.audioPlayer else {
                return
            }
            
            player.delegate = self
            player.prepareToPlay()
            
            guard let delegate = self.delegate else {
                log.error("delegate is nil")
                return
            }
            
            if player.play() {
                UIDevice.current.isProximityMonitoringEnabled = true
                delegate.audioPlayStart()
            } else {
                delegate.audioPlayFailed()
            }
            
            self.resetUpdater()
            
        } catch {
            self.destroyPlayer()
        }
    }
    
    func destroyPlayer() {
        self.stopPlayer()
    }
    
    func stopPlayer() {
        if self.audioPlayer == nil {
            return
        }
        self.audioPlayer!.delegate = nil
        self.audioPlayer!.stop()
        self.audioPlayer = nil
        
        self.updater?.invalidate()
        self.updater = nil
        
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    // 转换，并且播放声音
    private func convertAmrToWavAndPlaySound(_ audioModel: ChatAudioModel) {
        if self.audioPlayer != nil {
            self.stopPlayer()
        }
        
        guard let fileName = audioModel.keyHash, fileName.length > 0 else {
            return
        }

        let amrPathString = AudioFilesManager.amrPathWithName(fileName).path
        let wavPathString = AudioFilesManager.wavPathWithName(fileName).path
        
        if FileManager.default.fileExists(atPath: wavPathString) {
            self.playSoundWithPath(wavPathString)
        } else {
            if TSVoiceConverter.convertAmrToWav(amrPathString, wavSavePath: wavPathString) {
                self.playSoundWithPath(wavPathString)
            } else {
                if let delegate = self.delegate {
                    delegate.audioPlayFailed()
                }
            }
        }
    }
    
    /**
     使用 Alamofire 下载并且存储文件
     */
    private func downloadAudio(_ audioModel: ChatAudioModel) {
        let fileName = audioModel.keyHash!
        let filePath = AudioFilesManager.wavPathWithName(fileName)
        
        let destination : DownloadRequest.DownloadFileDestination = { temporaryURL, response  in
            log.info("checkAndDownloadAudio response:\(response)")
            if response.statusCode == 200 {
                if FileManager.default.fileExists(atPath: filePath.path) {
                    try! FileManager.default.removeItem(at: filePath)
                }
                log.info("filePath:\(filePath)")
                return (filePath, [])
            } else {
                return (temporaryURL, [])
            }
        }
        
        Alamofire.download(audioModel.audioURL!, to: destination).response { response in
            if let wavFilePath = response.destinationURL?.path {
                if FileManager.default.fileExists(atPath: wavFilePath) {
                    self.playSoundWithPath(wavFilePath)
                }
            }
        }
    }
}

// MARK: - @protocol AVAudioPlayerDelegate
extension AudioPlayManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        log.info("Finished playing the song")
        UIDevice.current.isProximityMonitoringEnabled = false
        if flag {
            self.delegate?.audioPlayFinished()
        } else {
            self.delegate?.audioPlayFailed()
        }
        self.stopPlayer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.stopPlayer()
        self.delegate?.audioPlayFailed()
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.stopPlayer()
        self.delegate?.audioPlayFailed()
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        
    }
}











