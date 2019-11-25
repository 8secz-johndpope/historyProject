//
//  CustomerServiceMerchants.swift
//  merchant-ios
//
//  Created by Alan YU on 10/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class CustomerServiceMerchants: Mappable {
    
    fileprivate(set) var merchants: [Merchant]? {
        didSet {
            self.updateMerchantColor()
        }
    }
    
    fileprivate(set) var merchantColorMap = [Int: UIColor]()
    let colorArray = [UIColor(hexString: "FB53F2"), UIColor(hexString: "4A90E2"), UIColor(hexString: "50E3C2"), UIColor(hexString: "096F63"), UIColor(hexString: "77D8FF"), UIColor(hexString: "B7AD3E"), UIColor(hexString: "E0FF00"), UIColor(hexString: "FFEA5A"), UIColor(hexString: "FFAF35"), UIColor(hexString: "AB7444")]
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    convenience init(merchants: [Merchant]) {
        self.init()
        self.merchants = merchants
    }
	
    // Mappable
    func mapping(map: Map) {
        merchants <- map["Merchants"]
    }
    
    func merchantIds() -> [Int] {
        var result =  [Int]()
        if let merchants = self.merchants {
            for merchant in merchants {
                result.append(merchant.merchantId)
            }
        }
        return result
    }
    
    func updateMerchantColor() {
        merchantColorMap.removeAll()
        
        let merchantIds = self.merchantIds()
        
        var colorIndex = 0
        
        for merchantId in merchantIds {
            
            if merchantId == Constants.MMMerchantId {
                merchantColorMap[merchantId] = UIColor.primary1()
            } else {
                let index = colorIndex % colorArray.count
                if index < colorArray.count {
                    merchantColorMap[merchantId] = colorArray[index]
                    colorIndex += 1
                }
            }
        }
    }
    
    func merchantColorForId(_ merchantId: Int) -> UIColor? {
        return merchantColorMap[merchantId]
    }
    
}
