//
//  FlashSaleBarCell.swift
//  storefront-ios
//
//  Created by Kam on 8/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class FlashSaleBarCell: UICollectionViewCell {
    static let CellIdentifier = "FlashSaleBarCellID"
    var timer: Timer? = nil
    var seconds = 0
    var dateSaleFrom: Date? = nil
    var dateSaleTo: Date? = nil {
        didSet{
            if let dateSaleTo = self.dateSaleTo, dateSaleTo > Date() {
                seconds = Int(dateSaleTo.timeIntervalSinceNow)
                start()
            }
        }
    }
    //松松 UI
    var sku: Sku?{
        didSet{
            if let sku = sku{
                flashSalePriceLabel.text = "\(sku.priceFlashSale)"
//                threeLabel.text =  "\(sku.priceRetail)"
                let dateFormatter = DateFormatter.init()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let date = dateFormatter.date(from: "May 20, 2018 at 11:59:59 PM")
                dateSaleTo = date
                start()
                
                let priceText = NSMutableAttributedString()
                let retailText = NSAttributedString(
                    string: "￥\(sku.priceRetail)",
                    attributes: [
                        NSAttributedStringKey.foregroundColor: UIColor.white,
                        NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
                        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12),
                        NSAttributedStringKey.baselineOffset: (UIFont.systemFont(ofSize: 12).capHeight - UIFont.systemFont(ofSize: 12).capHeight) / 2
                    ]
                )
                
                priceText.append(retailText)
                threeLabel.attributedText = priceText
                
                if sku.flashSaleTo == nil && sku.flashSaleFrom == nil{
                    tipLabel.isHidden = true
                    timeView.isHidden = true
                }else {
                    tipLabel.isHidden = false
                    timeView.isHidden = false
                    self.dateSaleFrom = sku.flashSaleFrom
                    self.dateSaleTo = sku.flashSaleTo
                }
                
  
            }
        }
    }
    
    lazy var currencyLabel:UILabel = {
        let currencyLabel = UILabel()
        currencyLabel.font = UIFont.boldSystemFont(ofSize: 12)
        currencyLabel.textColor = .white
        currencyLabel.text = "￥"
        return currencyLabel
    }()
    
    
    
    lazy var flashSalePriceLabel:UILabel = {
        let flashSalePriceLabel = UILabel()
        flashSalePriceLabel.font = UIFont.boldSystemFont(ofSize: 20)
        flashSalePriceLabel.textColor = .white
        return flashSalePriceLabel
    }()
    
    lazy var threeLabel:UILabel = {
        let threeLabel = UILabel()
        threeLabel.font = UIFont.boldSystemFont(ofSize: 10)
        threeLabel.textColor = .white
        return threeLabel
    }()
    
    lazy var tipLabel:UILabel = {
        let tipLabel = UILabel()
        tipLabel.font = UIFont.boldSystemFont(ofSize: 10)
        tipLabel.textColor = .white
        tipLabel.text = String.localize("LB_CA_NEWBIEPRICE_PDP_ENDING_IN")
        return tipLabel
    }()
    
    lazy var bgImageView:UIImageView = {
        let bgImageView = UIImageView()
        bgImageView.image = UIImage.init(named: "flash_bg")
        return bgImageView
    }()
    
    lazy var flashSaleFirstImageView:UIImageView = {
        let flashSaleFirstImageView = UIImageView()
        flashSaleFirstImageView.image = UIImage.init(named: "newbie_tag")
        flashSaleFirstImageView.sizeToFit()
        return flashSaleFirstImageView
    }()

    lazy var flashSaleSecondImageView:UIImageView = {
        let flashSaleSecondImageView = UIImageView()
        flashSaleSecondImageView.image = UIImage.init(named: "only_tag")
        flashSaleSecondImageView.sizeToFit()
        return flashSaleSecondImageView
    }()
    
    lazy var timeView:FlashTimeView = {
        let timeView = FlashTimeView()
        timeView.isHidden = true
        return timeView
    }()
    
    override init(frame: CGRect) {
       super.init(frame: frame)
        
       self.backgroundColor = .red
        
        self.contentView.addSubview(bgImageView)
        self.contentView.addSubview(currencyLabel)
        self.contentView.addSubview(flashSalePriceLabel)
        self.contentView.addSubview(threeLabel)
        self.contentView.addSubview(tipLabel)
        self.contentView.addSubview(flashSaleFirstImageView)
        self.contentView.addSubview(flashSaleSecondImageView)
        self.contentView.addSubview(timeView)
        
        bgImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.contentView)
        }
        currencyLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.bottom.equalTo(flashSalePriceLabel).offset(-2)
        }
        flashSalePriceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(currencyLabel.snp.right)
            make.top.equalTo(self.contentView).offset(2)
        }
        threeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(flashSalePriceLabel.snp.right).offset(2)
            make.bottom.equalTo(flashSalePriceLabel).offset(-2)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self.contentView).offset(-15)
            make.top.equalTo(self.contentView).offset(5)
        }
        flashSaleFirstImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(15)
            make.bottom.equalTo(self.contentView).offset(-6)

        }
        
        flashSaleSecondImageView.snp.makeConstraints { (make) in
            make.left.equalTo(flashSaleFirstImageView.snp.right).offset( 6)
            make.bottom.equalTo(self.contentView).offset(-6)
        }
        timeView.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.right.equalTo(self.contentView).offset(-15)
            make.bottom.equalTo(self.contentView).offset(-7)
        }
    }
    
    func start()  {
        if timer != nil {
            timer?.invalidate()
        }
        
        let currentTime = TimestampService.defaultService.getServerTime() ?? Date()
        if let dateSaleTo = self.dateSaleTo, dateSaleTo > currentTime {
            seconds = Int(dateSaleTo.timeIntervalSinceNow)
            self.timeString(time: TimeInterval(self.seconds))
            self.timeView.isHidden = false
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
        } else {
            self.timeView.isHidden = true
        }
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            timer?.invalidate()
        } else {
            seconds -= 1
            DispatchQueue.main.async {
                self.timeString(time: TimeInterval(self.seconds))
//                self.tipLabel.attributedText = self.timeString(time: TimeInterval(self.seconds))
            }
        }
    }
    
    func timeString(time: TimeInterval)  {
        let days = Int(time) / 86400
        let hours = Int(time) / 3600 % 24
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        timeView.dayLabel.text = String(format:"%02i", days)
        timeView.hourLabel.text = String(format:"%02i", hours)
        timeView.minuteLabel.text = String(format:"%02i", minutes)
        timeView.secondsLabel.text = String(format:"%02i", seconds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

class FlashTimeView: UIView {
    var getPriceStyle: Bool? {
        didSet {
            if let style =  getPriceStyle {
                if style {
                    dayLabel.backgroundColor = UIColor(hexString: "#F1F1F1")
                    hourLabel.backgroundColor = UIColor(hexString: "#F1F1F1")
                    minuteLabel.backgroundColor = UIColor(hexString: "#F1F1F1")
                    secondsLabel.backgroundColor = UIColor(hexString: "#F1F1F1")
                    firstTipLabel.textColor = .black
                    secondTipLabel.textColor = .black
                    thridTipLabel.textColor = .black
                } else {
                    dayLabel.textColor = .red
                    hourLabel.textColor = .red
                    minuteLabel.textColor = .red
                    secondsLabel.textColor = .red
                    firstTipLabel.textColor = .red
                    secondTipLabel.textColor = .red
                    thridTipLabel.textColor = .red
                }

            }
        }
    }
    lazy var dayLabel:UILabel = {
        let dayLabel = UILabel()
        dayLabel.font = UIFont.systemFont(ofSize: 14)
        dayLabel.text = "00"
        dayLabel.textAlignment = .center
        dayLabel.backgroundColor = .white
        dayLabel.layer.cornerRadius = 2
        dayLabel.layer.masksToBounds = true
        return dayLabel
    }()
    lazy var hourLabel:UILabel = {
        let hourLabel = UILabel()
        hourLabel.font = UIFont.systemFont(ofSize: 14)
        hourLabel.text = "00"
        hourLabel.backgroundColor = .white
        hourLabel.layer.cornerRadius = 2
        hourLabel.layer.masksToBounds = true
        hourLabel.textAlignment = .center
        return hourLabel
    }()
    lazy var minuteLabel:UILabel = {
        let minuteLabel = UILabel()
        minuteLabel.font = UIFont.systemFont(ofSize: 14)
        minuteLabel.text = "00"
        minuteLabel.backgroundColor = .white
        minuteLabel.layer.cornerRadius = 2
        minuteLabel.layer.masksToBounds = true
        minuteLabel.textAlignment = .center
        return minuteLabel
    }()
    lazy var secondsLabel:UILabel = {
        let secondsLabel = UILabel()
        secondsLabel.font = UIFont.systemFont(ofSize: 14)
        secondsLabel.text = "00"
        secondsLabel.backgroundColor = .white
        secondsLabel.layer.cornerRadius = 2
        secondsLabel.layer.masksToBounds = true
        secondsLabel.textAlignment = .center
        return secondsLabel
    }()
    lazy var firstTipLabel:UILabel = {
        let firstTipLabel = UILabel()
        firstTipLabel.font = UIFont.systemFont(ofSize: 14)
        firstTipLabel.text = String.localize("LB_AC_COUPON_REFERRAL_VALID_DAYS")
        firstTipLabel.textAlignment = .center
        firstTipLabel.textColor = .white
        return firstTipLabel
    }()


    lazy var secondTipLabel:UILabel = {
        let secondTipLabel = UILabel()
        secondTipLabel.font = UIFont.systemFont(ofSize: 14)
        secondTipLabel.text = ":"
        secondTipLabel.textAlignment = .center
        secondTipLabel.textColor = .white
        return secondTipLabel
    }()
    lazy var thridTipLabel:UILabel = {
        let thridTipLabel = UILabel()
        thridTipLabel.font = UIFont.systemFont(ofSize: 14)
        thridTipLabel.text = ":"
        thridTipLabel.textAlignment = .center
        thridTipLabel.textColor = .white
        return thridTipLabel
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(dayLabel)
        self.addSubview(hourLabel)
        self.addSubview(minuteLabel)
        self.addSubview(secondsLabel)
        self.addSubview(firstTipLabel)
        self.addSubview(secondTipLabel)
        self.addSubview(thridTipLabel)
        
        dayLabel.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(self)
            make.height.equalTo(20)
        }
        firstTipLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(dayLabel.snp.right)
            make.width.height.equalTo(20)
        }
        hourLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(firstTipLabel.snp.right)
            make.height.equalTo(dayLabel)
        }
        secondTipLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(hourLabel.snp.right)
            make.height.equalTo(20)
            make.width.equalTo(5)
        }
        minuteLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(secondTipLabel.snp.right)
            make.height.equalTo(dayLabel)
        }
        thridTipLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(minuteLabel.snp.right)
            make.height.equalTo(20)
            make.width.equalTo(5)
        }
        secondsLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(self)
            make.left.equalTo(thridTipLabel.snp.right)
            make.height.equalTo(dayLabel)
            make.right.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
