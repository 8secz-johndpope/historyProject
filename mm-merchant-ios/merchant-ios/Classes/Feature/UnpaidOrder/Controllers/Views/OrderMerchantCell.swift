//
//  OrderMerchantCell.swift
//  merchant-ios
//
//  Created by Jerry Chong on 1/9/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class OrderMerchantCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderMerchantCellID"
    static let DefaultHeight: CGFloat = 50
    
    private final let NamePaddingRight: CGFloat = 5
    private final let ArrowSize = CGSize(width: 6, height: 24)
    private final let WidthMerchantImage: CGFloat = 36
    
    var mainView: UIView?
    var imageView: UIImageView?
    var nameLabel: UILabel?
    var rightLabel: UILabel?
    
    let csButton: ActionButton = {
        let button = ActionButton(frame: CGRect.zero)
        button.setTitleColor(UIColor.secondary2(), for: UIControlState())
        button.setTitle(String.localize("LB_CA_OMS_CONTACT_CS"), for: UIControlState())
        button.isHidden = true
        return button
    }()
    
    var contactHandler: (() -> Void)?
    
    private var separatorHeight: CGFloat = 1
    //private var separatorWidth: CGFloat = 1
    private var overseasLabel: UILabel?
    private var separatorView: UIView?
    private var topView: UIView?
    var IsForUnpaid = false
    
    var disclosureIndicatorImageView: UIImageView?
    var headerTappedHandler: ((_ data: Order) -> Void)?
    var cellTappedHandler: (() -> Void)?
    
    var isEnablePaddingLeft = false
    var isEnablePaddingRight = false

    var unpaidData: Order? {
        didSet {
            self.separatorHeight = 1
            self.setupUI()
            if let data = self.unpaidData {
                csButton.isHidden = true
                csButton.addTarget(self, action: #selector(actionCustomerService), for: .touchUpInside)
                MerchantService.fetchMerchantIfNeeded(data.merchantId, completion: { (merchant) in
                    if let _merchant = merchant{
                        if let imageView = self.imageView {
                            imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(_merchant.headerLogoImage, category: .merchant), placeholderImage: UIImage(named: "im_order_brand"), clipsToBounds: true, contentMode: .scaleAspectFit)
                        }
                        if let nameLabel = self.nameLabel {
                            if let overseasLabel = self.overseasLabel {
                                nameLabel.text = _merchant.merchantName
                                
                                let nameWidth = UIScreen.width() - self.WidthMerchantImage - ShoppingCartSectionArrowWidth - 30
                                var newWidth = nameLabel.optimumWidth()
                                
                                if (data.isCrossBorder){
                                    if newWidth > nameWidth {
                                        newWidth = nameWidth - 50
                                    }
                                }else{
                                    if newWidth > nameWidth {
                                        newWidth = nameWidth
                                    }
                                }
                            
                                nameLabel.frame = CGRect(x: nameLabel.frame.originX, y: 0, width: newWidth, height: nameLabel.height)
                                
                                overseasLabel.frame = CGRect(x: nameLabel.frame.maxX + 10, y: overseasLabel.frame.originY, width: overseasLabel.frame.width, height: overseasLabel.height)
                                overseasLabel.isHidden = !data.isCrossBorder
                            } else {
                                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                            }
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                    }
                })
                
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
        }
    }
    
    var merchant: Merchant? {
        didSet {
            self.separatorHeight = 0
            self.setupUI()
            if let _merchant = self.merchant {
                csButton.isHidden = true
                if let imageView = self.imageView {
                    imageView.mm_setImageWithURL(ImageURLFactory.URLSize256(_merchant.headerLogoImage, category: .merchant), placeholderImage: UIImage(named: "im_order_brand"), clipsToBounds: true, contentMode: .scaleAspectFit)
                }
                if let nameLabel = self.nameLabel {
                    if let overseasLabel = self.overseasLabel {
                        nameLabel.text = _merchant.merchantName
                        var newWidth = nameLabel.optimumWidth()
                        if let rightLabel = self.rightLabel {
                            newWidth = min(newWidth, rightLabel.frame.minX - (nameLabel.frame.minX + self.NamePaddingRight))
                        }
                        nameLabel.frame = CGRect(x: nameLabel.frame.originX, y: 0, width: newWidth, height: nameLabel.height)
                        
                        overseasLabel.frame = CGRect(x: nameLabel.frame.maxX + 10, y: overseasLabel.frame.originY, width: overseasLabel.frame.width, height: overseasLabel.height)
                        overseasLabel.isHidden = true
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            self.rightLabel?.isHidden = false
        }
        
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }
    
    private func setupUI(){
        mainView = containerView
        addSubview(containerView)
        
        addSubview(csButton)
        csButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            
            target.height.equalTo(Constants.ActionButton.Height)
            target.width.equalTo(75)
            target.right.equalTo(strongSelf.snp.right).offset(-15)
            target.centerY.equalTo(0)
        }

    }

    private lazy var containerView: UIView = {
        let topPadding: CGFloat = 0
        
        let view = UIView(frame: CGRect(x: 0, y: topPadding, width: frame.width, height: frame.height))
        view.backgroundColor = UIColor.white
        
        let nameWidth = view.bounds.width - WidthMerchantImage - ShoppingCartSectionArrowWidth - 30
        
        let imageConatinerView = { () -> UIView in
            let marginTop: CGFloat = 14
            let marginBottom: CGFloat = 14
            let view = UIView(frame: CGRect(x: 14, y: marginTop, width: WidthMerchantImage, height: view.frame.sizeHeight - marginTop - marginBottom))
            
            let imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = .scaleAspectFill
            
            view.addSubview(imageView)
            self.imageView = imageView
            return view
        } ()
        view.addSubview(imageConatinerView)
        
        nameLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: imageConatinerView.frame.maxX + 10, y: 0, width: nameWidth, height: view.frame.sizeHeight))
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
        
        
        separatorView = { () -> UIView in
            var view = UIView()
            if (IsForUnpaid) {
                view = UIView(frame: CGRect(x: 15, y: nameLabel!.frame.maxY - separatorHeight, width: frame.width - 30, height: separatorHeight))
            }else{
                view = UIView(frame: CGRect(x: 0, y: nameLabel!.frame.maxY - separatorHeight, width: frame.width, height: separatorHeight))
            }
            view.backgroundColor = UIColor.backgroundGray()
            return view
        } ()
        view.addSubview(separatorView!)
        
        topView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: separatorHeight))
            view.backgroundColor = UIColor.backgroundGray()
            return view
        } ()
        topView?.isHidden = true
        view.addSubview(topView!)
        
        
        rightLabel = { () -> UILabel in
            let label = UILabel(frame: CGRect(x: frame.width - ArrowSize.width - 50, y: (view.frame.sizeHeight - ArrowSize.height) / 2, width: ArrowSize.width + 22, height: ArrowSize.height))
            label.adjustsFontSizeToFitWidth = true
            label.formatSmall()
            label.textColor = UIColor.secondary3()
            label.text = String.localize("LB_CA_PDP_ENTER_MLP")
            return label
        } ()
        rightLabel!.isHidden = true
        view.addSubview(rightLabel!)
        
        let arrowView = { () -> UIImageView in
            let imageView = UIImageView(frame: CGRect(x: frame.width - ArrowSize.width, y: (view.frame.sizeHeight - ArrowSize.height) / 2, width: ArrowSize.width, height: ArrowSize.height))
            imageView.image = UIImage(named: "arrow_right")
            imageView.contentMode = .scaleAspectFit
            imageView.image = imageView.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
            imageView.tintColor = UIColor.secondary3()
            imageView.isHidden = false
            return imageView
        } ()
        disclosureIndicatorImageView = arrowView
        view.addSubview(disclosureIndicatorImageView!)
        
        return view
    } ()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let contentView = self.mainView {
            let paddingLeft: CGFloat = isEnablePaddingLeft ? 10 : 0
            let paddingRight: CGFloat = isEnablePaddingRight ? 10 : 0
            
            contentView.frame.originX = paddingLeft
            contentView.frame.sizeWidth = contentView.frame.sizeWidth - paddingLeft - paddingRight
            disclosureIndicatorImageView!.frame.originX = contentView.frame.sizeWidth - ArrowSize.width - 15
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func headerTapped() {
        if let callback = self.headerTappedHandler {
            if let data = self.unpaidData {
                callback(data)
            } else {
                
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        if let cellCallback = self.cellTappedHandler {
            cellCallback()
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
    
    func showTopView(_ isShow: Bool){
        if let topView = self.topView {
            topView.isHidden = !isShow
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc private func actionCustomerService(_ sender: UIButton){
        if let callback = self.contactHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }

}
