//
//  TimestampService.swift
//  merchant-ios
//
//  Created by Jerry CHong on 7/27/17.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class TimestampAPIService {
    
    @discardableResult
    class func viewTimestamp(completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/timestamp"
        let parameters: [String: Any] = ["ts": (Date().timeIntervalSince1970 * 1000).description as Any]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
}

class TimestampService: NSObject {
    static let defaultService = TimestampService()
    let timestampKey = "com.mymm.userdefault.servertime"
    
    func updateServerTime(){
        TimestampAPIService.viewTimestamp() { (response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let timeDict = response.result.value as? [String: Any] {
                        if let value = timeDict["Timestamp"] {
                            let dateformat = DateTransformExtension(dateFormat: .dateTimeComplexWithoutZ)
                            if let currentServerTime = dateformat.transformFromJSON(value) {
                                let deltaTime = self.getDeltaTime(currentServerTime)
                                let userDefaults = UserDefaults.standard
                                userDefaults.set(deltaTime, forKey: self.timestampKey)
                                userDefaults.synchronize()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getServerTime() -> Date?{
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: timestampKey) != nil  {
            if let timeInterval = userDefaults.object(forKey: timestampKey) as? TimeInterval {
                let date = Date(timeIntervalSinceNow: timeInterval)
                return date
            }
        }
        return nil
    }
    
    func getDeltaTime(_ serverTime: Date) -> TimeInterval{
        let remainingTimeInterval = serverTime.timeIntervalSinceNow
        return remainingTimeInterval
    }
    
}


