//
//  SlideMenuViewController.swift
//  storefront-ios
//
//  Created by Kam on 22/3/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

protocol MenuItemClickProtocol {
    func showQRCode()
    func scanQRCode()
    func goToMyProfile()
}

class SlideMenuViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet var menuCollectionView: UICollectionView!
    @IBOutlet var userView: UIView!
    @IBOutlet var myQRCode: UIView! {
        didSet {
            myQRCode.track_consoleTitle = "我的二维码"
        }
    }
    @IBOutlet var scanQRView: UIView!
    @IBOutlet var scanLabel :UILabel! {
        didSet {
            scanLabel.text = String.localize("LB_CA_IM_SCAN_QR")
        }
    }
    @IBOutlet var meImageView: UIImageView! {
        didSet {
            meImageView.round(meImageView.width/2.0)
        }
    }
    @IBOutlet var meNameLabel: UILabel!
    @IBOutlet var meVIPLabel: UILabel!
    
    @IBOutlet weak var leftLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var QRCodeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scanQRBottomConstraint: NSLayoutConstraint!
    
    private var startX: CGFloat = 0
    private var intervalValue: CGFloat = 0
    private let viewInterval: CGFloat = 240
    
    override func track_support() -> Bool {
        return true
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .custom
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
    }
    
    var layout: MMCollectionViewLayout {
        get {
            var config = MMLayoutConfig()
            config.rowHeight = 44
            config.floating = true
            let _layout = MMCollectionViewLayout(MMLayoutConfig())
            return _layout
        }
    }
    
    var me: User? {
        get {
            if LoginManager.isValidUser() {
                return Context.getUserProfile()
            }
            return nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLeftViewAnimation()
    }
    
    override func viewDidLoad() {
        //写死埋点url
        self._node = VCNode()
        self._node.auth = true
        self._node.controller = "SlideMenuViewController"
        self._node.url = Navigator.mymm.main_menu
        self._node.path = "menu"
        
        super.viewDidLoad()
        self.leftLeadingConstraint.constant = -(viewInterval)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        self.QRCodeTopConstraint.constant = IsIphoneX ? ScreenTop + 35 : 35
        self.scanQRBottomConstraint.constant = ScreenBottom
        
        self.loadMyProfile()
        
        menuCollectionView.register(UINib(nibName: "SlideMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "SlideMenuCollectionViewCell")
        menuCollectionView.collectionViewLayout = layout
        
        let userTapGes = UITapGestureRecognizer(target: self, action:  #selector(self.goToMyProfile))
        userView.addGestureRecognizer(userTapGes)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapCloseAnimationGes))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        let scanTapGes = UITapGestureRecognizer(target: self, action:  #selector(self.scanQRCode))
        scanQRView.addGestureRecognizer(scanTapGes)

        didBadgeUpdate()
        
        menuCollectionView.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.userView)
            make.top.equalTo(self.userView.snp.bottom).offset(36)
            make.bottom.equalTo(self.scanQRView.snp.top).offset(-18)
        }
        
    }
    
    @objc private func loadMyProfile() {
        meImageView.round()
        if let user = self.me {
            meNameLabel.text = user.displayName
            meImageView.mm_setImageWithURL(ImageURLFactory.URLSize128(user.profileImage, category: .user), placeholderImage: UIImage(named: "default_profile_icon"))
            
            self.retreiveLoyalty()
        } else {
            meNameLabel.text = String.localize("LB_LOGIN")
        }
    }
    
    private func retreiveLoyalty() {
        LoyaltyManager.handleListLoyaltyStatus(success: { [weak self] (loyalties) in
            if let strongSelf = self{
                let filterLoyalties = loyalties.filter{$0.loyaltyStatusId == strongSelf.me?.loyaltyStatusId}
                strongSelf.showLoyalty(filterLoyalties.first)
            }
            }, failure: { (errorType) in
                
        })
    }
    
    private func showLoyalty(_ loyalty: Loyalty?) {
        let multipleAttributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.foregroundColor: UIColor.lightGray,
            NSAttributedStringKey.font: UIFont.systemFontWithSize(12)]
        let fullString = NSMutableAttributedString(string: "", attributes: multipleAttributes)
        let imgAttachment = NSTextAttachment()
        if let loyalty = loyalty {
            imgAttachment.image = UIImage(named: loyaltyIcon(statusCode: loyalty.loyaltyStatusCode))
            imgAttachment.bounds = CGRect(x: 0, y:0, width: 20, height: 14)
            fullString.append(NSAttributedString(attachment: imgAttachment))
            fullString.append(NSAttributedString(string: " "))
            fullString.append(NSAttributedString(string: loyalty.memberLoyaltyStatusName))
            meVIPLabel.attributedText = fullString
        }
    }
    
    private func loyaltyIcon(statusCode: String) -> String {
        switch statusCode {
        case LoyaltyStatusCodeLevel.standard.rawValue:
            return "icon_vip_standard"
        case LoyaltyStatusCodeLevel.ruby.rawValue:
            return "icon_vip_ruby"
        case LoyaltyStatusCodeLevel.silver.rawValue:
            return "icon_vip_silver"
        case LoyaltyStatusCodeLevel.gold.rawValue:
            return "icon_vip_gold"
        case LoyaltyStatusCodeLevel.platinum.rawValue:
            return "icon_vip_platinum"
        default:
            return "icon_vip_standard"
        }
    }
    
    @objc private func didBadgeUpdate() {
        var indexPaths = [IndexPath]()
        indexPaths.append(IndexPath(row: MENU_ITEM_TYPE.notification.rawValue, section: 0))
//        indexPaths.append(IndexPath(row: MENU_ITEM_TYPE.chat.rawValue, section: 0))
        indexPaths.append(IndexPath(row: MENU_ITEM_TYPE.coupon.rawValue, section: 0))
        self.menuCollectionView.reloadItems(at: indexPaths)
    }
    
    @objc private func tapCloseAnimationGes(ges: UITapGestureRecognizer) {
        let touchPoint = ges.location(in: self.view)
        if touchPoint.x > viewInterval {
            closeLeftViewAnimation(nil)
        }
    }
    
    private func closeLeftViewAnimation(_ completion:(() -> Void)?) {
        var timeInterval:CGFloat = 0.3
        if self.intervalValue < 0 {
            timeInterval = (viewInterval + self.intervalValue)/viewInterval*timeInterval
        }
        UIView.animate(withDuration: TimeInterval(timeInterval), animations: {
            self.leftLeadingConstraint.constant = -self.viewInterval
            self.view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.0)
            self.view.layoutIfNeeded()
        }) { (success) in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    private func startLeftViewAnimation() {
        var timeInterval:CGFloat = 0.3
        if self.intervalValue < 0 {
            timeInterval = (-self.intervalValue)/viewInterval*timeInterval
        }
        UIView.animate(withDuration: TimeInterval(timeInterval)) {
            self.leftLeadingConstraint.constant = 0
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            self.view.layoutIfNeeded()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            if let touch = touches.first {
                let moveLocation = touch.location(in: self.view)
                self.intervalValue = moveLocation.x - self.startX
                if self.intervalValue < 0 {
                    self.leftLeadingConstraint.constant = self.intervalValue
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(((viewInterval + self.intervalValue)/viewInterval)*0.3)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            if let touch = touches.first {
                let startLocation = touch.location(in: self.view)
                self.startX = startLocation.x
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.intervalValue < -100 {
            closeLeftViewAnimation(nil)
        } else {
            startLeftViewAnimation()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let touchView = touch.view {
            if touchView == self.view {
                return true
            }
        }
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("[deinit classname] : \(self.classForCoder)")
    }
}

extension SlideMenuViewController: MMCollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MENU_ITEM_TYPE.count.rawValue
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlideMenuCollectionViewCell", for: indexPath) as! SlideMenuCollectionViewCell
        cell.setData(index: indexPath.row)
        return cell
    }
    
    //可以漂浮停靠在界面顶部
    @objc func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return true
        }
        return false
    }
    
    //cell的行高,若scrollDirection == .horizontal则返回的是宽度
    @objc func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = MENU_ITEM_TYPE(rawValue: indexPath.row) {
            dismiss(animated: false) {
                if item == .post {
                    PopManager.sharedInstance.selectPost()
                } else {
                    _ = Navigator.shared.dopen(item.deeplink, modal: item.isModal)
                }
            }
        }
    }
}

extension SlideMenuViewController: MenuItemClickProtocol {
    @IBAction func showQRCode() {
        dismiss(animated: false) {
            let qrCodeViewController = MyQRCodeViewController()
            qrCodeViewController.modalPresentationStyle = .overFullScreen
            qrCodeViewController.modalTransitionStyle = .crossDissolve
            self.mm_tabbarController?.present(qrCodeViewController, animated: true, completion: nil)
        }
    }
    
    @objc func scanQRCode() {
        dismiss(animated: false) {
            Navigator.shared.dopen(Navigator.mymm.user_qrcode_scan)
        }
    }
    
    @objc func goToMyProfile() {
        self.closeLeftViewAnimation {
            self.mm_tabbarController?.setSelectIndex(index: MMTabBarType.minePage.rawValue)
        }
    }
}


