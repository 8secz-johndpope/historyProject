//
//  OrderTransaction.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 24/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderTransaction: Mappable {
    
    enum TransactionProvider: Int {
        case unknown = 0
        case alipay
        case manual
        case wechatPay
    }
    
    enum TransactionStatus: Int {
        case unknown = 0
        case cancelled
        case completed
        case requested
        case processed
        case fail
        case waiting
    }
    
    enum TransactionType: Int {
        case unknown = 0
        case payment
        case refund
    }
    
    enum PaymentRecordType: Int {
        case unknown = 0
        case alipayPayment
        case customerExtraPayment
        case alipayRefund
        case platformExtraRefund
        case wechatpayPayment
        case wechatpayRefund
    }
    
    var amount: CGFloat = 0
    var comments = ""
    var description = ""
    var isCrossBorder = false
    var isManual = false
    var lastCompleted = Date()
    var lastCreated = Date()
    var lastModified = Date()
    var merchantId = 0
    var orderTransactionKey = ""
    var referenceNo = ""
    var transactionProviderId = 0
    var transactionStatusId = 0
    var transactionTypeId = 0
    
    var transactionProvider: TransactionProvider = .unknown
    var transactionStatus: TransactionStatus = .unknown
    var transactionType: TransactionType = .unknown
    var paymentRecordType: PaymentRecordType = .unknown
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        amount                          <- map["Amount"]
        comments                        <- map["Comments"]
        description                     <- map["Description"]
        isCrossBorder                   <- map["IsCrossBorder"]
        isManual                        <- map["IsManual"]
        lastCompleted                   <- (map["LastCompleted"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        merchantId                      <- map["MerchantId"]
        orderTransactionKey             <- map["OrderTransactionKey"]
        referenceNo                     <- map["ReferenceNo"]
        transactionProviderId           <- map["TransactionProviderId"]
        transactionStatusId             <- map["TransactionStatusId"]
        transactionTypeId               <- map["TransactionTypeId"]
        
        transactionProvider             <- (map["TransactionProviderId"], EnumTransform<TransactionProvider>())
        transactionStatus               <- (map["TransactionStatusId"], EnumTransform<TransactionStatus>())
        transactionType                 <- (map["TransactionTypeId"], EnumTransform<TransactionType>())
        
        if transactionStatus == .completed || transactionStatus == .waiting {
            switch transactionProvider {
            case .alipay:
                switch transactionType {
                case .payment:
                    paymentRecordType = .alipayPayment
                case .refund:
                    paymentRecordType = .alipayRefund
                default:
                    break
                }
            case .manual:
                switch transactionType {
                case .payment:
                    paymentRecordType = .customerExtraPayment
                case .refund:
                    paymentRecordType = .platformExtraRefund
                default:
                    break
                }
            case .wechatPay:
                switch transactionType {
                case .payment:
                    paymentRecordType = .wechatpayPayment
                case .refund:
                    paymentRecordType = .wechatpayRefund
                default:
                    break
                }
            default:
                break
            }
        }
    }
}

