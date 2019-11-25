//
//  IMDateTransform.swift
//  merchant-ios
//
//  Created by Alan YU on 21/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

open class IMDateTransform: DateFormatterTransform {
    
    public init(stringFormat : String? = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") {
        let formatter = DateFormatter()
        formatter.dateFormat = stringFormat
        
        super.init(dateFormatter: formatter)
    }
}
