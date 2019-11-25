//
//  PaymentSelectionCell.swift
//  merchant-ios
//
//  Created by HungPM on 2/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

let PaymentCellHeight = CGFloat(55)

class PaymentSelectionCell: UICollectionViewCell {
    
    static let CellIdentifier = "PaymentSelectionCellID"
    
    private var imageViewLogo: UIImageView!
    private var labelName: UILabel!
    var paymentSelectButton: UIButton!
    var separatorView: UIView!
    
    var selectHandler: ((PaymentMethod) -> ())?
    var paymentMethod: PaymentMethod? {
        didSet {
            if let data = paymentMethod {
                imageViewLogo.image = data.image
                labelName.text = data.title
                paymentSelectButton.isSelected = data.selected
            } else {
                imageViewLogo.image = nil
                labelName.text = ""
                paymentSelectButton.isSelected = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.backgroundColor = UIColor.white
        
        self.frame = CGRect(x: 0, y: 0, width: frame.width, height: PaymentCellHeight)

        let logo = { () -> UIImageView in
            let MarginLeft = CGFloat(18)
            let ImageWidth = CGFloat(34)
            
            let imageView = UIImageView(frame: CGRect(x: MarginLeft, y: (PaymentCellHeight - ImageWidth) / 2, width: 34, height: 34))
            imageView.contentMode = .scaleAspectFit
            
            return imageView
        }()
        self.contentView.addSubview(logo)
        self.imageViewLogo = logo

        let selectButton = { () -> UIButton in
            let MarginRight = CGFloat(21)

            let button = UIButton(type: .custom)
            button.config(
                normalImage: UIImage(named: "icon_checkbox_unchecked"),
                selectedImage: UIImage(named: "icon_checkbox_checked")
            )
//            button.addTarget(self, action: #selector(PaymentSelectionCell.paymentItemSelect), for: .touchUpInside)
            button.isUserInteractionEnabled = false
            button.sizeToFit()
            button.frame = CGRect(x: frame.width - MarginRight - button.frame.width, y: (PaymentCellHeight - button.frame.height) / 2, width: button.frame.width, height: button.frame.height)
            
            return button
        }()
        self.contentView.addSubview(selectButton)
        self.paymentSelectButton = selectButton

        let name = { () -> UILabel in
            let MarginLeft = CGFloat(35)
            let xPos = logo.frame.maxX + MarginLeft
            let label = UILabel(frame: CGRect(x: xPos, y: 0, width: selectButton.frame.minX - xPos, height: PaymentCellHeight))
            label.formatSingleLine(15)
            label.textColor = UIColor.black
            
            return label
        }()
        self.contentView.addSubview(name)
        self.labelName = name

        let separatorHeight = CGFloat(1)
        let separatorView = { () -> UIView in
            
            let view = UIView(frame: CGRect(x: 0, y: PaymentCellHeight - separatorHeight, width: frame.width, height: separatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        } ()
        self.separatorView = separatorView
        self.contentView.addSubview(separatorView)
    
    }

    func paymentItemSelect() {
        if let callback = selectHandler, let data = self.paymentMethod {
            callback(data)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSeparatorViewHeight(separatorHeight: CGFloat) {
        separatorView.frame = CGRect(x: 0, y: self.frame.sizeHeight - separatorHeight, width: frame.width, height: separatorHeight)
    }
}
