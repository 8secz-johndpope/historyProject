//
//  AlipayCreateSign.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 10/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class AlipayCreateSign: Mappable {
    
    var body = "body"
    var currency = "HKD"
//    var externToken = ""
    var forexBiz = "FP"
//    var inputCharset = ""
    var itBPay = "30m"
//    var notifyUrl = ""
    var outTradeNo = "parentOrderKey"
    var paymentType = "1"
    var productCode = "NEW_WAP_OVERSEAS_SELLER"
    var rmbFee = ""
    var service = "mobile.securitypay.pay"
    var splitFundInfo = ""
    var subject = "subject"
    var totalFee = ""
    
    required init?(map: Map) {
        
    }
    
    init() {
        
    }
    
    func mapping(map: Map) {
        body                <- map["body"]
        currency            <- map["currency"]
//        externToken         <- map["extern_token"]
        forexBiz            <- map["forex_biz"]
//        inputCharset        <- map["input_charset"]
        itBPay              <- map["it_b_pay"]
//        notifyUrl           <- map["notify_url"]
        outTradeNo          <- map["out_trade_no"]
        paymentType         <- map["payment_type"]
        productCode         <- map["product_code"]
        rmbFee              <- map["rmb_fee"]
        service             <- map["service"]
        splitFundInfo       <- map["split_fund_info"]
        subject             <- map["subject"]
        totalFee            <- map["total_fee"]
    }
    
}

