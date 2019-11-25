//
//  Sharable.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 14/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
protocol Sharable {
    func getMessageContentType() -> MessageContentType
    func getMessageDataType() -> MessageDataType
    func getShareKey() -> String
}