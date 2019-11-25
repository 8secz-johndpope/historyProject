//
//  BrandNameCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import YYText
import UIKit

class BrandNameCell : UICollectionViewCell{
    static let CellIdentifier = "BrandNameCellID"
    
    private final let MIN_DAYS_SHOW_COUNTDOWN = 14
    private static let MarginRightShareButton: CGFloat = 15
    private static let MarginRightProductName: CGFloat = 30
    private static let WidthShareButton: CGFloat = 30
    private static let WidthCountDownLabel: CGFloat = 140
    private static let ProductNameFont = UIFont.fontWithSize(16, isBold: true)
    private var isCrossBorder = false
    private var skuName = ""
    private var shippingThresold: String? = nil
    

    var shareTapHandler: (() -> Void)?
    var timer: Timer? = nil
    var isTimerRunning = false
    var seconds = 0
    var dateSaleFrom: Date? = nil
    var dateSaleTo: Date? = nil {
        didSet{
            if let dateSaleTo = self.dateSaleTo, dateSaleTo > Date() {
                seconds = Int(dateSaleTo.timeIntervalSinceNow)
            }
        }
    }
    var isFlashSaleDiscount = false {
        didSet{
            if isFlashSaleDiscount{
                countdownLabel.isHidden = true
                priceLabel.isHidden = true
            } else{
                countdownLabel.isHidden = false
                priceLabel.isHidden = false
            }
        }
    }
    
    private let productNameLabel: YYLabel = {
        let label = YYLabel()
        label.font = BrandNameCell.ProductNameFont
        label.textColor = UIColor(hexString: "#4C4C4C")
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 2
        return label
    }()
    
    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.applyFontSize(14, isBold: false)
        label.textColor = UIColor.grayTextColor()
        label.backgroundColor = UIColor.primary2()
        label.layer.cornerRadius = 3
        label.layer.borderColor = UIColor.primary2().cgColor
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()
    
    private let brandNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor(hexString: "#333333")
        label.textAlignment = .center
        label.viewBorder(UIColor(hexString: "#CCCCCC"), width: 0.5)
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.applyFontSize(18, isBold: true)
        label.textColor = UIColor.primary1()
        return label
    }()
    
    private let overseaLabel: UILabel = {
        let label = UILabel()
        label.applyFontSize(18, isBold: true)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.secondary2()
        label.text = ""
        return label
    }()
    
    private let shareButton: IconButtonView = {
        let view = IconButtonView()
        view.iconDimension = 30
        view.setType(IconButtonView.ButtonType.share)
        return view
    }()
    
    private lazy var line: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor(hexString: "E7E7E7")
        return line
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        addSubview(shareButton)
        addSubview(productNameLabel)
        addSubview(brandNameLabel)
        addSubview(priceLabel)
        addSubview(countdownLabel)
        addSubview(line)
        layoutSubviews()
        
        shareButton.tapHandler = {
            if let callback = self.shareTapHandler {
                callback()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginRightShareButton: CGFloat = BrandNameCell.MarginRightShareButton
        shareButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(47)
            target.width.equalTo(BrandNameCell.WidthShareButton)
            target.top.equalTo(strongSelf.snp.top).offset(16)
            target.right.equalTo(strongSelf.snp.right).offset(-marginRightShareButton)
        }
        
        let marginRightProductName: CGFloat = BrandNameCell.MarginRightProductName
        let sizeProductName = BrandNameCell.getSizeNameLabel(text: self.skuName, cellWidth: self.bounds.sizeWidth - BrandNameCell.WidthShareButton - BrandNameCell.MarginRightProductName, isCrossBorder: isCrossBorder, fontSize: 16, shippingThresold: self.shippingThresold)
        productNameLabel.snp.remakeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            
            target.height.equalTo(min(max(sizeProductName.height + 4, 26), 54)) //Size height will be >= 26 and <= 54 
            target.top.equalTo(strongSelf.snp.top).offset(18)
            target.left.equalTo(strongSelf.snp.left).offset(14)
            target.right.equalTo(strongSelf.shareButton.snp.left).offset(-marginRightProductName)
        }
        
        let brandNameWidth = StringHelper.getTextWidth(brandNameLabel.text ?? "", height: 16, font: UIFont.boldSystemFont(ofSize: 12)) + 12
        brandNameLabel.snp.remakeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(16)
            target.top.equalTo(strongSelf.productNameLabel.snp.bottom).offset(5)
            target.left.equalTo(strongSelf.snp.left).offset(14)
            target.width.equalTo(brandNameWidth)
        }
        
        let shouldHideCountDownText = self.shouldHideCountDownText()
        priceLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.brandNameLabel.snp.bottom).offset(7)
            target.left.equalTo(strongSelf.snp.left).offset(14)
            
            if shouldHideCountDownText {
                target.right.equalTo(strongSelf.right).offset(-14)
            } else {
                target.right.equalTo(strongSelf.countdownLabel.snp.left).offset(-10)
            }
        }
        
        if shouldHideCountDownText {
            countdownLabel.isHidden = true
        } else {
            countdownLabel.isHidden = false
            countdownLabel.snp.makeConstraints { [weak self] (target) in
                guard let strongSelf = self else {
                    return
                }
                target.top.equalTo(strongSelf.priceLabel.snp.top)
                target.width.equalTo(BrandNameCell.WidthCountDownLabel)
                target.right.equalTo(strongSelf.snp.right).offset(-15)
                target.height.equalTo(20)
            }
        }
        
        line.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.equalTo(self.snp.left).offset(15)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(self.snp.bottom)
        }
    }
    
    //MARK: - Count Down Timer
    
    func shouldHideCountDownText() -> Bool {
        
        let nowDate = TimestampService.defaultService.getServerTime() ?? Date()
        
        if isFlashSaleDiscount {
            return true
        } else {
            if let dateSaleTo = self.dateSaleTo, let dateSaleFrom = self.dateSaleFrom {
                if dateSaleTo > nowDate && dateSaleFrom < nowDate {
                    let interVal = Int(dateSaleTo.timeIntervalSinceNow)
                    let days = interVal / 86400
                    return days >= MIN_DAYS_SHOW_COUNTDOWN
                } else {
                    return true
                }
            } else {
                return true
            }
        }
    }
    
    @discardableResult
    func startCountDown() -> Timer? {
        if timer != nil {
            stopCountDown()
        }
        
        let currentTime = TimestampService.defaultService.getServerTime() ?? Date()
        if let dateSaleTo = self.dateSaleTo, dateSaleTo > currentTime {
            
            seconds = Int(dateSaleTo.timeIntervalSinceNow)
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
            
            return timer!
        }
        
        return nil
        
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            timer?.invalidate()
        } else {
            seconds -= 1
            DispatchQueue.main.async {
                self.countdownLabel.attributedText = self.timeString(time: TimeInterval(self.seconds))
            }
        }
    }
    func stopCountDown() {
        timer?.invalidate()
        isTimerRunning = false
    }
    
    func timeString(time: TimeInterval) -> NSAttributedString {
        let days = Int(time) / 86400
        let hours = Int(time) / 3600 % 24
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        var timeText: NSMutableAttributedString!
        if days < 1 {
            let font = UIFont.fontWithSize(14, isBold: true)
            let dayStr = String.localize("LB_AC_COUPON_REFERRAL_VALID_DAYS")
            timeText = NSMutableAttributedString(string: String(format:"%i%@ %02i:%02i:%02i", days,dayStr, hours, minutes, seconds), attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.primary1()])
        } else {
            let font = UIFont.fontWithSize(14, isBold: false)
            let dayStr = String.localize("LB_AC_COUPON_REFERRAL_VALID_DAYS")
            timeText = NSMutableAttributedString(string: String(format:"%i%@ %02i:%02i:%02i", days,dayStr, hours, minutes, seconds), attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.grayTextColor()])
        }
        
        let spacing = NSAttributedString(string: " ")
        let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(string: String.localize("PDP_SALES_END"))
        mutableAttachmentString.append(spacing)
        mutableAttachmentString.append(timeText)
        return mutableAttachmentString
    }
    
    //MARK: - Set Data
    func setData(_ skuName: String, brandName: String, price: Double = 0, retailPrice: Double = 0){
        self.skuName = skuName
        let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: skuName, attributes: [NSAttributedStringKey.font: BrandNameCell.ProductNameFont])
        productNameLabel.attributedText = strLabelText
        productNameLabel.sizeToFit()
        brandNameLabel.attributedText = getImageAtrriString(brandName, imageName: "brand_arrow_right")
        brandNameLabel.sizeToFit()
        priceLabel.attributedText = PriceHelper.getFormattedPriceText(withRetailPrice: retailPrice, salePrice: price, isSale: 1, retailPriceFontSize: 14, salePriceFontSize: 18, retailPriceWithSaleFontColor: UIColor.secondary2(), isBoldSalePriceFont: true)
        
    }
    
    func setData(_ skuName: String, brandName: String, priceRange: String){
        self.skuName = skuName
        let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: skuName, attributes: [NSAttributedStringKey.font: BrandNameCell.ProductNameFont])
        productNameLabel.attributedText = strLabelText
        productNameLabel.sizeToFit()
        brandNameLabel.attributedText = getImageAtrriString(brandName, imageName: "brand_arrow_right")
        brandNameLabel.sizeToFit()
        priceLabel.text = priceRange
    }
    
    //MARK: - Get Size
    private class func getSizeNameLabel(text: String?, cellWidth: CGFloat, isCrossBorder: Bool, fontSize: CGFloat, shippingThresold: String? = nil) -> CGSize {
        if let text: String = text {
            let labelWidth = cellWidth - 15
            let dummyLabel = YYLabel(frame: CGRect(x:15,y: 0,width: labelWidth - 15,height: CGFloat.greatestFiniteMagnitude))
            dummyLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            
            var currentFont: UIFont!
            if let font = UIFont(name: Constants.Font.Bold, size: CGFloat(fontSize)) {
                currentFont = font
            } else {
                currentFont = UIFont(name: dummyLabel.font.fontName, size: fontSize)
            }
            dummyLabel.font = currentFont
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedStringKey.font: currentFont])
            dummyLabel.attributedText = strLabelText
            dummyLabel.numberOfLines = 0
            
            if let shippingThresold = shippingThresold {
                BrandNameCell.addShippingThresoldLabel(getFullShippingThresoldText(shippingThresold), label: dummyLabel)
            }
            
            if isCrossBorder {
                BrandNameCell.addImage("crossbroder", label: dummyLabel)
            }
            
            dummyLabel.sizeToFit()
            let size = dummyLabel.frame.size
            
            return size
        }
        return CGSize.zero
    }

    class func getSizeCell(productName: String?, brandName: String?, price: String?, cellWidth: CGFloat, isCrossBorder: Bool, shippingThresold: String?,isFlashSaleDiscount:Bool = false) -> CGSize {
        let productNameLabelSize = BrandNameCell.getSizeNameLabel(text: productName, cellWidth: cellWidth - BrandNameCell.WidthShareButton - BrandNameCell.MarginRightProductName , isCrossBorder: isCrossBorder, fontSize: 16, shippingThresold: shippingThresold)
        let brandNameLabelSize = BrandNameCell.getSizeNameLabel(text: brandName, cellWidth: cellWidth, isCrossBorder: false, fontSize: 14)
        var priceLabelHeight = BrandNameCell.getSizeNameLabel(text: price, cellWidth: cellWidth, isCrossBorder: false, fontSize: 18).height
        if isFlashSaleDiscount {
            priceLabelHeight = 0
        } else {
            priceLabelHeight = BrandNameCell.getSizeNameLabel(text: price, cellWidth: cellWidth, isCrossBorder: false, fontSize: 18).height
        }
        
        let productNameLbHeight = min(max(productNameLabelSize.height + 4, 26), 54)
        let totalHeight = 18 + productNameLbHeight + brandNameLabelSize.height + priceLabelHeight + 17
        return CGSize(width: cellWidth, height: totalHeight)
    }

    func showCrossBorderLabel(_ show: Bool) {
        isCrossBorder = show
        if (show) {
            BrandNameCell.addImage("crossbroder", label: productNameLabel)
            productNameLabel.textAlignment = .left
        }
    }
    
    func showShippingThresold(shippingThresold: String) {
        self.shippingThresold = shippingThresold
        BrandNameCell.addShippingThresoldLabel(shippingThresold, label: productNameLabel)
        productNameLabel.textAlignment = .left
    }
    
    class func getFullShippingThresoldText(_ shippingThresold: String) -> String {
        var shippingThresoldText = String.localize("LB_CA_ALL_FREE_SHIPPING")
        if shippingThresold.length > 0 {
            shippingThresoldText = String.localize("LB_CA_FREE_SHIPPING_MIN_AMT_S1").replacingOccurrences(of: "{0}", with: "\(shippingThresold)")
        }
        
        return shippingThresoldText
    }
    
    private class func addShippingThresoldLabel(_ shippingThresold: String, label: YYLabel) {
        let spacing = NSAttributedString(string: " ")
        
        let shippingThresoldText = BrandNameCell.getFullShippingThresoldText(shippingThresold)
        
        let font = UIFont.fontWithSize(10, isBold: false)
        let freeShippingText = NSMutableAttributedString(string: " \(shippingThresoldText) ", attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.primary1()])
        let border = YYTextBorder()
        border.strokeColor = UIColor.primary1()
        border.strokeWidth = 1
        border.lineStyle = .single
        border.cornerRadius = 3
        border.insets = UIEdgeInsetsMake(-2, 0, 3, 0)
        freeShippingText.yy_textBackgroundBorder = border
        freeShippingText.yy_setBaselineOffset(3, range: NSMakeRange(0, freeShippingText.length))

        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineBreakMode = .byTruncatingTail
        paraStyle.alignment = .center
        let strLabelText: NSMutableAttributedString = NSMutableAttributedString(attributedString: label.attributedText ?? NSMutableAttributedString())
        let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: spacing)
        mutableAttachmentString.append(freeShippingText)
        mutableAttachmentString.append(spacing)
        mutableAttachmentString.append(strLabelText)
        mutableAttachmentString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paraStyle, range: NSMakeRange(0, mutableAttachmentString.length))
        label.attributedText = mutableAttachmentString
    }
    
    private class func addImage(_ imageName: String, label: YYLabel) {
        let spacing = NSAttributedString(string: " ")
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineBreakMode = .byWordWrapping
        paraStyle.alignment = .center
        
        var attachment: NSMutableAttributedString! = nil
        if let image = UIImage(named: imageName) {
            attachment = NSMutableAttributedString.yy_attachmentString(withContent: image, contentMode: .center, attachmentSize: image.size, alignTo: label.font, alignment: .center)
            attachment.addAttribute(NSAttributedStringKey.paragraphStyle, value: paraStyle, range: NSMakeRange(0, attachment.length))
            //attachment.bounds = CGRectMake(0, -2.5, image.size.width, image.size.height);
        } else {
            attachment = NSMutableAttributedString()
        }
        
        let strLabelText: NSMutableAttributedString = NSMutableAttributedString(attributedString: label.attributedText ?? NSMutableAttributedString())
        let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachment)
        mutableAttachmentString.append(spacing)
        mutableAttachmentString.append(strLabelText)
        mutableAttachmentString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paraStyle, range: NSMakeRange(0, mutableAttachmentString.length))
        label.attributedText = mutableAttachmentString
    }
    
    /// 在字符的后面追加图片
    private func getImageAtrriString(_ str: String, imageName: String) -> NSMutableAttributedString {
        let arrString = NSMutableAttributedString(string: str + "  ")
        let attach = NSTextAttachment()
        attach.image = UIImage(named: imageName)
        let attchString = NSAttributedString(attachment: attach)
        arrString.append(attchString)
        return arrString
    }
}
