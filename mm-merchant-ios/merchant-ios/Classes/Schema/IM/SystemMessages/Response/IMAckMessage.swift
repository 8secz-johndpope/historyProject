//
//  IMAckMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMAckMessage: IMSystemMessage {
    
    var data: String?
    var dataType = MessageDataType.Unknown
    var associatedObject: Any?
    
    convenience init(associatedObject: Any) {
        self.init()
        self.associatedObject = associatedObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        data        <-  map["Data"]
        dataType    <-  (map["DataType"], EnumTransform())
    }
    
    func isError() -> Bool {
        return type == .Error
    }
    
}
