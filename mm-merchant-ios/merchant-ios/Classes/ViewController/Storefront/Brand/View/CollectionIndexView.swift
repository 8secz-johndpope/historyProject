//
//  CollectionIndexView.swift
//  merchant-ios
//
//  Created by Jerry Chong on 22/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore


func _floor(_ x: CGFloat, scale: CGFloat) -> CGFloat {
    return floor(x * scale) / scale
}


func _round(_ x: CGFloat, scale: CGFloat) -> CGFloat {
    let temp : CGFloat = ((x * scale) / scale)
    let temp2 = round(temp)
    return CGFloat(temp2)
}


func _ceil(_ x: CGFloat, scale: CGFloat) -> CGFloat {
    return ceil(x * scale) / scale
}


func floorOdd(_ x: Int) -> Int {
    return x % 2 == 1 ? x : x - 1
}

open class CollectionViewIndex: UIControl {
    open var indexTitles = [String]() {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    var _selectedIndex: Int?
    open var selectedIndex: Int {
        return _selectedIndex ?? 0
    }
    
    let font = UIFont.boldSystemFont(ofSize: 11)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(white: 1, alpha: 0.9)
        contentMode = UIViewContentMode.redraw
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        
        setNeedsDisplay()
    }
    
    enum IndexEntry {
        case text(String)
        case bullet
    }
    
    var titleHeight: CGFloat {
        return font.lineHeight
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ceil = _ceil(CGFloat(titleHeight), scale: CGFloat(contentScaleFactor))
        let maxNumberOfIndexTitles = Int(floor(bounds.height / ceil))
        
        var indexEntries = [IndexEntry]()
        if indexTitles.count <= maxNumberOfIndexTitles {
            indexEntries = indexTitles.map { .text($0) }
        } else {
            let numberOfIndexTitles = max(3, floorOdd(maxNumberOfIndexTitles))
            
            indexEntries.append(.text(indexTitles[0]))
            
            for i in 1...(numberOfIndexTitles / 2) {
                indexEntries.append(.bullet)
                let a = CGFloat(i) / (CGFloat(numberOfIndexTitles / 2))
                let b = CGFloat(indexTitles.count - 1)

                var index = a * b
                index.round()
                
                indexEntries.append(.text(indexTitles[Int(index)]))
            }
        }
        
        let totalHeight = titleHeight * CGFloat(indexEntries.count)
        
        let context = UIGraphicsGetCurrentContext()! as CGContext
        tintColor.setFill()
        
        var y = (bounds.height - totalHeight) / 2
        for indexEntry in indexEntries {
            switch indexEntry {
            case .text(let indexTitle):
                let attributedString = attributedStringForTitle(indexTitle)
                let width = attributedString.size().width
                let a: CGFloat = CGFloat((bounds.width - width) / 2)
                let b: CGFloat = CGFloat(contentScaleFactor)
                
                let x = _round(a, scale: b)
                attributedString.draw(in: CGRect(x: x, y: _round(y, scale: CGFloat(contentScaleFactor)), width: width, height: titleHeight))
                
            case .bullet:
                let diameter: CGFloat = 6
                let a: CGFloat = CGFloat((bounds.width - width) / 2)
                let b: CGFloat = CGFloat(contentScaleFactor)

                let x = _round(a, scale: b)
                let top = _round(y + (titleHeight - diameter) / 2, scale: CGFloat(contentScaleFactor))
                context.fillEllipse(in: CGRect(x: x, y: top, width: diameter, height: diameter))
            }
            
            y += titleHeight
        }
    }
    
    func attributedStringForTitle(_ title: String) -> NSAttributedString {
        return NSAttributedString(string: title, attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.blue])
    }
    

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        let selectedIndex = indexForTouch(touch)
        if _selectedIndex != selectedIndex {
            _selectedIndex = selectedIndex
            sendActions(for: .valueChanged)
        }
        
        return true
    }
    
    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        let selectedIndex = indexForTouch(touch)
        if _selectedIndex != selectedIndex {
            _selectedIndex = selectedIndex
            sendActions(for: .valueChanged)
        }
        
        return true
    }

    
    func indexForTouch(_ touch: UITouch) -> Int {
        let maxNumberOfIndexTitles = Int(floor(bounds.height / _ceil(titleHeight, scale: contentScaleFactor)))
        
        let numberOfIndexTitles: Int
        if indexTitles.count <= maxNumberOfIndexTitles {
            numberOfIndexTitles = indexTitles.count
        } else {
            numberOfIndexTitles = max(3, floorOdd(maxNumberOfIndexTitles))
        }
        
        let totalHeight = titleHeight * CGFloat(numberOfIndexTitles)
        
        let location = touch.location(in: self)
        let index = Int((location.y - (bounds.height - totalHeight) / 2) / totalHeight * CGFloat(indexTitles.count))
        return max(0, min(indexTitles.count - 1, index))
    }
    
    open var preferredMaxLayoutHeight: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override open var intrinsicContentSize : CGSize {
        let _ = super.intrinsicContentSize
     
        return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: preferredMaxLayoutHeight))
    }
    
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxNumberOfIndexTitles = Int(floor(size.height / _ceil(titleHeight, scale: contentScaleFactor)))
        
        var indexEntries = [IndexEntry]()
        if indexTitles.count <= maxNumberOfIndexTitles {
            indexEntries = indexTitles.map { .text($0) }
        } else {
            let numberOfIndexTitles = max(3, floorOdd(maxNumberOfIndexTitles))
            
            indexEntries.append(.text(indexTitles[0]))
            
            for i in 1...(numberOfIndexTitles / 2) {
                indexEntries.append(.bullet)
                let roundFloat = (CGFloat(i) / (CGFloat(numberOfIndexTitles / 2)) * CGFloat(indexTitles.count - 1)).rounded()
                let index = Int(roundFloat)
                indexEntries.append(.text(indexTitles[index]))
            }
        }
        
        let width: CGFloat = indexEntries.reduce(0, { width, indexEntry in
            switch indexEntry {
            case .text(let indexTitle):
                return max(width, self.attributedStringForTitle(indexTitle).size().width)
            case .bullet:
                return width
            }
        })
        
        return CGSize(width: max(15, width + 4), height: size.height)
    }
    

    
}

