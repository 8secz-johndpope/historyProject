//
//  OrderBaseViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 6/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class OrderBaseViewController: MmViewController {
    
    final let DefaultCellID = "DefaultCellID"
    
    final let OrderStatusCellHeight: CGFloat = 64
    final let PaddingContent: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.omsBackground()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func contactCustomerServiceWithOrder(_ fromvc: UIViewController, order: Order, orderShipmentKey: String? = nil, viewMode: Constants.OmsViewMode? = nil) {
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartToCSMessage(userList: [myRole], queue: .Postsales, senderMerchantId: myRole.merchantId, merchantId: order.merchantId),
            checkNetwork: true,
            viewController: self,
            completion: { ack in
            if let convKey = ack.data {
                let viewController = UserChatViewController(convKey: convKey)

                let orderModel = OrderModel()
                orderModel.orderNumber = order.orderKey
                
                if let orderShipmentKey = orderShipmentKey {
                    orderModel.orderShipmentKey = orderShipmentKey
                    if let orderShipments = order.orderShipments, !orderShipments.isEmpty {
                        orderModel.orderType = .OrderShipment
                        orderModel.orderReferenceNumber = orderShipments[0].consignmentNumber
                    }
                }
                else if let viewmode = viewMode, viewmode == .all || viewmode == .unpaid{
                    orderModel.orderType = .Order
                }
                else if let viewmode = viewMode, (viewmode == .toBeShipped || viewmode == .toBeReceived) {
                    orderModel.orderType = .OrderShipment
                    if let orderShipments = order.orderShipments, !orderShipments.isEmpty {
                        orderModel.orderReferenceNumber = orderShipments[0].consignmentNumber
                    }
                }
                else if let orderReturns = order.orderReturns, !orderReturns.isEmpty {
                    orderModel.orderType = .OrderReturn
                    orderModel.orderReferenceNumber = orderReturns[0].orderReturnKey
                }
                else if let orderShipments = order.orderShipments, !orderShipments.isEmpty {
                    orderModel.orderType = .OrderShipment
                    orderModel.orderReferenceNumber = orderShipments[0].consignmentNumber
                }
                else {
                    orderModel.orderType = .Order
                }
                
                let chatModel = ChatModel(orderModel: orderModel)
                
                viewController.forwardChatModel = chatModel
                fromvc.navigationController?.pushViewController(viewController, animated: true)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        })
    }
    
    
    func contactCustomerServiceWithOrderKey(_ fromvc: UIViewController, order: ParentOrder, merchantId: Int) {
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        
        WebSocketManager.sharedInstance().sendMessage(
            IMConvStartToCSMessage(userList: [myRole], queue: .Postsales, senderMerchantId: myRole.merchantId, merchantId: merchantId),
            checkNetwork: true,
            viewController: self,
            completion: { ack in
                if let convKey = ack.data {
                    self.csSendMessage(order.parentOrderKey, convKey: convKey, myRole: myRole, fromvc:fromvc)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
        })
    }
    
    func csSendMessage(_ message: String, convKey: String, myRole: UserRole, fromvc: UIViewController){
        WebSocketManager.sharedInstance().sendMessage(
            IMTextMessage(text: message, convKey: convKey, myUserRole: myRole),
            completion: { (ack) in
                let userChatViewController = UserChatViewController(convKey: convKey)
                
                fromvc.navigationController?.isNavigationBarHidden = false
                fromvc.navigationController?.pushViewController(userChatViewController, animated: true)
            }
        )
    }
    
    func contactCustumerServiceWithText(_ fromvc: UIViewController, order: Order){
        
        let myRole: UserRole = UserRole(userKey: Context.getUserKey())
        
        WebSocketManager.sharedInstance().sendMessage(
            IMForwardDescriptionMessage(
                comment: order.orderKey,
                merchantId: order.merchantId,
                convKey: "",
                status: CommentStatus.Normal,
                forwardedMerchantId: order.merchantId,
                forwardedMerchantQueueName: QueueType.General,
                myUserRole: myRole
            ), completion: { ack in
                if let convKey = ack.data {
                    let viewController = UserChatViewController(convKey: convKey)
                    fromvc.navigationController?.pushViewController(viewController, animated: true)
                }
                
            }, failure: {
                
            }
        )
    }
    
    // MARK: - Data
    
    func confirmShipment(orderShipmentKey: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            ShipmentService.receive(orderShipmentKey: orderShipmentKey, completion: { response in
                let statusCode = response.response?.statusCode ?? 0
                
                if response.result.isSuccess {
                    if statusCode == 200 {
                        fulfill("OK")
                    } else {
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    //
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    // MARK: Collection View Delegate (Flow Layout) methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

}
