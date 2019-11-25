//
//  CirclePickerFlowLayout.swift
//  merchant-ios
//
//  Created by Tony Fung on 20/4/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//


import Foundation
import UIKit
class CirclePickerFlowLayout: UICollectionViewFlowLayout {

    lazy var inset: CGFloat = {
        return  (self.collectionView?.bounds.height ?? 0)  * 0.5
    }()
    
    var cellHeight = CGFloat(60)
    var spacingLine = CGFloat(40)
    
    override init() {
        super.init()
        
        self.itemSize = CGSize(width: 320, height: cellHeight)
        self.scrollDirection = .vertical
        self.minimumLineSpacing = spacingLine
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        print("shouldInvalidateLayoutForBoundsChange")
        return true
    }
    
    override func prepare() {
        //设置边距(让第一张图片与最后一张图片出现在最中央)
        self.sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        self.itemSize = CGSize(width: self.collectionView!.frame.width, height: cellHeight)
        let array = super.layoutAttributesForElements(in: rect)
        
        
        let visiableRect = CGRect(x: self.collectionView!.contentOffset.x, y: self.collectionView!.contentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height)
        
        let centerY = self.collectionView!.contentOffset.y + self.collectionView!.frame.size.height * 0.5;
        
        for attributes in array! {

            if !visiableRect.intersects(attributes.frame) {continue}
            
            let distance = centerY - attributes.center.y
            var distanceRatio = abs(distance) / (cellHeight * 1.6)
            if (distanceRatio > 1){
                distanceRatio = 1
            }
            let scale = 1 + (1 - distanceRatio)
            print(scale)
            
            //            attributes.transform = CGAffineTransformMakeScale(scale, scale)
            var frame = attributes.frame
            frame.size.width = frame.size.width
            frame.size.height = frame.size.height * scale
            frame.origin.y = attributes.frame.midY - frame.height/2
            if distanceRatio > 0 {
                frame.origin.y = frame.origin.y - (distanceRatio * 20 * (distance / abs(distance)))
            }
            attributes.frame = frame
            
        }
        
        return array
        
    }
    
    var currentSelectedIndex = 0
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        let lastRect = CGRect(x: proposedContentOffset.x, y: proposedContentOffset.y, width: self.collectionView!.frame.width, height: self.collectionView!.frame.height)
        //获得collectionVIew中央的X值(即显示在屏幕中央的X)
        let centerY = proposedContentOffset.y + self.collectionView!.frame.height * 0.5;
        //这个范围内所有的属性
        let array = self.layoutAttributesForElements(in: lastRect)
        
        //需要移动的距离
        
//        return CGPoint(x: proposedContentOffset.x, y: round(proposedContentOffset.y / 100) * 100)
        
        var adjustOffsetY = CGFloat(MAXFLOAT);
        for attri in array! {
            if abs(attri.center.y - centerY) < abs(adjustOffsetY) {
                adjustOffsetY = attri.center.y - centerY;
            }
        }
        
        print("targetContentOffsetForProposedContentOffset \(proposedContentOffset) \(adjustOffsetY)")
        
        
        return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + adjustOffsetY)
        
    }

}
