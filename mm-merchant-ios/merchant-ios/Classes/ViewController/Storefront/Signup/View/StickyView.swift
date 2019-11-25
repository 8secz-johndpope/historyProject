//
//  StickyView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/6/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

enum StickyType: Int {
    case register = 0,
    referral
}

protocol StickyViewDelegate: NSObjectProtocol {
    func didTapOnRegisterView()
    func didTapOnReferralView()
}
class StickyView: UIView {
    private var imageView = UIImageView()
    static let StickySize = CGSize(width: 60, height: 72)
    var delegate: StickyViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        self.addSubview(imageView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: self.bounds.sizeWidth - StickyView.StickySize.width, y: (self.bounds.sizeHeight - StickyView.StickySize.height)/2, width: StickyView.StickySize.width, height: StickyView.StickySize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setupButton(_ type: StickyType) {
        switch type {
        case .register:
            imageView.image = UIImage(named: "btn_guestRegister")
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(StickyView.tapOnRegisterView)))
        case .referral:
            imageView.image = UIImage(named: "btn_userReferral")
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(StickyView.tapOnReferralView)))
        }
    }
    
    @objc func tapOnRegisterView() {
        delegate?.didTapOnRegisterView()
    }
    
    @objc func tapOnReferralView() {
        delegate?.didTapOnReferralView()
    }
    
}
