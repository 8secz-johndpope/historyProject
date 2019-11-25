//
//  SettingsData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 16/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class SettingsData: Equatable {
    
    var title: String?
    var value: String?
    var valueKey: String?
    var imageName: String?
    var isAlertStyle = false
    var hasDisclosureIndicator = false
    var hasBorder = true
    var action: ((_ indexPath: IndexPath?) -> Void)?
    var isEditting = false
    
    init(title: String? = nil, valueKey: String? = nil, imageName: String? = nil, isAlertStyle: Bool = false, hasDisclosureIndicator: Bool = false, hasBorder: Bool = true, action: ((_ indexPath: IndexPath?) -> Void)? = nil) {
        self.title = title
        self.valueKey = valueKey
        self.imageName = imageName
        self.isAlertStyle = isAlertStyle
        self.hasDisclosureIndicator = hasDisclosureIndicator
        self.hasBorder = hasBorder
        self.action = action
    }
}

func ==(lhs: SettingsData, rhs: SettingsData) -> Bool {
    return
        lhs.title == rhs.title &&
        lhs.value == rhs.value &&
        lhs.valueKey == rhs.valueKey &&
        lhs.imageName == rhs.imageName &&
        lhs.isAlertStyle == rhs.isAlertStyle &&
        lhs.hasDisclosureIndicator == rhs.hasDisclosureIndicator &&
        lhs.hasBorder == rhs.hasBorder
}
