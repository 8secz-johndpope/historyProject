//
//  NewsFeedService.swift
//  merchant-ios
//
//  Created by Markus Chow on 25/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class NewsFeedService {
	
	static let POST_PATH = Constants.Path.Host + "/post"
	
    @discardableResult
    class func listNewsFeedForUser(_ userKey : String, pageno: Int, followingUserKeys: [String]? = nil, followingMerchantIds: [Int]? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var params:[String : Any] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset, "userkeytarget": userKey]
        
        if let followUsers = followingUserKeys, followUsers.count > 0 {
            params["followuserlist"] = followUsers.joined(separator: ",")
        }
        
        if let followMerchants = followingMerchantIds, followMerchants.count > 0{
            params["followmerchantlist"] = followMerchants.map{ String($0) }.joined(separator: ",")
        }
        
        let url = Constants.Path.Host + "/search/post"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listNewsFeedByUser(_ userKey : String, pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset, "merchantid": 0]
        let url = Constants.Path.Host + "/search/post?userkeyauthor=\(userKey)"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listNewsFeedByPostIds(_ postIds : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        

        let url = Constants.Path.Host + "/search/post/activity/count/list?postids=\(postIds)"
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func listNewsFeedByMerchant(_ merchantId : Int, pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset]
        let url = Constants.Path.Host + "/search/post?merchantid=\(merchantId)"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
	class func listNewsFeedByProduct(_ skuId : Int, pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
		
		let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset]
		let url = Constants.Path.Host + "/search/post/product/list?skuid=\(skuId)"
		let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
		request.exResponseJSON{response in completion(response)}
		return request
	}

    @discardableResult
    class func listNewsFeedByCurators(_ pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset]
        let url = Constants.Path.Host + "/search/post?iscuratorpost=1"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listNewsFeedByHashTag(_ hashTag : String, pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset]

        var hashTagValue: String = hashTag
        
        //To remove first "#"
        if hashTagValue.hasPrefix("#") && hashTagValue.length > 1 {
            hashTagValue = String(hashTagValue.dropFirst())
        }
        
        //This is for fixing crash when hashTag value is Chinese
        if let hashTagEncoding = hashTag.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            hashTagValue = hashTagEncoding
        }
        
        let url = Constants.Path.Host + "/search/post?sh=\(hashTagValue)"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    //http://mobile-mm.eastasia.cloudapp.azure.com/api/search/post?cc=CHS&postid=5
    @discardableResult
    class func listNewsFeedByPostId(_ postId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let params:[String : Int] = ["pagesize" : Constants.Paging.PostOffset]
        let url = Constants.Path.Host + "/search/post?postid=\(postId)"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func likeNewsFeed(_ postId: Int , correlationKey: String,  completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
     
        let params:[String : Any] = ["PostId" : postId, "CorrelationKey": correlationKey]
        let url = POST_PATH + "/queued/like/save"
        
        let request = RequestFactory.post(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    @discardableResult
    class func unlikeNewsFeed(_ postLikeId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = POST_PATH + "/like/status/change"
        
        let parameters: [String : Any] = ["PostLikeId" : postLikeId,
                                                "StatusId" : Constants.StatusID.deleted.rawValue]
        
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getLikedObjectsByUser(_ pageno: Int, pageSize: Int = Constants.Paging.LikeListOffset, completionInBackground : @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let params:[String : Any] = ["pageno": pageno, "pagesize" : pageSize]
        let url = Constants.Path.Host + "/search/post/like"
        
        let request = RequestFactory.get(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{ response in
            background_async {
                completionInBackground(response)
            }
        }
        return request
    }

    @discardableResult
    class func getLikedObjectsByPost(_ postId: Int, pageNo: Int, pageSize: Int = Constants.Paging.Offset, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let params:[String : Any] = ["pageno": pageNo, "pagesize" : pageSize, "postid": postId]
        
        let url = Constants.Path.Host + "/search/post/like"
        
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func repostNewsFeed(_ postId: Int, correlationKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Any] = ["PostId" : postId, "CorrelationKey": correlationKey]
        let url = Constants.Path.Host + "/post/repost"
        
        let request = RequestFactory.post(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }

    @discardableResult
	class func saveNewFeed(_ postData : Post, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
		
		let url = POST_PATH + "/savemulti"
		
		if postData.correlationKey == "" {
			postData.correlationKey = Utils.UUID()
		}
		
		var parameters: [String : Any] = ["UserKey" : postData.userKey,
		                                        "PostText" : postData.postText,
		                                        "MerchantList": postData.getMerchantList(),
		                                        "UserList": postData.getUserList(),
		                                        "SkuList": postData.getSkusParameter(),
		                                        "CorrelationKey": postData.correlationKey,
                                                "Images":postData.getImagesParameter(),
                                                "PostImage":postData.postImage,
                                                "Feature":postData.feature]
		
		if postData.merchantId > 0 {
			parameters["MerchantId"] = postData.merchantId
			parameters["IsMerchantIdentity"] = (postData.isMerchantIdentity == MerchantIdentity.fromContentManager) ? 1 : 0
		}
		
		if (postData.groupKey != "") {
			parameters["GroupKey"] = postData.groupKey
		}
        
		let request = RequestFactory.post(url, parameters: parameters)
		request.exResponseJSON{response in completion(response)}
		return request
	}
    
    @discardableResult
    class func savePostComment(_ postComment : PostCommentList, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = POST_PATH + "/queued/comment/save"
        postComment.correlationKey = Utils.UUID()
        
        let parameters: [String : Any] = ["UserKey" : Context.getUserKey(),
                                                "PostCommentText" : postComment.postCommentText,
                                                "PostId": postComment.postId ?? 0,
                                                "CorrelationKey": postComment.correlationKey]
        
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func deleteNewsFeed(_ postId: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = POST_PATH + "/status/change"
        
        let parameters: [String : Any] = ["PostId" : postId,
                                                "StatusId" : Constants.StatusID.deleted.rawValue]
        
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func uploadPhoto(_ postId : String, image : UIImage, success : @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void) {
		
		let url = POST_PATH + "/upload/photo"
		let parameters: [String : String] = ["PostId" : postId, "UserKey": Context.getUserKey()]
		
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                autoreleasepool {
                    multipartFormData.append(UIImageJPEGRepresentation(image, Constants.CompressionRatio.JPG_COMPRESSION)!, withName: "file", fileName: "iosFile.jpg", mimeType: "image/jpg")
                    for (key, value) in parameters {
                        multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                    }
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
    class func listPostComment(_ postId : Int, pageno: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let params:[String : Int] = ["pageno": pageno, "pagesize" : Constants.Paging.CommentOffset]
        let url = Constants.Path.Host + "/search/post/comment?postid=\(postId)"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
	
    @discardableResult
    class func changePostCommentStatus(_ postComment : PostCommentList, statusId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = POST_PATH + "/comment/status/change"
        let parameters: [String : Any] = ["UserKey" : Context.getUserKey(),
                                                "PostCommentId": postComment.postCommentId ?? 0,
                                                "StatusId": statusId]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request

        
    }
    
    @discardableResult
    class func fetchPostLikedByPostIds(_ postIds: String, pageSize: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/post"
        let params: [String: Any] = ["postid": postIds, "pagesize" : pageSize]
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func createReportPost(reportReasonId: Int, reportDescription: String, postId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = POST_PATH + "/report/create"
        let parameters: [String: Any] = [
            "PostId": postId,
            "UserKey" : Context.getUserKey(),
            "Description" : reportDescription,
            "ReportReasonId": reportReasonId
        ]
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    
}
