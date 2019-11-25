//
//  SuggestCollectionViewDatasource.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol SuggestCollectionViewDatasourceDelegate : NSObjectProtocol{
    func didBuySuccess (_ parentOrder: ParentOrder)
}
class SuggestCollectionViewDatasource: NSObject, UICollectionViewDataSource {
    
    var post = Post()
    
    var referrerUserKey: String?
    
    weak var delegate: SuggestCollectionViewDatasourceDelegate?
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return post.skuList?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectCellId, for: indexPath) as! SuggestCollectionViewCell
        
        guard let skus = post.skuList else { return cell }
        
        cell.setupDataBySku(skus[indexPath.row])
        cell.sku = skus[indexPath.row]
        cell.referrerUserKey = self.referrerUserKey
        cell.didBuySuccess =  {(parentOrder) -> Void in
            if let parentOrder = parentOrder, let delegate = self.delegate{
                delegate.didBuySuccess(parentOrder)
            }
        }

		if let styles : [Style] = post.styles, styles.count > 0 {
			cell.style = styles.filter({ $0.styleCode == cell.sku?.styleCode }).first
		}
        
        cell.updateInactiveOrOutOfStockStatus()
        cell.nameLabel.removeImage()
        return cell
    }
    
}
