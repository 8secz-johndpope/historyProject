//
//  DoubleSnapFlowLayout.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 7/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class DoubleSnapFlowLayout : UICollectionViewFlowLayout {
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var _proposedContentOffset = CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y)
        var offSetAdjustment: CGFloat = CGFloat.greatestFiniteMagnitude
        let horizontalCenter: CGFloat = CGFloat(proposedContentOffset.x + (self.collectionView!.bounds.size.width / 4.0))
        
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0.0, width: self.collectionView!.bounds.size.width, height: self.collectionView!.bounds.size.height)
        
        let array: [UICollectionViewLayoutAttributes] = self.layoutAttributesForElements(in: targetRect)! as [UICollectionViewLayoutAttributes]
        for layoutAttributes: UICollectionViewLayoutAttributes in array {
            if (layoutAttributes.representedElementCategory == UICollectionElementCategory.cell) {
                let itemHorizontalCenter: CGFloat = layoutAttributes.center.x
                if (abs(itemHorizontalCenter - horizontalCenter) < abs(offSetAdjustment)) {
                    offSetAdjustment = itemHorizontalCenter - horizontalCenter
                }
            }
        }
        
        var nextOffset: CGFloat = proposedContentOffset.x + offSetAdjustment
        
        repeat {
            _proposedContentOffset.x = nextOffset
            let deltaX = proposedContentOffset.x - self.collectionView!.contentOffset.x
            let velX = velocity.x
            
            if (deltaX == 0.0 || velX == 0 || (velX > 0.0 && deltaX > 0.0) || (velX < 0.0 && deltaX < 0.0)) {
                break
            }
            
            if (velocity.x > 0.0) {
                nextOffset = nextOffset + self.snapStep()
            } else if (velocity.x < 0.0) {
                nextOffset = nextOffset - self.snapStep()
            }
        } while self.isValidOffset(nextOffset)
        
        _proposedContentOffset.y = 0.0
        
        return _proposedContentOffset
    }
    
    func isValidOffset(_ offset: CGFloat) -> Bool {
        return (offset >= CGFloat(self.minContentOffset()) && offset <= CGFloat(self.maxContentOffset()))
    }
    
    func minContentOffset() -> CGFloat {
        return -CGFloat(self.collectionView!.contentInset.left)
    }
    
    func maxContentOffset() -> CGFloat {
        return CGFloat(self.minContentOffset() + self.collectionView!.contentSize.width - self.itemSize.width)
    }
    
    func snapStep() -> CGFloat {
        return self.itemSize.width + self.minimumLineSpacing;
    }
}
