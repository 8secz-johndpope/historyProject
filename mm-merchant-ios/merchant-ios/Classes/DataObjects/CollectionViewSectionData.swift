//
//  CollectionViewSectionData.swift
//  merchant-ios
//
//  Created by Alan YU on 6/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CollectionViewSectionData {
    
    fileprivate(set) var sectionHeader: Any?
    fileprivate(set) var sectionFooter: Any?
    var dataSource: [Any]
    var currentViewMode: Constants.OmsViewMode = .unknown
    fileprivate(set) var reuseIdentifier: String
    
    convenience init(sectionHeader: Any? = nil, sectionFooter: Any? = nil, reuseIdentifier: String, dataSource: [Any]) {

        self.init(sectionHeader: sectionHeader, sectionFooter: sectionFooter, reuseIdentifier: reuseIdentifier, dataSource: dataSource, viewMode: .unknown)

    }
    
    //To track current view mode of current order management
    init(sectionHeader: Any? = nil, sectionFooter: Any? = nil, reuseIdentifier: String, dataSource: [Any], viewMode: Constants.OmsViewMode) {
        self.sectionHeader = sectionHeader
        self.sectionFooter = sectionFooter
        self.dataSource = dataSource
        self.reuseIdentifier = reuseIdentifier
        self.currentViewMode = viewMode
    }
}
