//
//  Message.swift
//  merchant-ios
//
//  Created by Tony Fung on 21/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//
// Depercated: now we use the ChatModel


import Foundation
import ObjectMapper
class Message : Mappable{
    var convKey = ""
    var type = ""
    var dataType = ""
    var data = ""
    var userKey = ""
    var msgKey = ""
    var timestamp = Date()
    var userList = [String]()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        type        <-  map["Type"]
        msgKey      <-  map["MsgKey"]
        dataType    <-  map["DataType"]
        data        <-  map["Data"]
        userKey     <-  map["UserKey"]
        convKey     <-  map["ConvKey"]
        timestamp   <-  (map["Timestamp"], ISO8601DateTransform())
        userList    <-  map["UserList"]
    }
}
