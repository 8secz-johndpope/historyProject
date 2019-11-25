//
//  ContactUsDetailViewController.swift
//  merchant-ios
//
//  Created by Markus Chow on 14/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import UIKit

class ContactUsDetailViewController: AboutDetailViewController {
	
	var chatView : UIView!
	
	private let chatViewHeight : CGFloat = 110
	
	private let iconSize : CGFloat = 38
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupChatView()
	}
	
	func setupChatView() {

		let statusBarHeight = UIApplication.shared.statusBarFrame.height
		var navigationBarHeight : CGFloat = statusBarHeight
		if let navigationController = self.navigationController {
			navigationBarHeight += navigationController.navigationBar.height
		}

		chatView = UIView(frame: CGRect(x: 0, y: navigationBarHeight, width: Constants.ScreenSize.SCREEN_WIDTH, height: chatViewHeight))
		chatView.backgroundColor = UIColor.backgroundGray()
		
		let clientContactView = UIView(frame: CGRect(x: 0, y: 10, width: Constants.ScreenSize.SCREEN_WIDTH / 2, height: chatViewHeight - 20))
		clientContactView.backgroundColor = UIColor.white
		clientContactView.isUserInteractionEnabled = true
		clientContactView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ContactUsDetailViewController.startConvForClient)))
		chatView.addSubview(clientContactView)
		
		let clientIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
		clientIcon.image = UIImage(named: "icon_CS_customer")
		clientIcon.center = clientContactView.center
		clientIcon.frame = CGRect(x: clientIcon.frame.originX, y: 6, width: iconSize, height: iconSize)
		clientContactView.addSubview(clientIcon)

		let clientTitle = UILabel(frame: CGRect(x: 0, y: clientIcon.frame.maxY, width: clientContactView.frame.width, height: 20))
		clientTitle.font = UIFont.boldSystemFont(ofSize: 14.0)
		clientTitle.text = String.localize("LB_CA_CONTACT_US_USER_CS")
		clientTitle.setStyle()
		clientContactView.addSubview(clientTitle)
		
		let clientDesc = UILabel(frame: CGRect(x: 0, y: clientTitle.frame.maxY, width: clientContactView.frame.width, height: 20))
		clientDesc.font = UIFont.systemFont(ofSize: 12.0)
		clientDesc.text = String.localize("LB_CA_CONTACT_US_USER_CS_DESC")
		clientDesc.setStyle()
		clientContactView.addSubview(clientDesc)

		// vertical line
		let borderViewVerticalMargin: CGFloat = 12
		let borderView = UIView(frame: CGRect(x: clientContactView.frame.size.width - 1, y: borderViewVerticalMargin, width: 1, height: clientContactView.frame.size.height - (borderViewVerticalMargin * 2)))
		borderView.backgroundColor = UIColor.primary2()
		clientContactView.addSubview(borderView)

		let merchantContactView = UIView(frame: CGRect(x: Constants.ScreenSize.SCREEN_WIDTH / 2, y: 10, width: Constants.ScreenSize.SCREEN_WIDTH / 2, height: chatViewHeight - 20))
		merchantContactView.backgroundColor = UIColor.white
		merchantContactView.isUserInteractionEnabled = true
		merchantContactView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ContactUsDetailViewController.startConvForMerchant)))
		chatView.addSubview(merchantContactView)

		let merchantIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: iconSize, height: iconSize))
		merchantIcon.image = UIImage(named: "icon_CS_business")
		merchantIcon.center = clientContactView.center
		merchantIcon.frame = CGRect(x: merchantIcon.frame.originX, y: 6, width: iconSize, height: iconSize)
		merchantContactView.addSubview(merchantIcon)
		
		let merchantTitle = UILabel(frame: CGRect(x: 0, y: merchantIcon.frame.maxY, width: clientContactView.frame.width, height: 20))
		merchantTitle.font = UIFont.boldSystemFont(ofSize: 14.0)
		merchantTitle.text = String.localize("LB_CA_CONTACT_US_MERCH_CS")
		merchantTitle.setStyle()
		merchantContactView.addSubview(merchantTitle)
		
		let merchantDesc = UILabel(frame: CGRect(x: 0, y: merchantTitle.frame.maxY, width: clientContactView.frame.width, height: 20))
		merchantDesc.font = UIFont.systemFont(ofSize: 12.0)
		merchantDesc.text = String.localize("LB_CA_CONTACT_US_MERCH_CS_DESC")
		merchantDesc.setStyle()
		merchantContactView.addSubview(merchantDesc)

		self.view.addSubview(chatView)
		
		// Re-position webview
		var rect = self.webview.frame
        rect.origin.y += chatViewHeight + (IsIphoneX ? 24 : 0)
		rect.size.height -= chatViewHeight + (IsIphoneX ? 24 : 0)
		self.webview.frame = rect
        self.webview.scrollView.delegate = self
		self.webview.scrollView.bounces = false
	}
	
	@objc func startConvForClient() {
		self.startConvToMM(.General)
	}

	@objc func startConvForMerchant() {
		self.startConvToMM(.Business)
	}

	func startConvToMM(_ queue: QueueType) {
		let myRole: UserRole = UserRole(userKey: Context.getUserKey())
		
		WebSocketManager.sharedInstance().sendMessage(
			IMConvStartToCSMessage(
				userList: [myRole],
				queue: queue,
				senderMerchantId: myRole.merchantId,
				merchantId: Constants.MMMerchantId
			),
			checkNetwork: true,
			viewController: self,
			completion: { [weak self] (ack) in
				if let strongSelf = self {
					if let convKey = ack.data {
						let viewController = UserChatViewController(convKey: convKey)
						strongSelf.navigationController?.pushViewController(viewController, animated: true)
					}
				}
			}
		)
	}
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension UILabel {
	func setStyle() {
		self.textAlignment = .center
		self.textColor = UIColor.secondary4()
	}
}
