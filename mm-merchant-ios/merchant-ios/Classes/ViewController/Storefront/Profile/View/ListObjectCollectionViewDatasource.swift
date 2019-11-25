//
//  ListObjectCollectionViewDatasource.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
let ObjectCollectionViewId = "ObjectCollectionView"
class ListObjectCollectionViewDatasource: NSObject, UICollectionViewDataSource {

    var data = [User]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ObjectCollectionViewId, for: indexPath) as! ObjectCollectionView
            cell.setupDataByUser(data[indexPath.row])
        return cell
    }

}
