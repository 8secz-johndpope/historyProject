//
//  VideoFileManager.swift
//  storefront-ios
//
//  Created by Kam on 23/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation

private let kVideoCacheFilesFolder = "VideoFiles"


class VideoFilesManager {
    
    fileprivate let ioQueue: DispatchQueue
    
    class var shared : VideoFilesManager {
        struct Static {
            static let instance : VideoFilesManager = VideoFilesManager()
        }
        return Static.instance
    }
    
    private var videoFilesFolder: URL {
        get { return self.createVideoFolder(kVideoCacheFilesFolder)}
    }
    
    init() {
        let ioQueueName = "com.mm.storefront.VideoFilesManager.ioQueue.default)"
        ioQueue = DispatchQueue(label: ioQueueName, qos: DispatchQoS.background, attributes: .concurrent)
    }
    
    private func createVideoFolder(_ folderName :String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(folderName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: folder.absoluteString) {
            do {
                try fileManager.createDirectory(atPath: folder.path, withIntermediateDirectories: true, attributes: nil)
                return folder
            } catch let error as NSError {
                log.error("error:\(error)")
            }
        }
        return folder
    }
    
    open func storeVideo(_ fileName: String, videoData: Data?) {
        ioQueue.async {
            if let data = videoData {
                let path = self.cachedVideoFileURL(fileName).path
                if !self.cachedVideoIsExist(fileName) {
                    FileManager.default.createFile(atPath: path, contents: data, attributes: nil)
                }
            }
        }
    }
    
    open func cachedVideoIsExist(_ fileName: String) -> Bool {
        let path = self.cachedVideoFileURL(fileName).path
        return FileManager.default.fileExists(atPath: path)
    }
    
    open func cachedVideoFileURL(_ fileName: String) -> URL {
        let url = URL(string: fileName)
        let fileName = "\(fileName.md5()).\(url?.pathExtension ?? "")"
        return self.videoFilesFolder.appendingPathComponent(fileName)
    }
    
    open func cachedVideoData(_ fileName: String) -> Data? {
        let path = self.cachedVideoFileURL(fileName).path
        if FileManager.default.fileExists(atPath: path) {
            return FileManager.default.contents(atPath: path)
        }
        return nil
    }
    
    open func removeAllVideoCache() {
        self.deleteFilesWithPath(self.videoFilesFolder.path)
    }
    
    private func deleteFilesWithPath(_ path: String) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)

            for i in 0 ..< files.count {
                let path = path + "/" + files[i]
                log.info("removing \(path)")
                do {
                    try fileManager.removeItem(atPath: path)
                } catch let error as NSError {
                    log.info("could not remove \(path)")
                    log.info(error.localizedDescription)
                }
            }
        } catch let error as NSError {
            log.info("could not get contents of directory at \(path)")
            log.info(error.localizedDescription)
        }
    }
    
}
