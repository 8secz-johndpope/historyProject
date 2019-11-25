
//
//  MarchantSectionHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class MerchantSectionHeaderView: UICollectionReusableView {
    
    static let ViewIdentifier = "MerchantSectionHeaderViewID"
    static let DefaultHeight: CGFloat = 50
    
    private final let ArrowSize = CGSize(width: 32, height: 32)
    
    var contentView: UIView?
    var imageView: UIImageView?
    var nameLabel: UILabel?
    private var overseasLabel: UILabel?
    private var separatorView: UIView?
    
    var disclosureIndicatorImageView: UIImageView?
    var headerTappedHandler: ((_ data: OrderSectionData) -> Void)?
    
    var isEnablePaddingLeft = false
    var isEnablePaddingRight = false
    
    var data: OrderSectionData? {
        didSet {
            if let data = self.data {
                if let imageKey = self.data?.order?.headerLogoImage {
                    if let imageView = self.imageView {
                        imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(imageKey, category: .merchant), placeholderImage: UIImage(named: "im_order_brand"), clipsToBounds: true, contentMode: .scaleAspectFit)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
                if let nameLabel = self.nameLabel {
                    if let overseasLabel = self.overseasLabel {
                        nameLabel.text = data.order?.merchantName
                        nameLabel.numberOfLines = 1
                        
                        let nameWidth = UIScreen.width() - ShoppingCartSectionMerchantImageWidth - ShoppingCartSectionArrowWidth
                        var newWidth = nameLabel.optimumWidth()
                        if let order = data.order {
                            if (order.isCrossBorder){
                                if newWidth > nameWidth {
                                    newWidth = nameWidth - 50
                                }
                            }else{
                                if newWidth > nameWidth {
                                    newWidth = nameWidth
                                }
                            }
                        }
                        
                        nameLabel.frame = CGRect(x: ShoppingCartSectionMerchantImageWidth + 5, y: 0, width: newWidth, height: nameLabel.height)
                        
                        overseasLabel.frame = CGRect(x: nameLabel.frame.maxX + 10, y: overseasLabel.frame.originY, width: overseasLabel.frame.width, height: overseasLabel.height)
                        
                        if let order = data.order {
                            overseasLabel.isHidden = !order.isCrossBorder
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let containerView = { () -> UIView in
            let topPadding: CGFloat = 10
            
            let view = UIView(frame: CGRect(x: 0, y: topPadding, width: frame.width, height: frame.height - topPadding))
            view.backgroundColor = UIColor.white
            
            let nameWidth = view.bounds.width - ShoppingCartSectionMerchantImageWidth - ShoppingCartSectionArrowWidth
            
            let imageConatinerView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: ShoppingCartSectionMerchantImageWidth, height: view.frame.sizeHeight))
                
                let imageView = UIImageView(frame: UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 10)))
                imageView.contentMode = .scaleAspectFit
                view.addSubview(imageView)
                self.imageView = imageView
                return view
            } ()
            view.addSubview(imageConatinerView)
            
            nameLabel = { () -> UILabel in
                let label = UILabel(frame: CGRect(x: imageConatinerView.frame.maxX, y: 0, width: nameWidth, height: view.frame.sizeHeight))
                label.formatSmall()
                label.adjustsFontSizeToFitWidth = false
                label.lineBreakMode = NSLineBreakMode.byTruncatingTail
                label.numberOfLines = 1
                return label
            } ()
            view.addSubview(nameLabel!)
            
            overseasLabel = { () -> UILabel in
                let labelHeight: CGFloat = 18
                let labelPadding: CGFloat = 8
                
                let label = UILabel(frame: CGRect(x: nameLabel!.frame.maxX + labelPadding, y: (view.height - labelHeight) / 2, width: 20, height: labelHeight))
                label.adjustsFontSizeToFitWidth = true
                label.textAlignment = .center
                label.formatSize(11)
                label.text = String.localize("LB_CA_OMS_OVERSEAS")
                label.textColor = UIColor.white
                label.backgroundColor = UIColor.noteColor()
                label.layer.masksToBounds = true
                label.layer.cornerRadius = 4
                label.isHidden = true
                
                // Update label width according to the content
                label.width = label.optimumWidth() + (labelPadding * 2)
                
                return label
            } ()
            view.addSubview(overseasLabel!)
            
            // Clear button cover from Merchant image to right arrow. Tap to go to the Merchant Public Profile Page
            let clearButton = { () -> UIButton in
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: imageConatinerView.frame.minX, y: 0, width: frame.width - imageConatinerView.frame.minX, height: frame.height)
                button.backgroundColor = UIColor.clear
                button.addTarget(self, action: #selector(headerTapped), for: .touchUpInside)
                return button
            } ()
            view.addSubview(clearButton)
            
            let separatorHeight: CGFloat = 1
            separatorView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: nameLabel!.frame.maxY - separatorHeight, width: frame.width, height: separatorHeight))
                view.backgroundColor = UIColor.backgroundGray()
                return view
            } ()
            view.addSubview(separatorView!)
            
            let arrowView = { () -> UIImageView in
                let imageView = UIImageView(frame: CGRect(x: frame.width - ArrowSize.width, y: (view.frame.sizeHeight - ArrowSize.height) / 2, width: ArrowSize.width, height: ArrowSize.height))
                imageView.image = UIImage(named: "icon_arrow_small")
                imageView.contentMode = .scaleAspectFit
                imageView.isHidden = false
                return imageView
            } ()
            disclosureIndicatorImageView = arrowView
            view.addSubview(disclosureIndicatorImageView!)
            
            return view
        } ()
        contentView = containerView
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let contentView = self.contentView {
            let arrowRightMargin: CGFloat = 10
            let paddingLeft: CGFloat = isEnablePaddingLeft ? 10 : 0
            let paddingRight: CGFloat = isEnablePaddingRight ? 10 : 0
            
            contentView.frame.originX = paddingLeft
            contentView.frame.sizeWidth = contentView.frame.sizeWidth - paddingLeft - paddingRight
            
            disclosureIndicatorImageView!.frame.originX = contentView.frame.sizeWidth - ArrowSize.width - arrowRightMargin
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func headerTapped() {
        if let callback = self.headerTappedHandler {
            if let data = self.data {
                callback(data)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        if let disclosureIndicatorImageView = self.disclosureIndicatorImageView {
            disclosureIndicatorImageView.isHidden = !isShow
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func showSeparatorView(_ isShow: Bool){
        if let separatorView = self.separatorView {
            separatorView.isHidden = !isShow
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
}
