//
//  TSChatListPredefinedMessage.swift
//  merchant-ios
//
//  Created by HungPM on 5/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

// MARK: - @Delgate ChatPredefinedMessageDelegate
protocol ChatPredefinedMessageDelegate: class {
//    func messageDidPick(message: String, image: UIImage?)
    func messageDidPick(_ message: String)
}

class TSChatListPredefinedMessage: UIView {
    
    weak var delegate: ChatPredefinedMessageDelegate?
    
    var conv: Conv? {
        didSet {
            if let conv = self.conv, conv.merchantObject != nil {
                
                firstly {
                    return self.listAnswer(conv.merchantObject!.merchantId)
                    }.then { _ -> Void in
                        self.collectionView.reloadData()
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var answerList = [PredefinedAnswer]()
    
    override func awakeFromNib() {
        
        self.collectionView.register(TSChatListPredefinedMessageCollectionViewCell.NibObject(), forCellWithReuseIdentifier: TSChatListPredefinedMessageCollectionViewCell.identifier)
        collectionView.backgroundColor = UIColor.white

    }
    
    
    func listAnswer(_ merchantId: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            MerchService.listAnswer(merchantId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    
                if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            if let answerList: Array<PredefinedAnswer> = Mapper<PredefinedAnswer>().mapArray(JSONObject: response.result.value) {
                                strongSelf.answerList = answerList
                            } else {
                                strongSelf.answerList = [PredefinedAnswer]()
                            }
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
                })
        }
    }
}


// MARK: - @protocol UICollectionViewDelegate
extension TSChatListPredefinedMessage: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! TSChatListPredefinedMessageCollectionViewCell
        
        cell.analyticsViewKey = self.analyticsViewKey
        cell.analyticsImpressionKey = self.analyticsImpressionKey
        
        var targetType:  AnalyticsActionRecord.ActionElement = .ChatCustomer
        if let conv = self.conv {
            if  conv.isFriendChat() {
                targetType = .ChatFriend
            } else if conv.isInternalChat() {
                targetType = .ChatInternal
            }
            // Action tag
            cell.recordAction(
                .Send,
                sourceRef: String(answerList[indexPath.row].merchanAnswerId),
                sourceType: .MessagePreDefined,
                targetRef: conv.convKey,
                targetType: targetType
            )
        }
        
//        delegate?.messageDidPick(answerList[indexPath.row].description, image: cell.imageView.image)
        delegate?.messageDidPick(answerList[indexPath.row].description)
    }
}


// MARK: - @protocol UICollectionViewDataSource
extension TSChatListPredefinedMessage: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return answerList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TSChatListPredefinedMessageCollectionViewCell.identifier, for: indexPath) as! TSChatListPredefinedMessageCollectionViewCell
    
        cell.messageLabel.text = answerList[indexPath.row].merchantAnswerName
//        let imageKey = answerList[indexPath.row].image
//        if imageKey != "" {
//            cell.imageView.ts_setImageWithURLString(MediaService.viewImage(imageKey))
//        }
//        else {
//            cell.imageView.image = nil
//        }
        
        return cell
    }
}

// MARK: - @protocol UICollectionViewDelegateFlowLayout
extension TSChatListPredefinedMessage: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cell = TSChatListPredefinedMessageCollectionViewCell.fromNib() {
            
            cell.messageLabel.text = answerList[indexPath.row].merchantAnswerName
//            let imageKey = answerList[indexPath.row].image
//            if imageKey != "" {
//                cell.imageView.ts_setImageWithURLString(imageKey)
//            }
//            else {
//                cell.imageView.image = nil
//            }
            
            return cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
