//
//  StylePriceCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/9/4.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class StylePriceCell: UICollectionViewCell {
    static public let CellIdentifier = "StylePriceCell"
    static public let CellHeight: CGFloat = 36
    private var timer: Timer? = nil
    private var seconds = 0
    var dateSaleFrom: Date? = nil
    var dateSaleTo: Date? = nil {
        didSet{
            if let dateSaleTo = self.dateSaleTo, dateSaleTo > Date() {
                seconds = Int(dateSaleTo.timeIntervalSinceNow)
                start()
            } else {
                timeView.isHidden = true
                timeTipLabel.isHidden = true
            }
        }
    }
    var sku: Sku?{
        didSet{
            if let sku = sku{
                self.dateSaleFrom = sku.flashSaleFrom
                self.dateSaleTo = sku.flashSaleTo
            }
        }
    }
    var noSale:Bool? {
        didSet {
            if let sale = noSale {
                if sale {
                    priceLabel.textColor = UIColor(hexString: "#ED2247")
                } else {
                    priceLabel.textColor = UIColor.black
                }
            }
        }
    }
    var price:String? {
        didSet {
            if let str = price {
                priceLabel.text = str
            }
        }
    }

    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(priceLabel)
        self.contentView.addSubview(timeView)
        self.contentView.addSubview(timeTipLabel)

        
        priceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(14)
            make.centerY.equalTo(self.contentView)
        }
        timeView.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.right.equalTo(self.contentView).offset(-15)
            make.centerY.equalTo(self.contentView)
        }
        timeTipLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(timeView.snp.left).offset(-5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - private methods
    private func start()  {
        if timer != nil {
            timer?.invalidate()
        }
        
        let currentTime = TimestampService.defaultService.getServerTime() ?? Date()
        if let dateSaleTo = self.dateSaleTo, dateSaleTo > currentTime {
            
            seconds = Int(dateSaleTo.timeIntervalSinceNow)
            
            self.timeString(time: TimeInterval(self.seconds))
            let days = Int(self.seconds) / 86400
            if days == 0 {
                timeView.getPriceStyle = false
            }
            if days > 14 {
                self.timeView.isHidden = true
            } else {
                self.timeView.isHidden = false
            }
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
            
        } else {
            timeView.isHidden = true
        }
        timeTipLabel.isHidden = timeView.isHidden
    }
    
   private func timeString(time: TimeInterval)  {
        let days = Int(time) / 86400
        let hours = Int(time) / 3600 % 24
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        timeView.dayLabel.text = String(format:"%02i", days)
        timeView.hourLabel.text = String(format:"%02i", hours)
        timeView.minuteLabel.text = String(format:"%02i", minutes)
        timeView.secondsLabel.text = String(format:"%02i", seconds)
    }
    
    //MARK: - private methods
    @objc private func updateTimer() {
        if seconds < 1 {
            timer?.invalidate()
        } else {
            seconds -= 1
            DispatchQueue.main.async {
                self.timeString(time: TimeInterval(self.seconds))
            }
        }
    }
    
    //MARK: - lazy
    lazy private var priceLabel:UILabel = {
        let priceLabel = UILabel()
        priceLabel.textColor = UIColor(hexString: "#ED2247")
        priceLabel.font = UIFont.boldSystemFont(ofSize: 24)
        return priceLabel
    }()
    lazy private var timeTipLabel:UILabel = {
        let timeTipLabel = UILabel()
        timeTipLabel.textColor = UIColor.black
        timeTipLabel.text = "仅剩"
        timeTipLabel.font = UIFont.systemFont(ofSize: 14)
        timeTipLabel.isHidden = true
        return timeTipLabel
    }()
    lazy private var timeView:FlashTimeView = {
        let timeView = FlashTimeView()
        timeView.getPriceStyle = true
        timeView.isHidden = true
        return timeView
    }()
}
