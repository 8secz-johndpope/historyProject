//
//  AnalyticsSectionData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 6/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AnalyticsSectionData {
    
    private var analyticsViewKey: String = ""
    private var analyticsImpressionKey: String = ""
    private var lastTriggerIndex = 0
    private var analyticsImpressionRecord: AnalyticsImpressionRecord?
    
    init(analyticsImpressionRecord: AnalyticsImpressionRecord) {
        self.analyticsImpressionRecord = analyticsImpressionRecord
        self.analyticsViewKey = analyticsImpressionRecord.viewKey
    }
    
    func recordAction(_ actionTrigger: AnalyticsActionRecord.ActionTriggerType = .Unknown, sourceRef: String? = nil, sourceType: AnalyticsActionRecord.ActionElement = .Unknown, targetRef: String? = nil, targetType: AnalyticsActionRecord.ActionElement = .Unknown) {
        let analyticsActionRecord = AnalyticsActionRecord()
        
        analyticsActionRecord.viewKey = analyticsViewKey
        analyticsActionRecord.impressionKey = analyticsImpressionKey 
        analyticsActionRecord.actionKey = Utils.UUID()
        
        analyticsActionRecord.actionTrigger = actionTrigger
        analyticsActionRecord.sourceRef = sourceRef ?? ""
        analyticsActionRecord.sourceType = sourceType
        analyticsActionRecord.targetRef = targetRef ?? ""
        analyticsActionRecord.targetType = targetType
        
        AnalyticsManager.sharedManager.recordAction(analyticsActionRecord)
    }
    
    func trigger(atIndex index: Int) {
        if lastTriggerIndex == index {
            if let analyticsImpressionRecord = analyticsImpressionRecord {
                analyticsImpressionRecord.impressionKey = Utils.UUID()
                analyticsImpressionRecord.timestamp = Date()
                
                AnalyticsManager.sharedManager.recordImpression(analyticsImpressionRecord)
                
                analyticsImpressionKey = analyticsImpressionRecord.impressionKey
            }
        }
        
        lastTriggerIndex = index
    }
    
}
