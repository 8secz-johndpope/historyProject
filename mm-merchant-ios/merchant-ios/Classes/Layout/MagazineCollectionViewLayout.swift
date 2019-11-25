//
//  UltravisualLayout.swift
//  RWDevCon
//
//  Created by Mic Pringle on 27/02/2015.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//
//  MagazineCollectionViewLayout.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/16/16.
//  Copyright © 2016 Quang Truong Dinh. All rights reserved.
//

import UIKit

/* The heights are declared as constants outside of the class so they can be easily referenced elsewhere */
struct MagazineCollectionViewLayoutConstants {
    struct Cell {
        /* The height of the non-featured cell */
        static let standardHeight: CGFloat = UIScreen.main.bounds.width / 4
        /* The height of the first visible cell */
        static let featuredHeight: CGFloat = UIScreen.main.bounds.width*485/500
    }
}

class MagazineCollectionViewLayout: UICollectionViewLayout {
    
    // MARK: Properties and Variables
    
    /* The amount the user needs to scroll before the featured cell changes */
    let dragOffset: CGFloat = 414.0
    
    var cache = [UICollectionViewLayoutAttributes]()
    
    var numberOfFixedItems = 0
    
    /* Returns the item index of the currently featured cell */
    var featuredItemIndex: Int {
        get {
            /* Use max to make sure the featureItemIndex is never < 0 */
            return min(max(0, Int(collectionView!.contentOffset.y / dragOffset)), numberOfItems - numberOfFixedItems)
        }
    }
    
    /* Returns a value between 0 and 1 that represents how close the next cell is to becoming the featured cell */
    var nextItemPercentageOffset: CGFloat {
        get {
            return (collectionView!.contentOffset.y / dragOffset) - CGFloat(featuredItemIndex)
        }
    }
    
    /* Returns the width of the collection view */
    var width: CGFloat {
        get {
            return collectionView!.bounds.width
        }
    }
    
    /* Returns the height of the collection view */
    var height: CGFloat {
        get {
            return collectionView!.bounds.height
        }
    }
    
    /* Returns the number of items in the collection view */
    var numberOfItems: Int {
        get {
            return collectionView!.numberOfItems(inSection: 0)
        }
    }
    
    // MARK: UICollectionViewLayout
    
    /* Return the size of all the content in the collection view */
    override var collectionViewContentSize : CGSize {
        let contentHeight = (CGFloat(numberOfItems - numberOfFixedItems) * dragOffset) + (height - dragOffset)
        return CGSize(width: width, height: contentHeight)
    }
    
    override func prepare() {
        cache.removeAll(keepingCapacity: false)
        
        let standardHeight = MagazineCollectionViewLayoutConstants.Cell.standardHeight
        let featuredHeight = MagazineCollectionViewLayoutConstants.Cell.featuredHeight
        
        var frame = CGRect.zero
        var y: CGFloat = 0

        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            /* Important because each cell has to slide over the top of the previous one */
            attributes.zIndex = item
            /* Initially set the height of the cell to the standard height */
            var height = standardHeight
            
            if indexPath.item == featuredItemIndex {
                /* The featured cell */
                
                let yOffset = standardHeight * nextItemPercentageOffset
                y = collectionView!.contentOffset.y - yOffset - max((featuredHeight - standardHeight) * nextItemPercentageOffset, 0)
                height = featuredHeight
                
                frame = CGRect(x: 0, y: y, width: width, height: height)
                attributes.frame = frame
                cache.append(attributes)
                
                y = collectionView!.contentOffset.y - yOffset
                let frame1 = CGRect(x: 0, y: y, width: width, height: height)
                y = frame1.maxY
                
                continue
            } else if indexPath.item == (featuredItemIndex + 1) && indexPath.item != numberOfItems {
                /* The cell directly below the featured cell, which grows as the user scrolls */
                
                if indexPath.item < (numberOfItems - numberOfFixedItems) {
                    height = standardHeight + max((featuredHeight - standardHeight) * nextItemPercentageOffset, 0)
                }
                
                y = y - max((featuredHeight - standardHeight) * nextItemPercentageOffset, 0)//maxY - height
            }
            
            frame = CGRect(x: 0, y: y, width: width, height: height)
            attributes.frame = frame
            
            cache.append(attributes)
            y = frame.maxY
        }
    }
    
    /* Return all attributes in the cache whose frame intersects with the rect passed to the method */
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
    
    /* Return the content offset of the nearest cell which achieves the nice snapping effect, similar to a paged UIScrollView */
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let itemIndex = round(proposedContentOffset.y / dragOffset)
        let yOffset = itemIndex * dragOffset
        return CGPoint(x: 0, y: yOffset)
    }
    
    /* Return true so that the layout is continuously invalidated as the user scrolls */
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
}
