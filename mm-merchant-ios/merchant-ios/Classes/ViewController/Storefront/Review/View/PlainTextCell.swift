//
//  PlainTextCell.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class PlainTextCell: UICollectionViewCell {
    
    static let CellIdentifier = "PlainTextCellID"
    
    static let FontSize = 14
    static let ContainerHorizontalPadding: CGFloat = 10
    static let ContainerVerticalPadding: CGFloat = 10
    static let ContentPadding: CGFloat = 10
    
    final let PaddingContainerBottom: CGFloat = 15
    
    var containerView = UIView()
    var contentLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Prepare layout before set data - Remove this line will make the cell can't show content
        containerView.frame = CGRect(x: PlainTextCell.ContainerHorizontalPadding, y: PlainTextCell.ContainerVerticalPadding, width: frame.width - (PlainTextCell.ContainerHorizontalPadding * 2), height: frame.height - PaddingContainerBottom)
        containerView.layer.backgroundColor = UIColor.primary2().cgColor
        containerView.roundCorners([.topRight, .bottomLeft, .bottomRight], radius: 10)
        
        contentLabel.frame = CGRect(x: PlainTextCell.ContentPadding, y: PlainTextCell.ContentPadding, width: containerView.frame.sizeWidth - 2 * PlainTextCell.ContentPadding, height: containerView.frame.sizeHeight - 2 * PlainTextCell.ContentPadding)
        contentLabel.formatSize(PlainTextCell.FontSize)
        contentLabel.textColor = UIColor.grayTextColor()
        contentLabel.numberOfLines = 0
        containerView.addSubview(contentLabel)
        
        self.addSubview(containerView)
        
    }
    
    //MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.frame = CGRect(x: PlainTextCell.ContainerHorizontalPadding, y: PlainTextCell.ContainerVerticalPadding, width: frame.width - (PlainTextCell.ContainerHorizontalPadding * 2), height: frame.height - PaddingContainerBottom)
        
    }
    
    
    // MARK: - Size
    class func getSizeCell(text: String?, cellWidth: CGFloat) -> CGSize {
        
        if let text = text {
            let labelWidth = cellWidth - (PlainTextCell.ContainerHorizontalPadding + PlainTextCell.ContentPadding) * 2
            
            let labelHeight = StringHelper.heightForText(text, width: labelWidth, font: UIFont.systemFontWithSize(CGFloat(FontSize)))
            
            return CGSize(width: cellWidth, height: (PlainTextCell.ContainerHorizontalPadding + PlainTextCell.ContentPadding) * 2 + labelHeight)
        }
        
        return CGSize.zero
    }
}
