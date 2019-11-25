//
//  AddressData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 4/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AddressData {
    
    enum AddressFormat: Int {
        case chinese
        case english
    }
    
    var recipientName = ""
    var recipientPhoneNumber = ""
    
    private var address = ""
    private var city = ""
    private var province = ""
    private var country = ""
    
    init(order: Order, orderShipment: Shipment? = nil) {
        recipientName = order.recipientName
        recipientPhoneNumber = "\(order.phoneCode) \(order.phoneNumber)"
        
        if let shipment = orderShipment {
            address = shipment.address
            city = shipment.city
            province = shipment.province
            country = shipment.country
        } else {
            address = order.address
            city = order.city
            province = order.province
            country = order.country
        }
    }
    
    init(orderShipment: Shipment) {
        recipientName = orderShipment.recipientName
        recipientPhoneNumber = "\(orderShipment.phoneCode) \(orderShipment.phoneNumber)"
        address = orderShipment.address
        city = orderShipment.city
        province = orderShipment.province
        country = orderShipment.country
    }
    
    init(address: Address) {
        recipientName = address.recipientName
        recipientPhoneNumber = "\(address.phoneCode) \(address.phoneNumber)"
        
        self.address = address.address
        city = address.city
        province = address.province
        country = address.country
    }
    
    func getFullAddress(withFormat format: AddressFormat = .chinese) -> String {
        switch format {
        case .chinese:
            //MM-18895: Remove comma
            return "\(country) \(province) \(city) \(address)"
        case .english:
            return "\(address), \(city), \(province), \(country)"
        }
    }
    
}
