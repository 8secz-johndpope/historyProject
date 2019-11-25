//
//  NoConnectionView.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 12/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class NoConnectionView: UIView {

    var reloadHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let VerticalSpace = CGFloat(10)
        let WifiImageSize = CGSize(width: 51, height: 58)
        let ButtonReloadSize = CGSize(width: 80, height: 40)
        let ButtonReloadColor = UIColor.red
        
        let imgWifi = UIImageView(frame: CGRect(x: (frame.width - WifiImageSize.width) / 2.0, y: 0, width: WifiImageSize.width, height: WifiImageSize.height))
        imgWifi.image = UIImage(named: "wifi_icon")
        addSubview(imgWifi)
        
        let lblNoNetwork = UILabel(frame: CGRect(x: 0, y: imgWifi.frame.maxY + VerticalSpace, width: frame.width, height: 25))
        lblNoNetwork.font = UIFont.systemFont(ofSize: 20)
        lblNoNetwork.textAlignment = .center
        lblNoNetwork.text = String.localize("LB_CA_NETWORK_FAIL_PLACEHOLDER")
        lblNoNetwork.textColor = UIColor.black
        addSubview(lblNoNetwork)

        let lblCheckNetwork = UILabel(frame: CGRect(x: 0, y: lblNoNetwork.frame.maxY + VerticalSpace, width: frame.width, height: 25))
        lblCheckNetwork.font = UIFont.systemFont(ofSize: 15)
        lblCheckNetwork.textAlignment = .center
        lblCheckNetwork.text = String.localize("LB_CA_CHECK_NETWORK_SETTING")
        lblCheckNetwork.textColor = UIColor(hexString: "#7c7c7c")
        addSubview(lblCheckNetwork)

        let btnReload = UIButton(type: .custom)
        btnReload.frame = CGRect(x: (frame.width - ButtonReloadSize.width) / 2.0, y: lblCheckNetwork.frame.maxY + 2*VerticalSpace, width: ButtonReloadSize.width, height: ButtonReloadSize.height)
        btnReload.setTitle(String.localize("LB_CA_NETWORK_RELOAD"), for: UIControlState())
        btnReload.setTitle(String.localize("LB_CA_NETWORK_RELOAD"), for: .highlighted)
        btnReload.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnReload.setTitleColor(ButtonReloadColor, for: UIControlState())
        btnReload.layer.cornerRadius = 4
        btnReload.layer.borderWidth = 1
        btnReload.layer.borderColor = ButtonReloadColor.cgColor
        btnReload.addTarget(self, action: #selector(buttonReloadTapped), for: .touchUpInside)
        addSubview(btnReload)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonReloadTapped() {
        if self.superview != nil {
            self.removeFromSuperview()
        }
        
        reloadHandler?()
    }
}
