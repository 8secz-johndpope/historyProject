//
//  PhotoFilterUtils.swift
//  merchant-ios
//
//  Created by Alan YU on 18/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import PromiseKit

typealias MMFilter = (source: PhotoFilterUtils.Source, filter: String, title: String, normalImageName: String, selectImageName: String)

protocol FilterWrapper {
    
}

class PhotoFilterUtils {
    
    enum Source {
        case myMM
        case tuTu
        case camera360
    }
    
    typealias WrappedFilterResult = (resource: Camera360Wrapper.Resource?, image: UIImage)
    
    static func apply(_ filter: MMFilter, toImage: UIImage, resource: Camera360Wrapper.Resource? = nil) -> Promise<WrappedFilterResult> {
        return Promise<WrappedFilterResult> { fulfill, reject in
            switch(filter.source) {
            case .tuTu:
                if let tutuFilter = TutuWrapper.Filter(rawValue: filter.filter) {
                    TutuWrapper.apply(tutuFilter, forImage: toImage).then { result in
                        fulfill(result)
                    }.catch { error in
                        reject(error)
                    }
                } else {
                    reject(NSError(domain: "Camera360", code: -1, userInfo: ["reason": "Invalid Image"]))
                }
            case .camera360:
                if let c360Filter = Camera360Wrapper.Filter(rawValue: filter.filter) {
                    Camera360Wrapper.apply(c360Filter, forImage: toImage, resource: resource).then { result in
                        fulfill(result)
                    }.catch { error in
                        reject(error)
                    }
                } else {
                    reject(NSError(domain: "Camera360", code: -2, userInfo: ["reason": "Invalid request"]))
                }
            case .myMM:
                break
            }
        }
    }
    
}
