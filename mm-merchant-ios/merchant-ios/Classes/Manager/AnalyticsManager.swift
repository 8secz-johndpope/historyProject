//
//  AnalyticsManager.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 4/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class AnalyticsManager {
    
    typealias AnalyticBlockForLoginCompleted = (_ userKey: String?) -> (Void)
    
    final let SendTimeInterval: TimeInterval = 60
    final let SessionExpireTime: Int = 1800 // 30min
    
    private final let AnalyticsPauseTime = "analyticsPauseTime"
    private final let AnalyticsSessionKey = "analyticsSessionKey"
    
    static let Headers: [String: String] = [
        "Content-Type": "application/json",
        "Cache-Control": "no-cache"
    ]
    
    private var sendTimer: Timer!
    
    private var sessionKey = ""
    private var analyticsRecords = [[String : Any]]()
    private var locationManager = LocationManager.sharedInstance()
    
    class var sharedManager: AnalyticsManager {
        get {
            struct Singleton {
                static let instance = AnalyticsManager()
            }
            return Singleton.instance
        }
    }
    
    private init() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.send), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        resetSendTimer()
        
        if !wakeUp() || sessionKey == ""{
            createNewSession()
        }
    }
    
    private let analyticsQueue = DispatchQueue(label: "com.mm.analytics", attributes: [])
    private func RunOnAnalyticsThread(_ block: @escaping ()->()) {
        analyticsQueue.async(execute: block)
    }
    
    func getSessionKey() -> String {
        return sessionKey
    }
    
    func recordCampaign(_ campaignRecord: AnalyticsCampaignRecord) {
        appendRecord(campaignRecord)
    }
    
    func recordView(_ viewRecord: AnalyticsViewRecord) {
        appendRecord(viewRecord)
    }
    
    func recordImpression(_ impressionRecord: AnalyticsImpressionRecord) {
        appendRecord(impressionRecord)
    }
    
    @discardableResult
    func recordImpression(_ authorRef: String? = nil,
                          authorType: String? = nil,
                          brandCode: String? = nil,
                          impressionRef: String? = nil,
                          impressionType: String? = nil,
                          impressionVariantRef: String? = nil,
                          impressionDisplayName: String? = nil,
                          merchantCode: String? = nil,
                          parentRef: String? = nil,
                          parentType: String? = nil,
                          positionComponent: String? = nil,
                          positionIndex: Int? = nil,
                          positionStringIndex: String? = nil,
                          positionLocation: String? = nil,
                          referrerRef: String? = nil,
                          referrerType: String? = nil,
                          viewKey: String ) -> String {
        
        let impressionKey = Utils.UUID()
        
        let impressionRecord = AnalyticsImpressionRecord()
        impressionRecord.viewKey = viewKey
        impressionRecord.impressionKey = impressionKey
        
        impressionRecord.authorRef = authorRef ?? ""
        impressionRecord.authorType = authorType ?? ""
        impressionRecord.brandCode = brandCode ?? ""
        impressionRecord.impressionRef = impressionRef ?? ""
        impressionRecord.impressionType = impressionType ?? ""
        impressionRecord.impressionVariantRef = impressionVariantRef ?? ""
        impressionRecord.impressionDisplayName = impressionDisplayName ?? ""
        impressionRecord.merchantCode = merchantCode ?? ""
        impressionRecord.parentRef = parentRef ?? ""
        impressionRecord.parentType = parentType ?? ""
        impressionRecord.positionComponent = positionComponent ?? ""
        impressionRecord.positionIndex = positionIndex ?? -1
        impressionRecord.positionStringIndex = positionStringIndex ?? ""
        impressionRecord.positionLocation = positionLocation ?? ""
        impressionRecord.referrerRef = referrerRef ?? ""
        impressionRecord.referrerType = referrerType ?? ""

        self.recordImpression(impressionRecord)
        
        return impressionKey
    }
    
    func recordAction(_ actionRecord: AnalyticsActionRecord) {
        appendRecord(actionRecord)
    }
    
    @objc func send() {
        
        RunOnAnalyticsThread {
            
            if self.analyticsRecords.count > 0 {
                
                // Collections copy by value
                let records = self.analyticsRecords
                // Clear analyticsRecords
                self.analyticsRecords.removeAll()
                
                AnalyticsService.post(
                    records,
                    success: { [weak self] (response) in
                        if response.response?.statusCode == 200 {
                            // TODO: Success
                        } else {
                            self?.insertFailedSessions(records)
                        }
                    },
                    fail: { [weak self] (error) in
                        self?.insertFailedSessions(records)
                    }
                )
            }
            
        }
    }
    
    
    func insertFailedSessions(_ failedRecords : [[String: Any]] ){
        RunOnAnalyticsThread {
            let sessions = failedRecords.filter{ $0["ty"] as? String == "s" }
            self.analyticsRecords += sessions
        }
    }
    
    func resetSendTimer() {
        RunOnAnalyticsThread {
            if self.sendTimer != nil {
                self.sendTimer.invalidate()
            }
            
            self.sendTimer = Timer.scheduledTimer(timeInterval: self.SendTimeInterval, target: self, selector: #selector(self.send), userInfo: nil, repeats: true)
        }
    }
    
    private func appendRecord(_ record: AnalyticsRecord) {
        
        record.sessionKey = self.sessionKey
        
        RunOnAnalyticsThread {
            
            self.analyticsRecords.append(record.build())
            
            if self.analyticsRecords.count >= 100 {
                self.send()
                self.resetSendTimer()
            }
        }
    }
    
    // MARK: - renew Session track other app open mm
    internal func renewSession(query:QBundle) {
        if let from = query["from"]?.string,!from.isEmpty {
            updateSession(track:from)
        }
    }
    
    // MARK: - Session Control
    
    internal func createNewSession() {
        sessionKey = Utils.UUID()
        
        wirteSessionKeyToCookies(sessionKey)
        
        createSession()
        
        
        logTalkingDataID()
        
        // For QA
        print("New sessionKey: \(sessionKey)")
    }
    
    internal func updateSession(track from:String = ""){
        createSession(track:from)
        
        // For QA
        print("Update sessionKey: \(sessionKey)")
    }
    
    private func createSession(track from:String = ""){
        let analyticsSessionRecord = AnalyticsSessionRecord()
        analyticsSessionRecord.sessionKey = sessionKey
        analyticsSessionRecord.screenDimension = from
        
        if let location = locationManager.getCurrentLocation() {
            analyticsSessionRecord.latitude = location.coordinate.latitude
            analyticsSessionRecord.longitude = location.coordinate.longitude
        }
        
        RunOnAnalyticsThread {
            let recordDict = analyticsSessionRecord.build()
            self.analyticsRecords.append(recordDict)
            self.send()
        }
    
    }
    
    func sleep() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(AnalyticsManager.getTimestamp(), forKey: AnalyticsPauseTime)
        userDefaults.set(sessionKey, forKey: AnalyticsSessionKey)
        userDefaults.synchronize()
    }
    
    @discardableResult
    // return true means we dont have to create a new session outside
    func wakeUp() -> Bool {
        let userDefaults = UserDefaults.standard
        
        if let analyticsPauseTime = userDefaults.object(forKey: AnalyticsPauseTime) as? Int, let loadedSessionKey = userDefaults.string(forKey: AnalyticsSessionKey) {
            
            userDefaults.removeObject(forKey: AnalyticsPauseTime)
            userDefaults.removeObject(forKey: AnalyticsSessionKey)
            
            if AnalyticsManager.getTimestamp() - analyticsPauseTime > SessionExpireTime {
                // Upload previous session records
                send()

                // Start new session
                createNewSession()
            } else {
                // Resume session 
                sessionKey = loadedSessionKey
                
            }
            
            wirteSessionKeyToCookies(sessionKey)
            
            return true // as we created the session inside the function already
        }
        
        return false // if we didn't store any sesions or time
    }
    
    
    // MARK: - Helper
    
    private class func getTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    
    class func trimTextForImpressionDisplayName(_ text: String? = "") -> String {
        if let text = text {
            if text.length > 50 {
                return text[0...49]
            }
            
            return text
        }
        
        return ""
    }
    
    class func createActionRecord(analyticsViewKey: String, analyticsImpressionKey: String? = nil, actionTrigger: AnalyticsActionRecord.ActionTriggerType = .Unknown, sourceRef: String? = nil, sourceType: AnalyticsActionRecord.ActionElement = .Unknown, targetRef: String? = nil, targetType: AnalyticsActionRecord.ActionElement = .Unknown) -> AnalyticsActionRecord {
        
        let analyticsActionRecord = AnalyticsActionRecord()
        
        analyticsActionRecord.viewKey = analyticsViewKey
        analyticsActionRecord.impressionKey = analyticsImpressionKey ?? ""
        analyticsActionRecord.actionKey = Utils.UUID()
        
        analyticsActionRecord.actionTrigger = actionTrigger
        analyticsActionRecord.sourceRef = sourceRef ?? ""
        analyticsActionRecord.sourceType = sourceType
        analyticsActionRecord.targetRef = targetRef ?? ""
        analyticsActionRecord.targetType = targetType
        
        return analyticsActionRecord
    }
    
    func recordCampaign(params: String)  { //brooksbrothersdemo?cs=wechat&cm=message&ca=u:39df65c2-45c9-483d-8125-de8cb04d5103&from=singlemessage&isappinstalled=1&
        
        let campaignRecord = AnalyticsCampaignRecord()
        
        let value = params
        var array = value.components(separatedBy: "?")
        var campaignCode = ""
        var campaignSource = ""
        var campaignMedium = ""
        var campaignUserKey = ""
        if array.count > 1 {
            campaignCode = array[0]
            let array1 = array[1].components(separatedBy: "&")
            for component in array1 {
                if component.contain("cs=") {
                    campaignSource = component.replacingOccurrences(of: "cs=", with: "")
                } else if component.contain("cm=") {
                    campaignMedium = component.replacingOccurrences(of: "cm=", with: "")
                } else if component.contain("ca=") {
                    campaignUserKey = component.replacingOccurrences(of: "ca=", with: "")
                }
            }
            
        }
        
        campaignRecord.campaignKey = Utils.UUID()
        campaignRecord.campaignCode = campaignCode
        campaignRecord.campaignSource = campaignSource
        campaignRecord.campaignMedium = campaignMedium
        campaignRecord.campaignUserKey = campaignUserKey
        self.recordCampaign(campaignRecord)
        
    }
    
    private func logTalkingDataID() {
        let action = AnalyticsManager.createActionRecord(
            analyticsViewKey: "",
            analyticsImpressionKey: "",
            actionTrigger: AnalyticsActionRecord.ActionTriggerType.System,
            sourceRef: TrackManager.getDeviceId(),
            sourceType: AnalyticsActionRecord.ActionElement.App,
            targetRef: "TDID",
            targetType: AnalyticsActionRecord.ActionElement.App
        )
        appendRecord(action)
    }
    
    private func wirteSessionKeyToCookies(_ sk: String) {
        for domain in Constants.SessionCookieDomains {
            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: "MMSessionKey",
                .value: sk,
                .domain: domain,
                .path: "/",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 365 * 10) // 10 years
            ]
            
            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
}
