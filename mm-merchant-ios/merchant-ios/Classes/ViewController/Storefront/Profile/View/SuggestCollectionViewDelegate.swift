//
//  SuggestCollectionViewDelegate.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
private let sectionInsets = UIEdgeInsets(top: 0, left: Constants.Margin.Left, bottom: 0.0, right: Constants.Margin.Right)

protocol SuggestCollectionDelegate : NSObjectProtocol{
    func didSelectSkuAtIndexPath (_ indexPath: IndexPath)
}
class SuggestCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    weak var delegate : SuggestCollectionDelegate?
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Log.debug("cell no: \(indexPath.row) of collection view: \(collectionView.tag)")
        self.delegate?.didSelectSkuAtIndexPath(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.getSuggestionCellWidth()
        let height = width * Constants.Ratio.ProductImageHeight + 48 //40 + 20 + 7 + 4
        return CGSize(width: width, height: height)
    }
    func getSuggestionCellWidth() -> CGFloat {
        return (Constants.ScreenSize.SCREEN_WIDTH - (Constants.Margin.Left + Constants.Margin.Right + Constants.LineSpacing.ImageCell * 2)) / 3
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
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
