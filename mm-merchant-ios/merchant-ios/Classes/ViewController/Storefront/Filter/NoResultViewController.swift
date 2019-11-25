//
//  NoResultViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 8/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
class NoResultViewController : MmViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(NoResultCell.self, forCellWithReuseIdentifier: "NoResultCell")
        collectionView.backgroundColor = UIColor.white
        self.view.addSubview(collectionView)
        createBackButton()
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoResultCell", for: indexPath) as! NoResultCell
        cell.label.text = String.localize("LB_CA_NO_PROD_RESULT_1")
        cell.lowerLabel.text = String.localize("LB_CA_NO_PROD_RESULT_2")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 80)
    }
    
}
