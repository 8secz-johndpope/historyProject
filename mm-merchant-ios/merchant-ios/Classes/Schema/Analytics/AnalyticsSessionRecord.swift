//
//  AnalyticsSessionRecord.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit
import CoreTelephony

class AnalyticsSessionRecord: AnalyticsRecord {
    
    private var appDistribution = "App Store"
    private var appVersion = ""                         // 1.1.1 - CFBundleShortVersionString
    private var cultureCode = ""                        //
    private var deviceBrand = "Apple"                   //
    private var deviceChannel = "app"                   //
    private var deviceKey = ""                          // GUID
    private var deviceModel = ""                        // iPhone 5s ***
    private var deviceType = "iOS"                      //
    private var deviceVersion = ""                      // 9.1
    private var ipAddress = ""                          // 192.168.0.1 ***
    var latitude: Double = 0                            // Decimal(9,6)
    var longitude: Double = 0                           // Decimal(9,6)
    private var networkCarrier = ""                     // csl.
    var networkSignal = -1                              // 1, 2, 3, 4
    private var networkType = ""                        // LTE
    var screenDimension = ""                            // 原屏幕尺寸，现在用于记录session唤醒来源，用于追踪推广
    private var screenResolution = ""                   // 1136 x 640 后面修改：如果为web的tsession，则字段sr为来自app的sessionkey；uk为来自app用户的userkey。

    private var userKey = ""
    private var userName = ""
    
    override init() {
        super.init()
        type = "s"

        if let infoDictionary = Bundle.main.infoDictionary, let bundleVersion = infoDictionary["CFBundleShortVersionString"] as? String {
            appVersion = bundleVersion
        }
        
        cultureCode = Context.getCc()
        
        if let identifierForVendor = UIDevice.current.identifierForVendor {
            deviceKey = identifierForVendor.uuidString
        }
        
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        deviceVersion = UIDevice.current.systemVersion
        
        let networkInfo = CTTelephonyNetworkInfo()
        
        if let carrier = networkInfo.subscriberCellularProvider {
            networkCarrier = carrier.carrierName ?? ""
        }
        
//        if let currentRadioAccessTechnology = networkInfo.currentRadioAccessTechnology {
//            networkType = currentRadioAccessTechnology.replacingOccurrences(of: "CTRadioAccessTechnology", with: "")
//        }
        
        networkType = self.getNetworkType()
        let nativeScale = UIScreen.main.nativeScale
        let screenWidth = Int(UIScreen.main.bounds.width * nativeScale)
        let screenHeight = Int(UIScreen.main.bounds.height * nativeScale)
        
        
        screenResolution = "\(screenWidth) x \(screenHeight)"
        var uk = Context.getUserKey()
        if uk.isEmpty || uk == "0" {
            uk = User.guestUser().userKey
        }
        userKey = uk
        userName = Context.getUsername()
    }
    
    override func build() -> [String : Any] {
        let parameters: [String : Any] = [
            "ad" : appDistribution as Any,
            "av" : appVersion as Any,
            "cc" : cultureCode as Any,
            "db" : deviceBrand as Any,
            "dc" : deviceChannel as Any,
            "dk" : deviceKey as Any,
            "dm" : deviceModel as Any,
            "dt" : deviceType,
            "dv" : deviceVersion,
            "na" : ipAddress,
            "la" : String(format: "%.06f", latitude),
            "lo" : String(format: "%.06f", longitude),
            "nc" : networkCarrier,
            "ns" : "\(networkSignal)",
            "nt" : networkType,
            "sd" : screenDimension,
            "sr" : screenResolution,
            "sk" : sessionKey,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "ty" : type,
            "uk" : userKey,
            "un" : userName
        ]
        
        return parameters
    }
    
    //MARK: - Private Functions
    
    func getNetworkType() -> String {
        
        var networkType = ""
        let reachability = Reachability.shared()
        let status: NetworkStatus = reachability!.currentReachabilityStatus()
        if status == NotReachable {
            
            //No internet
        }
        else if status == ReachableViaWiFi {
            networkType = "Wifi"
        }
        else if status == ReachableViaWWAN {
            
            let netinfo = CTTelephonyNetworkInfo()
            //let carrier = netinfo.subscriberCellularProvider?.carrierName
            
            if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyGPRS) {
                networkType = "2G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyEdge) {
                networkType = "2G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyWCDMA) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyHSDPA) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyHSUPA) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyCDMA1x) {
                networkType = "2G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyCDMAEVDORev0) {
               networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyCDMAEVDORevA) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyCDMAEVDORevB) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyeHRPD) {
                networkType = "3G"
            }
            else if (netinfo.currentRadioAccessTechnology == CTRadioAccessTechnologyLTE) {
                networkType = "LTE"
            }
        }
        return networkType
    }
}
