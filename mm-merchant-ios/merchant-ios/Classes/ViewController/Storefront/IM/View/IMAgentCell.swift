//
//  IMAgentCell.swift
//  merchant-ios
//
//  Created by Vo Huy Hung on 5/9/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class IMAgentCell: UICollectionViewCell {
    
    private final let CenterViewWidth : CGFloat = 76
    private final let RightViewWidth : CGFloat = 62
    
    var merchantColorImageView :  UIImageView!
    var logoImageView :  UIImageView!
    var agentNameLabel :  UILabel!
//    var agentStatusLabel :  UILabel!
//    var agentStatusIcon :  UIImageView!
    var agentQueueLabel :  UILabel!
    var agentQueueNumber :  UILabel!
    var agentQueueButton : UIButton!
    
    var pickUpTappedHandler: ((_ cell: IMAgentCell, _ merchant: Merchant) -> Void)?
    
    var data: Merchant? {
        didSet {
            if let data = self.data {
                
                if data.merchantId != Constants.MMMerchantId { // not MM
                    logoImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(data.headerLogoImage, category: .merchant), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFit)
                } else {
                    self.logoImageView.image = Merchant().MMImageIconBlack
                }

                self.agentNameLabel.text = data.merchantCompanyName +  String.localize("LB_CA_CS_SETTING")
                
                self.agentQueueNumber.text = "-"
                
                self.agentQueueButton.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
                agentQueueButton.formatPrimary()
                
                if let merchantColor = Context.customerServiceMerchants().merchantColorForId(data.merchantId) {
                    self.merchantColorImageView.backgroundColor = merchantColor
                        self.merchantColorImageView.isHidden = false
                } else {
                    self.merchantColorImageView.isHidden = true
                }
            }
        }
    }
    
    func displayNumberOfPreSales(_ noOfPreSales : Int) {
        if noOfPreSales > 0 {
            self.agentQueueButton.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
            self.agentQueueButton.formatPrimary()
            self.agentQueueButton.isEnabled = true
            self.agentQueueNumber.text = "\(noOfPreSales)"
        } else {
            self.agentQueueButton.setTitle("+ \(String.localize("LB_CA_CS_GET_NEXT"))", for: UIControlState())
            self.agentQueueButton.formatPrimary()
            self.agentQueueButton.layer.backgroundColor = UIColor.secondary1().cgColor
            self.agentQueueButton.isEnabled = false
            self.agentQueueNumber.text = "0"
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(hexString:"#717171")
        
        let containerView = { () -> UIView in
            
            let paddingLeft = CGFloat(9)
            let paddingBottom = CGFloat(5)
            
            let aContainerView = UIView(frame: CGRect(x: paddingLeft, y: 0, width: frame.size.width - 2*paddingLeft, height: frame.size.height - paddingBottom))
            
            // left view
            let leftView = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: aContainerView.frame.width - CenterViewWidth - RightViewWidth, height: aContainerView.frame.height))
                
                merchantColorImageView = { () -> UIImageView in
                    
                    let imgeViewSize = CGSize(width: 10, height: 10)
                    let padding = CGFloat(5)
                    let imgView = UIImageView(frame:CGRect(x: padding, y: (view.bounds.height - imgeViewSize.height) / 2, width: imgeViewSize.width, height: imgeViewSize.height))
                    imgView.clipsToBounds = true
                    imgView.layer.cornerRadius = 3
                    return imgView
                    } ()
                view.addSubview(merchantColorImageView)
                
                logoImageView = { () -> UIImageView in
                    let imgView = UIImageView()
                    let paddingLeft = CGFloat(5)
                    let paddingTop = CGFloat(10)
                    imgView.frame = CGRect(x: merchantColorImageView.frame.maxX + paddingLeft, y: paddingTop, width: view.bounds.height - 2*paddingTop, height: view.bounds.height - 2*paddingTop)
                    imgView.clipsToBounds = true
                    imgView.contentMode = .scaleAspectFit
                    imgView.layer.cornerRadius = 3
                    return imgView
                    } ()
                view.addSubview(logoImageView)
                
                agentNameLabel = { () -> UILabel in
                    let label = UILabel()
                    let paddingLeft = CGFloat(7)
                    label.frame = CGRect(x: paddingLeft + logoImageView.frame.maxX, y: 0, width: view.frame.width - logoImageView.frame.maxX -  paddingLeft, height: view.frame.height)
                    label.font = UIFont.usernameFont()
                    label.textColor = .black
                    label.lineBreakMode = NSLineBreakMode.byTruncatingTail
                    label.numberOfLines = 2
                    return label
                    } ()
                view.addSubview(agentNameLabel)                
                return view
            }()
            aContainerView.addSubview(leftView)
            
            // center view
            let centerView = { () -> UIView in
                
                let view = UIView(frame: CGRect(x: aContainerView.frame.width - RightViewWidth - CenterViewWidth, y: 0, width: CenterViewWidth, height: aContainerView.frame.height))
            
                agentQueueButton = { () -> UIButton in
                    let button = UIButton(type: .custom)
                    button.formatPrimary()
                    let buttonHeight = CGFloat(32)
                    let paddingLeft = CGFloat(3)
                    let paddingRight = CGFloat(10)
                    button.frame = CGRect(x: paddingLeft, y: (view.frame.height - buttonHeight)/2, width: view.frame.width - paddingLeft - paddingRight, height: buttonHeight)
                    
                    button.addTarget(self, action: #selector(agentQueueTapped), for: .touchUpInside)
                    
                    return button
                    } ()
                view.addSubview(agentQueueButton)
                
                
                
                return view
            }()
            aContainerView.addSubview(centerView)
            

            // right view
            let rightView = { () -> UIView in
                
                let agentQueueWidth = CGFloat(40)
                let agentQueueHeight = CGFloat(18)
                let arrowWidth = CGFloat(7)
                let arrowHeight = CGFloat(15)
                
                let view = UIView(frame: CGRect(x: aContainerView.frame.width - RightViewWidth, y: 0, width: RightViewWidth, height: aContainerView.frame.height))
                
                let verticalLineImageView = UIImageView(frame: CGRect(x: 0, y: 5, width: 1, height: view.frame.height - 10))
                verticalLineImageView.backgroundColor = UIColor.secondary1()
                view.addSubview(verticalLineImageView)
                
                agentQueueLabel = { () -> UILabel in
                    let label = UILabel()
                    let paddingLeft = CGFloat(5)
                    let paddingTop = CGFloat(11)
                    label.frame = CGRect(x: paddingLeft, y: paddingTop, width: agentQueueWidth, height: agentQueueHeight)
                    label.text = String.localize("LB_CA_CS_UNANS")
                    label.formatSize(12)
                    return label
                    } ()
                view.addSubview(agentQueueLabel)
                
                agentQueueNumber = { () -> UILabel in
                    let label = UILabel()
                    let paddingTop = CGFloat(4)
                    label.frame = CGRect(x: agentQueueLabel.frame.originX, y: agentQueueLabel.frame.maxY + paddingTop, width: agentQueueWidth, height: agentQueueHeight)
                    label.formatSizeBold(14)
                    label.textAlignment = .center
                    return label
                    } ()
                view.addSubview(agentQueueNumber)
                
                let arrowImageView = UIImageView(frame: CGRect(x: agentQueueLabel.frame.maxX + 3, y: (view.frame.height - arrowHeight)/2, width: arrowWidth, height: arrowHeight))
                arrowImageView.image = UIImage(named: "icon_arrow")
                arrowImageView.contentMode = .scaleAspectFit
                view.addSubview(arrowImageView)
                
                return view
            }()
            
            aContainerView.addSubview(rightView)
            
            aContainerView.backgroundColor = UIColor.white
            aContainerView.layer.cornerRadius = 3.0
            aContainerView.clipsToBounds = true
            
            return aContainerView
        } ()
        
        contentView.addSubview(containerView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func agentQueueTapped(){
        if let callback = self.pickUpTappedHandler, let merchant = self.data {
            callback(self, merchant)
        }
    }
    
}
