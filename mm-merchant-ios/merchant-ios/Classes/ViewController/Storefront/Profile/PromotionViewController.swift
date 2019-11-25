//
//  PromotionViewController.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PromotionViewController: MmViewController, PromotionCellDelegate {
    
    private var numberOfRows = 3
    private var cellHeight : CGFloat = 80
    let CellIdentifier = "CellIdentifier"
    let FooterIdentifier = "FooterIdentifier"
    let heightOfFooterView = CGFloat(65)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initUI()
    }
    
    func initUI() -> Void {
        self.createRightButton(String.localize("LB_CA_SAVE"), action: #selector(PromotionViewController.didSelectedRightButton))
        self.createBackButton()
        
        self.configCollectionView()
        
        var titleText = String.localize("LB_CA_CURATOR_PROFILE_RECOM")
        if titleText.range(of: "{0}") != nil {
            titleText = titleText.replacingOccurrences(of: "{0}", with: "")
        }
        self.title = titleText
        self.setupDismissKeyboardGesture()
    }
    
    @objc func didSelectedRightButton(_ id : Any?) -> Void {
        self.view.endEditing(true)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return true
    }
    
    func configCollectionView() -> Void {
        collectionView.register(PromotionCell.self, forCellWithReuseIdentifier: CellIdentifier)
        collectionView!.register(PromotionFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: FooterIdentifier)
        collectionView.isScrollEnabled = false
    }
    
    //MARK: -- Promotion Cell Delegate
    func promotionCellDidEndEditText(_ cell: PromotionCell, text: String) {
        
    }
    
    //MARK: -- CollectionView Protocol
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfRows
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? PromotionCell {
            cell.configCellAtIndexPath(indexPath)
            cell.delegate = self
            return cell
        }else {
            return UICollectionViewCell()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterIdentifier, for: indexPath) as! PromotionFooterView
        
        return footerView
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: heightOfFooterView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: cellHeight)
    }
    
}
