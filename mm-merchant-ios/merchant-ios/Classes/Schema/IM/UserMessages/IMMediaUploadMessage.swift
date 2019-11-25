//
//  IMMediaUploadMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 12/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMMediaUploadMessage: IMUserMessage {
    
    var localStoreName: String?
    
    override init() {
        super.init()
        self.readyToSend = false
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["LocalStoreName"] = localStoreName
        
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        localStoreName  <-  map["LocalStoreName"]
    }
    
    func uploadMedia(_ fileURL: URL, completion: ((_ uuid: String) -> Void)? = nil, failure: (() -> Void)? = nil) {
        MediaService.save(
            fileURL,
            dataType: dataType,
            success: { (response) in
                if response.result.isSuccess {
                    if let uploadResponse = Mapper<MediaSaveResponse>().map(JSONObject: response.result.value), let uuid = uploadResponse.file {
                        completion?(uuid)
                    } else {
                        failure?()
                    }
                } else {
                    failure?()
                }
            },
            fail: { (error) in
                failure?()
            }
        )
    }
    
    override func prepare(completion: ((_ message: IMMessage) -> Void)? = nil, failure: (() -> Void)? = nil) {
        if let url = mediaFileURL() {
            uploadMedia(
                url,
                completion: {(uuid) in
                    self.data = uuid
                    completion?(self)
                },
                failure: failure
            )
        } else {
            failure?()
        }
    }
    
    func mediaFileURL() -> URL? {
        return nil
    }
    
}
