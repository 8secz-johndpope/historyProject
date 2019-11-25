//
//  CheckoutFullAddressCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/12/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CheckoutFullAddressCell: UICollectionViewCell {
    
    static let CellIdentifier = "CheckoutFullAddressCellID"
    
    private static let TopPaddingForErrorMessage: CGFloat = 10
    private static let BottomPadding: CGFloat = 0
    
    private static let ArrowRightMargin: CGFloat = 17
    private static let ArrowWidth: CGFloat = 32
    private static let PaddingLeft: CGFloat = 17
    private static let BasicLabelHeight: CGFloat = 14
    private static let MaxLineOfAddress: CGFloat = 3
    
    private static let VerticalPaddingBetweenLabels: CGFloat = 6
    
    private var nameLabel: UILabel!
    private var addressLabel: UILabel!
    
    private var viewTopBackgroundGray: UIView!
    private var viewBottomBackgroundGray: UIView!
    private var arrowImageView: UIImageView!
    private var borderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        viewTopBackgroundGray = UIView()
        viewTopBackgroundGray.backgroundColor = UIColor.backgroundGray()
        addSubview(viewTopBackgroundGray)
        
        nameLabel = UILabel()
        nameLabel.textColor = UIColor.blackTitleColor()
        nameLabel.formatSmall()
        addSubview(nameLabel)
        
        addressLabel = UILabel()
        addressLabel.textColor = UIColor.blackTitleColor()
        addressLabel.formatSmall()
        addressLabel.lineBreakMode = .byTruncatingTail
        addressLabel.numberOfLines = 0
        addSubview(addressLabel)
        
        arrowImageView = UIImageView(image: UIImage(named: "icon_arrow_small"))
        arrowImageView.contentMode = .scaleAspectFit
        addSubview(arrowImageView)
        
        viewBottomBackgroundGray = UIView()
        viewBottomBackgroundGray.backgroundColor = UIColor.backgroundGray()
        addSubview(viewBottomBackgroundGray)
        
        borderView.backgroundColor = UIColor.secondary1()
        borderView.isHidden = true
        addSubview(borderView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelWidth = self.width - CheckoutFullAddressCell.PaddingLeft - CheckoutFullAddressCell.ArrowWidth - CheckoutFullAddressCell.ArrowRightMargin
        
        viewTopBackgroundGray.frame = CGRect(x: 0, y: 0, width: self.width, height: CheckoutFullAddressCell.TopPaddingForErrorMessage)
        viewBottomBackgroundGray.frame = CGRect(x: 0, y: self.height - CheckoutFullAddressCell.BottomPadding, width: self.width, height: CheckoutFullAddressCell.BottomPadding)
        
        let contentViewHeight = self.height - CheckoutFullAddressCell.TopPaddingForErrorMessage - CheckoutFullAddressCell.BottomPadding
        arrowImageView.frame = CGRect(x: self.width - CheckoutFullAddressCell.ArrowWidth - CheckoutFullAddressCell.ArrowRightMargin, y: CheckoutFullAddressCell.TopPaddingForErrorMessage + (contentViewHeight - CheckoutFullAddressCell.ArrowWidth) / 2, width: CheckoutFullAddressCell.ArrowWidth, height: CheckoutFullAddressCell.ArrowWidth)
        
        let nameLabelY = viewTopBackgroundGray.frame.maxY + CheckoutFullAddressCell.VerticalPaddingBetweenLabels
        nameLabel.frame = CGRect(x: CheckoutFullAddressCell.PaddingLeft, y: nameLabelY, width: labelWidth, height: CheckoutFullAddressCell.BasicLabelHeight)
        
        let addressLabelHeight = self.bounds.sizeHeight - nameLabel.frame.maxY - (CheckoutFullAddressCell.VerticalPaddingBetweenLabels * 2)
        addressLabel.frame = CGRect(x: CheckoutFullAddressCell.PaddingLeft, y: nameLabel.frame.maxY + CheckoutFullAddressCell.VerticalPaddingBetweenLabels, width: labelWidth, height: addressLabelHeight)
        
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
    }
    
    func setContent(withName name: String, address: String, phoneNumber: String) {
        nameLabel.text = "\(name) \(phoneNumber)"
        addressLabel.text = address
        
        layoutSubviews()
    }
    
    func showBorder(_ isShow: Bool) {
        borderView.isHidden = !isShow
    }
    
    class func getCellHeight(withAddress address: String, cellWidth: CGFloat) -> CGFloat {
        let dummyLabel = UILabel()
        dummyLabel.formatSmall()
        var height = dummyLabel.optimumHeight(text: address, width: cellWidth - CheckoutFullAddressCell.ArrowWidth - CheckoutFullAddressCell.ArrowRightMargin - CheckoutFullAddressCell.PaddingLeft)
        if height > CheckoutFullAddressCell.BasicLabelHeight * CheckoutFullAddressCell.MaxLineOfAddress {
            height = CheckoutFullAddressCell.BasicLabelHeight * CheckoutFullAddressCell.MaxLineOfAddress
        }
        
        return max(height, CheckoutFullAddressCell.BasicLabelHeight) + CheckoutFullAddressCell.TopPaddingForErrorMessage + CheckoutFullAddressCell.BottomPadding + (CheckoutFullAddressCell.BasicLabelHeight * 2) + (CheckoutFullAddressCell.VerticalPaddingBetweenLabels * 4)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
