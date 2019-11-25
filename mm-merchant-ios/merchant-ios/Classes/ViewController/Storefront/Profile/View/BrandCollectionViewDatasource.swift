//
//  BrandCollectionViewDatasource.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
let BrandCollectionCellId = "BrandLogoCollectionViewCell"
class BrandCollectionViewDatasource: NSObject, UICollectionViewDataSource {
    
    var brands = [Brand]()
    var merchants = [Merchant]()
    var users = [User]()
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  merchants.count + users.count + brands.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandCollectionCellId, for: indexPath) as! KeywordCell
        if indexPath.row <  merchants.count {
            cell.nameLabel.text = merchants[indexPath.row].merchantName
        } else {
            if indexPath.row < (merchants.count + users.count){
                let index = indexPath.row - merchants.count
                cell.nameLabel.text = users[index].displayName
            } else {
                let index = indexPath.row - (users.count + merchants.count)
                cell.nameLabel.text = brands[index].brandName
            }
        }
        cell.nameLabel.textColor = UIColor.secondary2()
        cell.viewBackground.layer.borderColor = UIColor.secondary1().cgColor
        cell.viewBackground.layer.cornerRadius = 3.0
        return cell
    }
}
