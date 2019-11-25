//
//  AgentChatViewController.swift
//  merchant-ios
//
//  Created by HungPM on 5/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AgentChatViewController: TSChatViewController {
    var showPopUp = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
                    
        self.setupActionBarForAgent()
        self.setupActionBarForAgentComment()
        
        updateShareMore()
        
        if showPopUp {
            showSuccessPopupWithText(String.localize("MSG_SUC_CS_FORWARD_CHAT"))
		}
        
    }
    
    func updateShareMore() {
        self.shareMoreView.isAgent = true
        self.shareMoreView.itemDataSouce = [
            (String.localize("LB_CA_IM_LIBRARY"), TSAsset.Sharemore_pic.image, "IM_UserChat-UIBT_IM_ATTACH_PHOTO_LIBRARY"),
            (String.localize("LB_CA_IM_CAMERA"), TSAsset.Sharemore_video.image, "IM_UserChat-UIBT_IM_ATTACH_PHOTO_CAMERA"),
            (String.localize("LB_PRODUCTS"), TSAsset.Sharemore_insert_product.image, "IM_UserChat-UIBT_IM_ATTACH_PROD"),
            (String.localize("LB_CA_CS_COMMENT"), TSAsset.Sharemore_drop_comment.image, "IM_UserChat-UIBT_IM_ATTACH_COMMENT")
        ]
        self.shareMoreView.reloadSource()
        self.shareMoreView.listCollectionView.reloadData()
    }
}
