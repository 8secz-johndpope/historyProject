//
//  PinterestLayout.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 9/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
@objc
protocol PinterestLayoutDelegate: NSObjectProtocol {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    @objc optional func collectionView(_ collectionView: UICollectionView, padingOfSection section: Int) -> CGFloat
    
    //Return 0 if you don't want to apply pinteres layout for specific section
    @objc optional func collectionView(_ collectionView: UICollectionView, numberOfColumnsInSection section: Int) -> Int
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtSection section: Int) -> UIEdgeInsets
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    
    @objc optional func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize
}
class PinterestLayout : UICollectionViewFlowLayout {
    weak var delegate: PinterestLayoutDelegate!
    var extraContentHeight: CGFloat = 0 //we will increase more height for avoiding tabbar overlay
    private var cache = [UICollectionViewLayoutAttributes]()
    private var contentHeight: CGFloat  = 0.0
    private var contentWidth: CGFloat {
        if let collectionView = self.collectionView {
            return collectionView.bounds.width
        }
        return 0
    }
    
    override class var layoutAttributesClass : AnyClass {
        return UICollectionViewLayoutAttributes.self
    }
    
    override func prepare() {
        contentHeight = 0
        if let collectionView = self.collectionView {
            cache.removeAll()
            let numberOfSection = collectionView.numberOfSections
            var repeatedValue : CGFloat = 0
            for section in 0 ..< numberOfSection {
                let edgeInset : UIEdgeInsets = self.delegate.collectionView?(collectionView, layout: self, insetForSectionAtSection: section) ?? UIEdgeInsets.zero
                let numberOfColumnsInSection = self.delegate.collectionView?(collectionView, numberOfColumnsInSection: section) ?? 0
                
                let minimumLineSpacing = self.delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAtIndex: section) ?? 0
                let minimumInteritemSpacing = self.delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAtIndex: section) ?? 0
                
                let cellPadding: CGFloat = self.delegate.collectionView?(collectionView, padingOfSection: section) ?? 0
                
                //Header height and attributes
                contentHeight = contentHeight + edgeInset.top
                let sizeHeader = self.delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section)
                let sizeHeaderHeight: CGFloat = (sizeHeader != nil) ? sizeHeader!.height : 0
                if sizeHeaderHeight > 0 {
                    let frameHeader = CGRect(x: 0, y: contentHeight, width: sizeHeader!.width, height: sizeHeaderHeight)
                    let insetFrame = frameHeader.insetBy(dx: 0, dy: 0)
                    let headerAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: IndexPath(item: 0, section: section) )
                    headerAttribute.frame = insetFrame
                    cache.append(headerAttribute)
                    contentHeight = frameHeader.maxY
                }
                
                repeatedValue = contentHeight
                
                if numberOfColumnsInSection <= 0 {
                    
                    //tracking columns and rows
                    var column = 0
                    var row = 0
                    
                    var xOffset = edgeInset.left
                    var yOffset = repeatedValue
                    
                    let numberOfItemsInSection = collectionView.numberOfItems(inSection: section)
                    
                    for item in 0 ..< numberOfItemsInSection {
                        let indexPath = IndexPath(item: item, section: section)
                        let size = self.delegate.collectionView(collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
                        let height = cellPadding +  size.height + cellPadding
                        let frame = CGRect(x: xOffset, y: yOffset, width: size.width, height: height)
                        // Creates an UICollectionViewLayoutItem with the frame and add it to the cache
                        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                        
                        attributes.frame = frame
                        cache.append(attributes)
                        
                        //Increase column
                        column += 1
                        xOffset = edgeInset.left + CGFloat(column) * minimumLineSpacing + CGFloat(column) * size.width + CGFloat(column) * minimumInteritemSpacing
                        
                        //Reset comlumn if cell outside collectionview
                        if xOffset + size.width >= contentWidth {
                            xOffset = edgeInset.left
                            row += 1
                            column = 0
                            yOffset = yOffset + size.height +  minimumInteritemSpacing
                        }
                        
                        // Updates the collection view content height
                        contentHeight = max(contentHeight, frame.maxY)
                        repeatedValue = contentHeight
                    }
                    
                } else {
                    
                    let columnWidth = (contentWidth - (edgeInset.left + edgeInset.right + (CGFloat(numberOfColumnsInSection) - 1) * minimumLineSpacing)) / CGFloat(numberOfColumnsInSection)
                    
                    var xOffset = [CGFloat]()
                    
                    for column in 0 ..< numberOfColumnsInSection {
                        xOffset.append(edgeInset.left + CGFloat(column) * minimumLineSpacing + CGFloat(column) * columnWidth)
                    }
                    var column = 0
                    var yOffset = [CGFloat](repeating: repeatedValue, count: numberOfColumnsInSection)
                    
                    let numberOfItemsInSection = collectionView.numberOfItems(inSection: section)
                    
                    for item in 0 ..< numberOfItemsInSection {
                        let indexPath = IndexPath(item: item, section: section)
                        let size = self.delegate.collectionView(collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
                        let height = cellPadding + size.height + cellPadding
                        let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                        let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                        // Creates an UICollectionViewLayoutItem with the frame and add it to the cache
                        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                        
                        attributes.frame = insetFrame
                        cache.append(attributes)
                        
                        
                        
                        yOffset[column] = yOffset[column] + height +  minimumInteritemSpacing
//                        column = column >= (numberOfColumnsInSection - 1) ? 0 : column + 1
                        column = minOffsetYColumn(offsets:yOffset)
                        
                        // Updates the collection view content height
                        repeatedValue = max(repeatedValue, frame.maxY)
                        contentHeight = max(contentHeight, repeatedValue)
                    }
                    
                }
                
                //Footer height
                let sizeFooter = self.delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section)
                let sizeFooterHeight: CGFloat = (sizeFooter != nil) ? sizeFooter!.height : 0
                if sizeFooterHeight > 0 {
                    let frameFooter = CGRect(x: 0, y: contentHeight, width: sizeFooter!.width, height: sizeFooterHeight)
                    let fotterAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: IndexPath(item: 0, section: section))
                    fotterAttribute.frame = frameFooter
                    cache.append(fotterAttribute)
                    contentHeight = contentHeight + sizeFooterHeight
                }
                contentHeight = contentHeight + edgeInset.bottom
                repeatedValue = contentHeight
            }
            
        }
        
    }
    
    private func minOffsetYColumn(offsets:[CGFloat]) -> Int {
        var minIdx = 0
        for idx in 0..<offsets.count {
            if offsets[minIdx] > offsets[idx] {
                minIdx = idx
            }
        }
        return minIdx
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var morelayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                morelayoutAttributes.append(attributes)
            }
        }
        return morelayoutAttributes
    }
    
    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight + extraContentHeight)
    }
}


