//
//  TrackManager.swift
//  storefront-ios
//
//  Created by Demon on 10/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

class TrackManager {
    
    enum TrackSignType: String {
        case signUp = "sign_up"
        case signIn = "sign_in"
        case payOrderNum = "pay_order_num"
        case orderNum = "order_num"
    }
    
    /// 注册埋点功能
    static func configTrackInfo() {
        Growing.start(withAccountId: Platform.GrowingIO.GrowingIOID)
    }
  
    static func setUserId(_ userId: String) {
        Growing.setUserId(userId)
    }
    
    static func clearUserId() {
        Growing.clearUserId()
    }
    
    static func getDeviceId()  -> String {
        return Growing.getDeviceId()
    }

    /// GMV订单埋点
    ///
    /// - Parameters:
    ///   - order_id: 订单号
    ///   - pay_amount: 实际支付金额
    ///   - order_amount: 订单金额
    static func recordGMV(orderId order_id: String, payOrderAmount pay_amount: Double, orderAmount order_amount: Double) {
        record(eventId: TrackSignType.orderNum, orderId: order_id, payOrderAmount: pay_amount, orderAmount: order_amount)
    }
    
    /// 支付成功埋点
    ///
    /// - Parameters:
    ///   - order_id: 订单号
    ///   - pay_amount: 实际支付金额
    ///   - order_amount: 订单金额
    static func recordPay(orderId order_id: String, payOrderAmount pay_amount: Double, orderAmount order_amount: Double) {
        record(eventId: TrackSignType.payOrderNum, orderId: order_id, payOrderAmount: pay_amount, orderAmount: order_amount)
    }
    
    private static func record(eventId event_id: TrackSignType,orderId order_id: String, payOrderAmount pay_amount: Double, orderAmount order_amount: Double) {
        Growing.track(event_id.rawValue, withVariable: ["order_id":order_id,"pay_order_amount_string":String(pay_amount*100),"pay_order_amount":Int64(pay_amount*100),"order_amount_string":String(order_amount*100),"order_amount":Int64(order_amount*100)])

    }
    
    /// 注册埋点
    ///
    /// - Parameters:
    ///   - userK: userkey
    static func signUp(_ userkey: String) {
        Growing.track(TrackSignType.signUp.rawValue, withVariable: ["UserKey": userkey])
    }
    
    /// 登录埋点
    ///
    /// - Parameter userkey: userkey
    static func signIn(_ userkey: String) {
        Growing.track(TrackSignType.signIn.rawValue, withVariable: ["UserKey": userkey])
    }
    
    static func handleURL(_ url: URL)  -> Bool {
        if Growing.handle(url) {
            return true
        }
        return false
    }
    
}
