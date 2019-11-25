//
//  ListObjectCollectionViewDelegate.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol ListObjectCollectionDelegate : NSObjectProtocol{
    func didSelectUserAtIndexPath (_ indexPath: IndexPath, isLike: Bool)
}
private let sectionInsets = UIEdgeInsets(top: 0.0, left: Constants.Margin.Left, bottom: 0.0, right: 0.0)
private let widthCell = CGFloat(32)

class ListObjectCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    weak var delegate : ListObjectCollectionDelegate?
    var  isLikeDelegate = false;
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Log.debug("cell no: \(indexPath.row) of collection view: \(collectionView.tag)")
        self.delegate?.didSelectUserAtIndexPath(indexPath, isLike: self.isLikeDelegate)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: 32, height: 32)
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if self.isLikeDelegate {
            
            let cellCount = CGFloat(collectionView.numberOfItems(inSection: section))
            
            if cellCount > 0 {
                let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
                let totalCellWidth = widthCell * cellCount + flowLayout.minimumInteritemSpacing
                let contentWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right
                
                if (totalCellWidth < contentWidth) {
                    let padding = (contentWidth - totalCellWidth) / 2.0
                    return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
                }
            }
        }

        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Constants.LineSpacing.ImageCell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        return CGSize(width: 0,height: 0)
    }

}
