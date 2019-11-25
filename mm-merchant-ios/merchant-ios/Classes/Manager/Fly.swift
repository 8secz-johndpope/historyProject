//
//  Fly.swift
//  storefront-ios
//
//  Created by lingminjun on 2018/5/7.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import HandyJSON

/**
 @brief 所有LP热数据（喜欢+阅读数）管理，LP指magazine和cms单页
 */
class Fly {
    
    class PageHotData: FlyModel,HandyJSON {
        var data_unique_id: String {
            return pageKey
        }
        
        var data_sync_flag: Int64 = 0
        var pageKey:String = ""
        var isLike:Bool = false
        //        var likeCount:Int = 0
        
        required init() {
            //
        }
    }
    
    private class PageLikeRemoteAccessor : FlyRemoteAccessor {
        func remote_get(dataId: String) -> FlyModel? {
            
            //未登录不发起请求
            if !LoginManager.isValidUser() {
                return nil
            }
            
            let success:(_ value: [String]) -> Void = { (list) in
                let hotData = PageHotData()
                hotData.pageKey = dataId
                if  list.count > 0 {
                    hotData.isLike = true
                }
                Fly.page.save(hotData)
            }
            MagazineService.viewLikeContentPageListByUserKey(pageKeys: [dataId], success: success)
            // alamofire 不支持同步
            return nil
        }
    }
    
    public static let store = FlyweightStore<PageHotData>(scope: "page")
    public static let page: Flyweight<PageHotData> = Flyweight<PageHotData>(capacity: 200, psstn:store, remote: PageLikeRemoteAccessor(), flag: Int64(UserDefaults.standard.integer(forKey: ".app.start.times")))
    
}
