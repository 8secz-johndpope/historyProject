//
//  WeChatManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 18/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol WeChatAuthDelegate : class {
    
    func handleWeChatCallback(_ authResponseCode: String)
}

class WeChatManager : NSObject, WXApiDelegate {
    
    private static let instance = WeChatManager()
    
    static func sharedInstance() -> WeChatManager {
        return WeChatManager.instance
    }
    
    weak var delegate : WeChatAuthDelegate?
    
    
    class func login(_ viewController : UIViewController){
        Log.debug("leftButtonClicked")
        let req = SendAuthReq()
        req.scope = "snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact"
        req.state = "xxx"
        WXApi.sendAuthReq(
            req,
            viewController: viewController,
            delegate: instance
        )
        
    }
    
    
    //MARK: WXApiDelegate method
    func onResp(_ resp: BaseResp!) {
        Log.debug("on Resp from WeChat")
        Log.debug("Err Code from WeChat : \(resp.errCode)")
        Log.debug("Err String from WeChat : \(resp.errStr)")
        if let sendAuthResp = resp as? SendAuthResp {
            if let code = sendAuthResp.code { //If user cancel in Wechat MM acceptance, code will be nil
                Log.debug("Auth code from WeChat : \(code)")
                Log.debug("State from WeChat : \(sendAuthResp.state)")
                Log.debug("Lang from WeChat : \(sendAuthResp.lang)")
                Log.debug("Country from WeChat : \(sendAuthResp.country)")
//                NotificationCenter.default.post(name: "LoginWeChat", object: nil, userInfo: ["Code" : code])
                
                if let handler = self.delegate {
                    handler.handleWeChatCallback(code)
                }
                
                // request push and location permissions for any wechat response
                Utils.requestLocationAndPushNotification()
            }
        } else if let sendMessageResponse = resp as? SendMessageToWXResp {
            Log.debug("Return from wechat lang: \(sendMessageResponse.lang), country: \(sendMessageResponse.country)")
            ShareManager.sharedManager.handleShareResult(.weChatMessage, isSuccess: sendMessageResponse.errCode == 0)
            //TODO: call back from wechat
            ShareManager.sharedManager.invokeSharingCompletion(.weChatMoment, isSuccess: (sendMessageResponse.errCode == 0))
        }
        
    }
    
    func onReq(_ req: BaseReq!) {
        Log.debug("on Request from WeChat")
        
    }
    
    
    
}
