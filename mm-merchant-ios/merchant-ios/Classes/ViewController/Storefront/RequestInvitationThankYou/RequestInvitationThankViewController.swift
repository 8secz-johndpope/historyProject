//
//  RequestInvitationThankViewController.swift
//  merchant-ios
//
//  Created by LongTa on 7/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class RequestInvitationThankViewController: MmViewController {

    let thankYouView = RequestInvitationThankView()
    var selectedCountry:GeoCountry?
    var mobileNo:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_LAUNCH_INVITATION_CODE_DONE")

        self.hideBackButton(true)
        self.addBackButton()
        
        thankYouView.wechatFollowButton.addTarget(self, action: #selector(self.wechatFollowingButtonTapped), for: .touchUpInside)
        self.setupLayout()
        
        if let selectedCountry = self.selectedCountry, let mobileNo = self.mobileNo{
            self.thankYouView.phoneNumberLabel.text = selectedCountry.mobileCode + " " + mobileNo
        }
        initAnalyticLog()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideBackButton(false)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    //MARK:
    func hideBackButton(_ isHide: Bool){
        self.navigationItem.setHidesBackButton(isHide, animated:false);
    }
    
    func addBackButton(){
        self.createRightButton(String.localize("LB_OK"), action:  #selector(RequestInvitationThankViewController.backToRoot))
    }
    
    @objc func backToRoot(_ sender: UIButton){
        if let navigationController = self.navigationController{
            let exclusiveViewController:UIViewController = navigationController.viewControllers[navigationController.viewControllers.count - 3]
                if exclusiveViewController.isKind(of: ExclusiveViewController.self){
                    navigationController.pop(to: exclusiveViewController, animated: false)
                    
                    //record button action
                    sender.recordAction(
                        .Tap,
                        sourceRef: "OK",
                        sourceType: .Button,
                        targetRef: "Starting",
                        targetType: .Page
                    )
                }
        }
    }
    
    func setupLayout(){
        thankYouView.frame = self.view.bounds
        self.view.addSubview(thankYouView)
    }
    
    @objc func wechatFollowingButtonTapped(_ sender: UIButton){
        UIPasteboard.general.string = "MyMMStyle"
        WXApi.openWXApp()
        
        //record button action
        sender.recordAction(
            .Tap,
            sourceRef: "CopyMyMMWeChat",
            sourceType: .Button,
            targetRef: "WeChat",
            targetType: .Redirection
        )
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            viewLocation: "GetInvitationCodeThanks",
            viewType: "ExclusiveLaunch"
        )
    }
}
