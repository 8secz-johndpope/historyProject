//
//  MediaSaveResponse.swift
//  merchant-ios
//
//  Created by Alan YU on 17/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MediaSaveResponse: Mappable {
    
    var type: String?
    var file: String?
    var mimeType: String?
    var fileExtension: String?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        type            <-  map["Type"]
        file            <-  map["File"]
        mimeType        <-  map["MimeType"]
        fileExtension   <-  map["Extension"]
    }
    
}
