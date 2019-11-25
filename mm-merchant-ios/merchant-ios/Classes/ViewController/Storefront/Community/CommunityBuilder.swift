//
//  CommunityBuilder.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/3.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CommunityBuilder {
    static func buiderFeedCellModel(_ response:NewsFeedListResponse) ->  [MMCellModel] {
        var list = [MMCellModel]()

        if let pageData = response.pageData,pageData.count > 0{
            for post in pageData {
                let cellModel = CMSPageNewsfeedPostCellModel()
                cellModel.supportMagicEdge = 15
                let dataModel = CMSPageDataModel()
                dataModel.dType = .POST
                dataModel.imageUrl = post.postImage
                dataModel.content = post.postText
                dataModel.post = post
                cellModel.data = dataModel
                list.append(cellModel)
            }
        }
        return list
    }
    static func buiderUserCellModel() ->  [MMCellModel] {
        var list = [MMCellModel]()
        let cellModel = CommunityUserCellModel()
        var userList = [User]()
        for _ in 0..<10 {
            userList.append(Context.getUserProfile())
        }
        cellModel.userList = userList
        list.append(cellModel)
        
        let bottomModel = CMSPageBottomCellModel()
        bottomModel.cellHeight = 10
        bottomModel.backgroundColor = .gray
        bottomModel.isExclusiveLine = true
        list.append(bottomModel)
        return list
    }
    static func buiderTagCellModel() ->  MMCellModel {
        let cellModel = CommunityTagCellModel()
        return cellModel
    }
}
