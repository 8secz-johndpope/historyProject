//
//  UserService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import PromiseKit

enum ImageType: Int {
    case profile = 0
    case cover
    case profileAlternateImage
    case coveraAternateImage
    case curatorImage
}

class UserService {
    
    static let USER_PATH = Constants.Path.Host + "/user"
    static let VIEW_USER_PATH = Constants.Path.Host + "/view/user"
    
    class func deviceZero() {
        let url = USER_PATH + "/device/zero"
        RequestFactory.post(url)
    }
    
    @discardableResult
    class func view(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/view"
        let request = RequestFactory.get(url, parameters: nil)
        request.exResponseJSON{ response in
            // try to cache all user object
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let user = Mapper<User>().map(JSONObject: response.result.value) {
                    Log.debug("Cache user : user key : \(user.userKey)")
                    CacheManager.sharedManager.cacheObject(user.cacheableObject())
                }
            }
            completion(response)
        }
        return request
    }
    
    @discardableResult
    class func viewUserByUserKey(_ userKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/view"
        let parameters = ["userkey" : userKey]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{ response in
            // try to cache all user object
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let user = Mapper<User>().map(JSONObject: response.result.value) {
                    Log.debug("Cache user : user key : \(user.userKey)")
                    CacheManager.sharedManager.cacheObject(user.cacheableObject())
                }
            }
            completion(response)
        }
        return request
    }
    @discardableResult
    class func viewWithUserKey(_ userKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/view/User"
        let parameters = ["userkey" : userKey]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{ response in
            // try to cache all user object
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let user = Mapper<User>().map(JSONObject: response.result.value) {
                    Log.debug("Cache user : user key : \(user.userKey)")
                    CacheManager.sharedManager.cacheObject(user.cacheableObject())
                }
            }
            completion(response)
        }
        
        return request
    }
    
    class func fetchUserIfNeeded(_ userKey: String, completion: @escaping (_ user: User?) -> Void) {
        if let user = CacheManager.sharedManager.cachedUserForUserKey(userKey) {
            Log.debug("Hit cache : user key : \(userKey)")
            completion(user)
        } else {
            Log.debug("Missing cache : user key : \(userKey)")
            viewWithUserKey(userKey, completion: { (response) in
                if response.response?.statusCode == 200 && response.result.isSuccess {
                    if let user = Mapper<User>().map(JSONObject: response.result.value) {
                        completion(user)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            })
        }
    }
    
    class func fetchUser(_ saveToCache: Bool) -> Promise<User> {
        return Promise{ fulfill, reject in
            UserService.view() { (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let user = Mapper<User>().map(JSONObject: response.result.value)!
                        if saveToCache == true {
                            Context.saveUserProfile(user)
                        }
                        fulfill(user)
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            }
            
        }
    }
    
    @discardableResult
    class func fetchUserAliasList(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/alias/list"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func saveAlias(_ alias: String, forUserKey userKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/alias/save"
        
        let parameters : [String : Any] = ["UserKey": userKey, "Alias": alias]
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}

        return request
    }
    
    class func viewListWithUserKeys(_ userKeys : [String], getFromCache: Bool = true, completion: @escaping ([String: User]) -> Void) {
        let url = USER_PATH + "/list/consumer/userkey"
        
        var map = [String: User]()
        var userKeysString = ""
        
        userKeys.forEach { (userKey) in
            if let user = CacheManager.sharedManager.cachedUserForUserKey(userKey), getFromCache {
                map[user.userKey] = user
            }
            else {
                userKeysString += userKey + ","
            }
        }
        
        if userKeysString.length > 0 {
            let index = userKeysString.index(userKeysString.endIndex, offsetBy: -1)
            userKeysString = String(userKeysString[..<index])
            let parameters = ["userkeys" : userKeysString]
            
            let request = RequestFactory.get(url, parameters: parameters)
            request.exResponseJSON{ response in
                // try to cache all user object
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    if let users = Mapper<User>().mapArray(JSONObject: response.result.value) {
                        
                        var cacheList = [UserCacheObject]()
                        
                        for user in users {
                            map[user.userKey] = user
                            cacheList.append(user.cacheableObject())
                        }
                        
                        CacheManager.sharedManager.cacheListObjects(cacheList)
                        completion(map)
                    }
                }
            }
        }
        else {
            completion(map)
        }
        
    }

    /*class func viewListWithUserKeys(userKey : [String], completion: ([User], [String: User]) -> Void) {
        var promise = [Promise<User?>]()
        for key in userKey {
            promise.append(
                Promise<User?> { fufill, fail in
                    fetchUserIfNeeded(
                        key,
                        completion: { responseUser in
                            fufill(responseUser)
                        }
                    )
                }
            )
        }
        
        when(promise)
            .then { (users) -> Void in
                var map = [String: User]()
                var list = [User]()
                for optinalUser in users {
                    if let user = optinalUser {
                        map[user.userKey] = user
                        list.append(user)
                    }
                }
                completion(list, map)
        }
    }*/
    
    static func viewWithUserName(_ userName: String, success: @escaping ((_ value: User) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Constants.Path.Host + "/view/User"
        let parameters = ["UserName" : userName]
        let scs:(_ value: User) -> Void = { (user) in
            CacheManager.sharedManager.cacheObject(user.cacheableObject())
            success(user)
        }
        RequestFactory.requestWithObject(.get, url: url, parameters: parameters, appendUserKey: false, success: scs, failure: failure)
    }
    
    static func viewWithUserKey(_ userKey : String, success: @escaping ((_ value: User) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Constants.Path.Host + "/view/User"
        let parameters = ["userkey" : userKey]
        let scs:(_ value: User) -> Void = { (user) in
            CacheManager.sharedManager.cacheObject(user.cacheableObject())
            success(user)
        }
        RequestFactory.requestWithObject(.get, url: url, parameters: parameters, appendUserKey: false, success: scs, failure: failure)
    }
    
    @discardableResult
    class func viewWithUserName(_ userName: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/view/User"
        let parameters = ["UserName" : userName]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{ response in
            // try to cache all user object
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let user = Mapper<User>().map(JSONObject: response.result.value) {
                    Log.debug("Cache user : user key : \(user.userKey)")
                    CacheManager.sharedManager.cacheObject(user.cacheableObject())
                }
            }
            completion(response)
        }
        return request
    }
	
    @discardableResult
    class func changeUserName(_ userName : String, password : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/usernamechange"
        let parameters: [String: Any] = [
            "UserKey": Context.getUserKey(),
            "UserName": userName,
            "Password": password
        ]
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func postUser(_ user : User, url : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        // create the request & response
        var request = URLRequest(url: URL(string: url)!, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 5)
        // create some JSON data and configure the request
        let jsonString = Mapper().toJSONString(user, prettyPrint: true)
        request.httpBody = jsonString!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        Log.debug(request.httpBody)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserDefaults.standard.object(forKey: "token") as? String, forHTTPHeaderField: "Authorization")
        let alamofireRequest = RequestFactory.networkManager.request(request)
        alamofireRequest.exResponseJSON{response in completion(response)}
        return alamofireRequest
    }
    	
    @discardableResult
    class func listAllRecommendedCurator(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/list/curator/recommended"
        let request = RequestFactory.get(url, parameters: ["limit": Constants.Paging.All] , appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func updateName(firstName: String, lastName: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let values: [String: Any] = ["FirstName": firstName, "LastName": lastName]
        return updateProfile(values: values, completion: completion)
    }
    
    @discardableResult
    class func updateDisplayName(displayName: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let values: [String: Any] = ["DisplayName": displayName]
        return updateProfile(values: values, completion: completion)
    }
    
    @discardableResult
    class func updateGender(gender: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let values: [String: Any] = ["Gender": gender]
        return updateProfile(values: values, completion: completion)
    }
    
    @discardableResult
    class func updateDateOfBirth(dateOfBirth: Date, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let values: [String: Any] = ["DateOfBirth": dateFormatter.string(from: dateOfBirth)]
        return updateProfile(values: values, completion: completion)
    }
    
    @discardableResult
    class func updateLocation(geoCountryId: Int, geoProvinceId: Int, geoCityId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let values: [String: Any] = ["GeoCountryId": geoCountryId, "GeoProvinceId": geoProvinceId, "GeoCityId": geoCityId]
        return updateProfile(values: values, completion: completion)
    }
    
    @discardableResult
    class func updateProfile(values: [String: Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/update"
        var parameters: [String: Any] = ["UserKey": Context.getUserKey() as Any]
        
        for (key, value) in values {
            parameters[key] = value
        }
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func updatePassword(currentPassword: String, newPassword: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/passwordchange"
        let parameters: [String: Any] = ["UserKey": Context.getUserKey(), "CurrentPassword": currentPassword, "Password": newPassword]
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func updateMobile(mobileCode: String, mobileNumber: String, mobileVerificationId: Int, mobileVerificationToken: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/mobilechange"
        let parameters: [String: Any] = [
            "UserKey": Context.getUserKey(),
            "MobileCode": mobileCode,
            "MobileNumber": mobileNumber,
            "MobileVerificationId": mobileVerificationId,
            "MobileVerificationToken": mobileVerificationToken
        ]
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func updateDevice(_ deviceId: String?, deviceIdPrevious: String?, completion: ((DataResponse<Any>) -> Void)?) -> DataRequest? {
        if deviceId != nil || deviceIdPrevious != nil {
            let url = USER_PATH + "/device/update"
            
            var parameters = [String: Any]()
            if let id = deviceId {
                parameters["DeviceId"] = id
            }
            if let id = deviceIdPrevious {
                parameters["DeviceIdPrevious"] = id
            }
            
            let request = RequestFactory.post(url, parameters: parameters)
            
            if let callback = completion {
                request.exResponseJSON(completionHandler: callback)
            }
            
            return request
        }
        return nil
    }

	
    class func uploadImage(_ image: UIImage, imageType: ImageType, success: @escaping (DataResponse<Any>) -> Void, fail: @escaping (Error) -> Void) {
//        var url = USER_PATH + ((imageType == .Profile) ? "/upload/profileimage" : "/upload/coverimage")
        
        var url = USER_PATH
        switch imageType {
        case .profile:
            url += "/upload/profileimage"
            break
        case .cover:
            url += "/upload/coverimage"
            break
        case .profileAlternateImage:
            url += "/upload/profilealternateimage"
            break
        case .coveraAternateImage:
            url += "/upload/coveralternateimage"
            break
        case .curatorImage:
              url += "/image/upload"
            break
        }
        
        RequestFactory.networkManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(UIImageJPEGRepresentation(image, Constants.CompressionRatio.JPG_COMPRESSION)!, withName: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
        },to: url, headers: Context.getHTTPHeader(Constants.AppVersion), encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    success(response)
                }
            case .failure(let encodingError):
                Log.debug(encodingError)
                fail(encodingError)
            }
        })
	}
    
    @discardableResult
    class func getPopularCuratorList(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/list/curator/popular"
		
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getAllPopularCuratorList(start: Int, limit: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/list/curator/popular?start=\(start)&limit=\(limit)"
        let isAppendUserKey = false
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: isAppendUserKey)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getRecommendedList(start: Int, limit: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/list/curator/recommended?isfeatured=1&start=\(start)&limit=\(limit)"
        let isAppendUserKey = false
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: isAppendUserKey)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func merchantContactList(_ merchantId : Int = -1,
                                   success: @escaping ((_ value: [User]) -> Void),
                                   failure: @escaping (_ error: Error) -> Bool) {

        let url = USER_PATH + "/list/merchant"
        var parameters: [String: Any]?
        
        if merchantId != -1 {
            parameters = ["MerchantId" : merchantId as Any]
        }
        
        RequestFactory.requestWithArray(
            .get,
            url: url,
            parameters: parameters,
            appendUserKey: false,
            success: success,
            failure: failure
        )
    }
    
    @discardableResult
    class func mmContactList(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/mmcontact/list"
        let request = RequestFactory.get(url, parameters: nil)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func listImagesCuratorAbout(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = USER_PATH + "/image/list"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    @discardableResult
    class func listImagesCuratorByUserKey(_ userkey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = USER_PATH + "/image/list"
        
        let parameters: [String : Any] = ["userkey" : userkey]
//                                                "UserImageKey" : userImageKey ]
            let request = RequestFactory.get(url,parameters: parameters, appendUserKey: false)
            request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    @discardableResult
    class func deleteImageCurator(_ userImageKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = USER_PATH + "/image/delete"
        
        let parameters: [String : Any] = ["UserKey" : Context.getUserKey(),
                                                "UserImageKey" : userImageKey ]
        
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    
    @discardableResult
    class func uploadUserDescription(_ description: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = USER_PATH + "/update"
        
        let parameters: [String : Any] = ["UserKey" : Context.getUserKey(),
                                                "UserDescription" : description ]
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    
    class func uploadPhoto(_ userKey : String, image : UIImage, success : @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void) {
        
        let url = USER_PATH + "/image/upload"
        let parameters: [String : String] = ["UserKey" : userKey]
        
        RequestFactory.networkManager.upload(
            multipartFormData: {
                multipartFormData in
                multipartFormData.append(UIImageJPEGRepresentation(image, Constants.CompressionRatio.JPG_COMPRESSION)!, withName: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
                for (key, value) in parameters {
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                }
            },
            to: url,
            method: .post,
            headers: Context.getHTTPHeader(Constants.AppVersion),
            encodingCompletion: {
                encodingResult in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    Log.debug("Success")
                    
                    upload.responseJSON { response in
                        Log.debug(response.request)  // original URL request
                        Log.debug(response.response) // URL response
                        Log.debug(response.data)     // server data
                        Log.debug(response.result)   // result of response serialization
                        
                        if let JSON = response.result.value {
                            Log.debug("JSON: \(JSON)")
                        }
                        
                        success(response)
                    }
                    
                case .failure(let encodingError):
                    Log.debug(encodingError)
                    
                    fail(encodingError)
                }
            }
        )
        
    }

    @discardableResult
    class func customerView(_ userKey: String, merchantId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = VIEW_USER_PATH + "/cs"
        let parameters: [String : Any] = [
            "userkey" : userKey,
            "merchantid" : merchantId
        ]

        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func orderstatus(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = USER_PATH + "/orderstatus"
        let request = RequestFactory.get(url, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
}
