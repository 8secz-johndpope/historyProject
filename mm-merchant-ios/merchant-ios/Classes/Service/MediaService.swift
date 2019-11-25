
//  MediaService.swift
//  merchant-ios
//
//  Created by Alan YU on 17/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

enum MediaServiceError: Int {
    case incorrectDataType = -1
}

class MediaService {
    
    static let MEDIA_PARH = Constants.Path.Host + "/media"
    
    class func save (
        _ fileURL: URL,
        dataType: MessageDataType,
        progress: ((Progress) -> Void)? = nil,
        success : @escaping (DataResponse<Any>) -> Void,
        fail : @escaping (Error) -> Void
        ) {
        
        var fileType: String?
        var fileSettings: (URL: URL, name: String, fileName: String, mimeType: String)?
        
        if dataType == .ImageUUID || dataType == .ForwardImage {
            fileType = "image"
            fileSettings = (URL: fileURL, name: "file", fileName: "image", mimeType: "image/jpeg")
        } else if dataType == .AudioUUID {
            fileType = "audio"
            fileSettings = (URL: fileURL, name: "file", fileName: "audio", mimeType: "audio/wav")
        }
        
        guard let type = fileType, let settings = fileSettings else {
            fail(NSError(domain: "MediaService", code: MediaServiceError.incorrectDataType.rawValue, userInfo: nil))
            return
        }
        
        save(
            fileURL,
            file: settings,
            type: type,
            progress: progress,
            success: success,
            fail: fail
        )
    }
    
    private class func save (
        _ fileURL: URL,
        file: (URL: URL, name: String, fileName: String, mimeType: String),
        type: String,
        progress: ((Progress) -> Void)? = nil,
        success : @escaping (DataResponse<Any>) -> Void,
        fail : @escaping (Error) -> Void
        ) {
        RequestFactory.upload(
            MEDIA_PARH + "/save",
            file: file,
            parameters: ["Type": type, "UserKey": Context.getUserKey()],
            progress: progress,
            success: success,
            fail: fail
        )
    }
    
    class func viewImage (_ guid: String) -> String? {
        return view(
            guid,
            type: "image"
        )
    }
    
    class func viewAudio (_ guid: String) -> String? {
        return view(
            guid,
            type: "audio"
        )
    }
    
    private class func view (_ guid: String, type:String) -> String? {
        
        let url = MEDIA_PARH + "/view"
        
        let parameters = ["guid": guid, "type": type]
        
        var queryString = [String]()
        for (key, value) in parameters {
            queryString.append(key + "=" + value)
        }
        
        return url + "?" + queryString.joined(separator: "&")
    }
    
}
