//
//  NameCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class NameCell : UICollectionViewCell{
    var logoImageView = UIImageView()
    var nameLabel = UILabel()
    var containerView = UIView()
    
    private static let HorizotalMargin:CGFloat = 10.0
    private final let ContainerViewTopPadding:CGFloat = 7.0
    
    private final let MarginTop : CGFloat = 25
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        addSubview(logoImageView)
        
        nameLabel.formatSmall()
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        containerView.addSubview(nameLabel)
        
        addSubview(containerView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        logoImageView.frame = CGRect(x: bounds.midX - Constants.Value.PdpBrandImageWidth / 2 , y: bounds.minY + MarginTop, width: Constants.Value.PdpBrandImageWidth, height: Constants.Value.PdpBrandImageHeight)
    }
    
    func setImage(_ imageKey: String, imageCategory: ImageCategory) {
        logoImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: imageCategory), placeholderImage: nil, contentMode: .scaleAspectFit)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCrossBorderLabel(){
        nameLabel.addImage("crossbroder")
        updateNameLabelFrame(isShowCrossBorder: true)
    }
    
    func hideCrossBorderLabel(){
        
        nameLabel.removeImage()
        updateNameLabelFrame(isShowCrossBorder: false)
    }
    
    func updateNameLabelFrame(isShowCrossBorder: Bool){
        
        let totalWidth = bounds.sizeWidth - 2 * NameCell.HorizotalMargin
        let nameLabelSize = NameCell.getSizeNameLabel(text: nameLabel.text, cellWidth: bounds.sizeWidth, isCrossBorder: isShowCrossBorder)
        self.containerView.frame = CGRect(x: NameCell.HorizotalMargin, y: logoImageView.frame.maxY + ContainerViewTopPadding, width: totalWidth, height: Constants.Value.PdpBrandImageHeight + nameLabelSize.height + 45) //45 is padding height
        nameLabel.frame = CGRect(x: 0, y: 0, width: totalWidth, height: nameLabelSize.height)
    }
    
    
    // MARK: - Size
    
    private class func getSizeNameLabel(text: String?, cellWidth: CGFloat, isCrossBorder: Bool) -> CGSize {
        if let text: String = text {
            let labelWidth = cellWidth - 2 * NameCell.HorizotalMargin
            let dummyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
            dummyLabel.formatSmall()
            dummyLabel.numberOfLines = 0
            dummyLabel.text = text
            if isCrossBorder {
                dummyLabel.addImage("crossbroder")
            }
            dummyLabel.sizeToFit()
            
            return dummyLabel.frame.size
        }
        
        return CGSize.zero
    }
    
    class func getSizeCell(text: String?, cellWidth: CGFloat, isCrossBorder: Bool) -> CGSize {
        let nameLabelSize = NameCell.getSizeNameLabel(text: text, cellWidth: cellWidth, isCrossBorder: isCrossBorder)
        return CGSize(width: cellWidth, height: Constants.Value.PdpBrandImageHeight + nameLabelSize.height + 45) //45 is padding height
    }
}
