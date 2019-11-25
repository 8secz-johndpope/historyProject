//
//  TSChatViewControllerCellEnums.swift
//  TSWeChat
//
//  Created by Hilen on 1/11/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation


// MARK: - @extension 消息内容 cell 的扩展
extension MessageContentType {
    func chatCellHeight(_ model: ChatModel) -> CGFloat {
        switch self {
        case .Text :
            return TSChatTextCell.layoutHeight(model)
        case .Image :
            return TSChatImageCell.layoutHeight(model)
        case .Voice:
            return TSChatVoiceCell.layoutHeight(model)
        case .System:
            return TSChatSystemCell.layoutHeight(model)
        case .File:
            return 60
        case .Time :
            return TSChatTimeCell.heightForCell()
        case .Product,
             .ForwardProduct:
            return TSChatShareProductCell.layoutHeight(model)
        case .ShareUser:
            return TSShareUserCell.layoutHeight(model)
        case .ShareMerchant :
            return TSShareMerchantCell.layoutHeight(model)
        case .ShareBrand :
            return TSShareBrandCell.layoutHeight(model)
        case .ImageUUID,
            .ForwardImage:
            return TSChatImageCell.layoutHeight(model)
        case .VoiceUUID:
            return TSChatVoiceCell.layoutHeight(model)
        case .ShareOrder:
            return TSShareOrderCell.layoutHeight(model)
        case .LoadMore:
            return TSLoadMoreCell.layoutHeight(model)
        case .Comment,
             .ForwardDescription,
             .TransferComment:
            return TSChatCommentCell.layoutHeight(model)
        case .SharePost:
            return TSSharePostCell.layoutHeight(model)
        case .SharePage:
            return TSSharePageCell.layoutHeight(model)
        case .Coupon:
            return TSCouponCell.layoutHeight(model)
        case .Shipment:
            if TSShipmentImageCell.isShouldUsingShipmentImageCell(model){
                return TSShipmentImageCell.layoutHeight(model)
            }
            else {
                return TSShipmentCell.layoutHeight(model)
            }

        case .TransferRedirect:
            return TSChatTransferCell.layoutHeight(model)

        case .AutoRespond:
            return TSChatAutoRespondCell.layoutHeight(model)
        case .MasterCoupon:
            return TSMasterCouponCell.layoutHeight(model)
        }
    }

    func chatCell(_ tableView: UITableView, indexPath: IndexPath, model: ChatModel, viewController: TSChatViewController) -> UITableViewCell? {
        var isHideAvatar = false
        if indexPath.row > 1 {
            if model.chatSendId == viewController.itemDataSouce[indexPath.row - 1].chatSendId {
                isHideAvatar = true
            }
        }
        
        var referrerUserType = "User"
        var referrerUserRef: String?
        let referrerUser: User? = model.fromMe ? viewController.conv?.me : viewController.presenter
        if let user = referrerUser {
            referrerUserRef = user.userKey
            referrerUserType = user.userTypeString()
        }
        
        var positionLocation = "Chat-Customer"
        if let conv = viewController.conv {
            positionLocation = conv.chatTypeString()
        }
        
        switch self {
        case .Text :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatTextCell.identifier, for: indexPath) as! TSChatTextCell
            
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .Image :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatImageCell.identifier, for: indexPath) as! TSChatImageCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .Voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatVoiceCell.identifier, for: indexPath) as! TSChatVoiceCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .System:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatSystemCell.identifier, for: indexPath) as! TSChatSystemCell
            cell.setCellContent(model)

            return cell

        case .File:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatVoiceCell.identifier, for: indexPath) as! TSChatVoiceCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .Time :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatTimeCell.identifier, for: indexPath) as! TSChatTimeCell
            cell.setCellContent(model)
            return cell
            
        case .Product,
             .ForwardProduct:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatShareProductCell.identifier, for: indexPath) as! TSChatShareProductCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            
            // Impression tag - Product
            
            let impressionKey = viewController.recordImpression(
                impressionRef: model.productModel?.style?.styleCode,
                impressionType: "Product",
                impressionVariantRef: String(describing: model.productModel?.style?.defaultSku()?.skuId),
                impressionDisplayName: model.productModel?.style?.defaultSku()?.skuName,
                merchantCode: model.productModel?.style?.merchantCode,
                parentRef : model.messageId,
                parentType : "Message",
                positionComponent: "MessageFeeding",
                positionLocation: positionLocation,
                referrerRef: referrerUserRef,
                referrerType: referrerUserType
            )
            cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            return cell

        case .ShareUser :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSShareUserCell.identifier, for: indexPath) as! TSShareUserCell
            cell.delegate = viewController
            if let chatSendId = model.chatSendId {
                cell.targetUser = viewController.conv?.userForKey(chatSendId)
            }
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
        
            // Impression tag - ShareContact
            if let user =  model.userModel?.user {
                
                let impressionType = user.userTypeString()
                let impressionKey = viewController.recordImpression(
                    impressionRef: user.userKey,
                    impressionType: impressionType,
                    impressionDisplayName: user.displayName,
                    merchantCode: user.merchant.merchantCode,
                    parentRef : model.messageId,
                    parentType : "Message",
                    positionComponent: "MessageFeeding",
                    positionLocation: positionLocation,
                    referrerRef: referrerUserRef,
                    referrerType: referrerUserType
                )
                cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
            
            return cell

        case .ShareMerchant :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSShareMerchantCell.identifier, for: indexPath) as! TSShareMerchantCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            
            // Impression tag - Merchant
            if let merchant = model.merchantModel?.merchant {
                
                let impressionKey = viewController.recordImpression(
                    impressionRef: String(merchant.merchantId),
                    impressionType: "Merchant",
                    impressionDisplayName: merchant.merchantName,
                    merchantCode: merchant.merchantCode,
                    parentRef : model.messageId,
                    parentType : "Message",
                    positionLocation: positionLocation,
                    referrerRef: referrerUserRef,
                    referrerType: referrerUserType
                )
                cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
        
            return cell
            
        case .ShareBrand :
            let cell = tableView.dequeueReusableCell(withIdentifier: TSShareBrandCell.identifier, for: indexPath) as! TSShareBrandCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            
            // Impression tag - Brand
            if let brand = model.brandModel?.brand {
                
                let impressionKey = viewController.recordImpression(
                    brandCode: brand.brandCode,
                    impressionRef: String(brand.brandId),
                    impressionType: "Brand",
                    impressionDisplayName: brand.brandName,
                    parentRef : model.messageId,
                    parentType : "Message",
                    positionLocation: positionLocation,
                    referrerRef: referrerUserRef, referrerType: referrerUserType
                )
                cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
            
            return cell
            
        case .VoiceUUID:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatVoiceCell.identifier, for: indexPath) as! TSChatVoiceCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .ImageUUID,
             .ForwardImage:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatImageCell.identifier, for: indexPath) as! TSChatImageCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
            
        case .ShareOrder:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSShareOrderCell.identifier, for: indexPath) as! TSShareOrderCell
            cell.delegate = viewController
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell

        case .LoadMore:
            if model.needToLoadMore {
                model.needToLoadMore = false
                viewController.fetchMoreHistory { [weak viewController] (request, response) in
                    if let vc = viewController {
                        vc.handleIncomingHistory(request: request, response: response)
                    }
                }
            }
            return tableView.dequeueReusableCell(withIdentifier: TSLoadMoreCell.identifier, for: indexPath) as! TSLoadMoreCell
        
        case .Comment,
             .ForwardDescription,
             .TransferComment:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatCommentCell.identifier, for: indexPath) as! TSChatCommentCell
            if let chatSendId = model.chatSendId {
                cell.targetUser = viewController.conv?.userForKey(chatSendId)
                if let merchantId = viewController.conv?.merchantObject?.merchantId {
                    cell.merchantObject = viewController.conv?.merchantForId(merchantId)
                }
            }
            cell.setCellContent(model)
        
            return cell
        case .SharePost:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSSharePostCell.identifier, for: indexPath) as! TSSharePostCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            
            if let post = (model.model as? PostModel)?.post {
                var authorType = "User"
                if let user = post.user {
                    authorType = user.userTypeString()
                }
                // Impression tag - SharePost
                
                let impressionKey = viewController.recordImpression(
                    post.user?.userKey,
                    authorType: authorType,
                    impressionRef: String(post.postId),
                    impressionType: "Post",
                    merchantCode: post.merchant?.merchantCode,
                    parentRef : model.messageId,
                    parentType : "Message",
                    positionLocation: positionLocation,
                    referrerRef: referrerUserRef,
                    referrerType: referrerUserType
                )
                cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
            
            return cell
        case .SharePage:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSSharePageCell.identifier, for: indexPath) as! TSSharePageCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            return cell
        case .Coupon:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSCouponCell.identifier, for: indexPath) as! TSCouponCell
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar
            
            // Impression tag - Coupon
            if let coupon = (model.model as? CouponModel)?.coupon {
                
                let impressionKey = viewController.recordImpression(
                    impressionRef: model.couponCode,
                    impressionType: "Coupon",
                    impressionDisplayName: coupon.couponName,
                    merchantCode: coupon.merchantId != nil ? String(describing: coupon.merchantId) : nil,
                    parentRef : model.messageId,
                    parentType : "Message",
                    positionLocation: positionLocation,
                    referrerRef: referrerUserRef,
                    referrerType: referrerUserType
                )
                cell.initAnalytics(withViewKey: viewController.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }
            
            return cell
        case .Shipment:
            let cell:TSShipmentCell!
            if TSShipmentImageCell.isShouldUsingShipmentImageCell(model){
                cell = tableView.dequeueReusableCell(withIdentifier: TSShipmentImageCell.identifier, for: indexPath) as! TSShipmentImageCell
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: TSShipmentCell.identifier, for: indexPath) as! TSShipmentCell
            }
            cell.delegate = viewController
            cell.conv = viewController.conv
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = true
            cell.tag = indexPath.row
            return cell

        case .TransferRedirect:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatTransferCell.identifier, for: indexPath) as! TSChatTransferCell
            cell.delegate = viewController
            cell.setCellContent(model)
            
            return cell
            
        case .AutoRespond:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSChatAutoRespondCell.identifier, for: indexPath) as! TSChatAutoRespondCell
            cell.delegate = viewController
            cell.setCellContent(model)
            
            return cell
        case .MasterCoupon:
            let cell = tableView.dequeueReusableCell(withIdentifier: TSMasterCouponCell.identifier, for: indexPath) as! TSMasterCouponCell
            
            cell.delegate = viewController
            cell.targetUser = viewController.presenter
            cell.me = viewController.conv?.me
            cell.setCellContent(model)
            cell.avatarImageView.isHidden = isHideAvatar

            return cell
        }
    }
}
