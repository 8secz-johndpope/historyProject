//
//  DBUtil.swift
//  storefront-ios
//
//  Created by lingminjun on 2018/7/27.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

/// 获取当前用户下的db和table
public final class DBUtil {
    
    /// 全部数据
    public static func globaldb() -> DB {
        let db = DB.db(with: "guest")
        return db
    }
    
    /// 全部数据
    public static func globaltable(_ table:String, template:String = "") -> DBTable {
        let db = DB.db(with: "guest")
        let tb = DBTable.table(db: db, name: table, template: template)
        return tb
    }
    
    /// 当前用户数据
    public static func db() -> DB {
        if LoginManager.getLoginState() == .validUser {
            let db = DB.db(with: "\(Context.getUserId())")
            return db
        } else {
            let db = DB.db(with: "guest")
            return db
        }
    }
    
    /// 当前用户数据
    public static func table(_ table:String, template:String = "") -> DBTable {
        if LoginManager.getLoginState() == .validUser {
            let db = DB.db(with: "\(Context.getUserId())")
            let tb = DBTable.table(db: db, name: table, template: template)
            return tb
        } else {
            let db = DB.db(with: "guest")
            let tb = DBTable.table(db: db, name: table, template: template)
            return tb
        }
    }
}
