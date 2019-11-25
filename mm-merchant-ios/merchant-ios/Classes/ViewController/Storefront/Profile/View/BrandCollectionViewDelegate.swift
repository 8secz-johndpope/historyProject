//
//  BrandCollectionViewDelegate.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol BrandCollectionDelegate : NSObjectProtocol{
    func didSelectBrandAtIndexPath (_ indexPath: IndexPath)
}
private let sectionInsets = UIEdgeInsets(top: 0.0, left: Constants.Margin.Left, bottom: 0.0, right: 0.0)

class BrandCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var brands = [Brand]()
    var merchants = [Merchant]()
    var users = [User]()
    private var labelName : UILabel?
    weak var delegate : BrandCollectionDelegate?
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Log.debug("cell no: \(indexPath.row) of collection view: \(collectionView.tag)")
        self.delegate?.didSelectBrandAtIndexPath(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var text = ""
        if indexPath.row <  merchants.count {
            text = merchants[indexPath.row].merchantName
        } else {
            if indexPath.row < (merchants.count + users.count){
                let index = indexPath.row - merchants.count
                text = users[index].displayName
            } else {
                let index = indexPath.row - (users.count + merchants.count)
                text = brands[index].brandName
            }
        }

        return CGSize(width: self.getTextWidth(text), height: ViewDefaultHeight.HeightBrandCV )
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 13
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    
    func getTextWidth(_ text: String) -> CGFloat {
        
        if self.labelName == nil {
            self.labelName = UILabel()
            self.labelName?.formatSize(13)
        }
        if let font  = self.labelName?.font {
            let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: ViewDefaultHeight.HeightBrandCV)
            let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
            return boundingBox.width + 28
        }
        return 40
    }
}
