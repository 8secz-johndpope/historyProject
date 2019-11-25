//
//  ExclusiveViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import JPSVolumeButtonHandler
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ExclusiveViewController: SignupModeViewController, UITextFieldDelegate, UINavigationControllerDelegate, WeChatAuthDelegate {
    
    enum ChangeSettingAction : Int{
        case host = 0,
        cdn,
        webSocket
    }
	
	var crossView : UIView!
	
    let exclusiveView = ExclusiveView()
    let loginBar = LoginBar()
    var isShowingKeyboard = false
    var preloadedInvitationCode: String = "" {
        didSet{
            self.exclusiveView.textFieldInviteCode.text = preloadedInvitationCode
            if preloadedInvitationCode.length > 0 {
                self.exclusiveView.textFieldInviteCode.textAlignment = .left
            } else {
                self.exclusiveView.textFieldInviteCode.textAlignment = .center
            }
            self.exclusiveView.updateStatusForConfirmButton()
        }
    }
    static var loadedInstance : ExclusiveViewController?
    
    convenience init(){
        self.init(nibName: nil, bundle: nil)
        ExclusiveViewController.loadedInstance = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createBackButton()

        self.setupLayout()
        self.view.addSubview(self.exclusiveView)
        self.view.addSubview(self.loginBar)
        self.exclusiveView.textFieldInviteCode.text = preloadedInvitationCode
        self.exclusiveView.textFieldInviteCode.addTarget(self, action: #selector(self.textFieldInviteCodeDidChanged), for: .editingChanged)
        self.exclusiveView.updateStatusForConfirmButton()
        self.initAnalyticLog()
        
        self.exclusiveView.guestButton.addTarget(self, action:#selector(self.guestModeLogin), for: .touchUpInside )
        // Do any additional setup after loading the view.
        
        if LoginManager.isGuestUser() {
        
            self.createCloseButton()
            
            self.exclusiveView.guestButton.isHidden = true
            
        }
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.delegate = self
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.setupShowKeyboard()
//        NotificationCenter.default.addObserver(self, selector: #selector(loginWeChat(_:)), name: "LoginWeChat", object: nil)
        
        WeChatManager.sharedInstance().delegate = self
        
        
        if !Context.hasShownTutorialSpash() {
            self.present(TutorialSplashController(nibName: "TutorialSplashController", bundle: nil), animated: true, completion: nil)
        }

    }
	
	func createCloseButton() {
		
		crossView = { () -> UIView in
			
			let buttonWidth = CGFloat(30)
			let buttonHeight = CGFloat(30)
			let buttonPadding = CGFloat(5)
			let viewTopPadding = CGFloat(20)
			let viewRightPadding = CGFloat(5)
			let viewWidth = buttonWidth + 2*buttonPadding
			let viewWHeight = buttonHeight + 2*buttonPadding
			let view = UIView (frame: CGRect(x: self.view.frame.size.width - viewWidth - viewRightPadding, y: viewTopPadding, width: viewWidth, height: viewWHeight))
			let button = UIButton(type: .custom)
			button.setImage(UIImage(named: "icon_cross"), for: UIControlState())
			button.frame = CGRect(x: buttonPadding, y: buttonPadding, width: buttonWidth, height: buttonHeight)
//            button.addTarget(self, action: #selector(LoginViewController.closeButtonTapped), for: .touchUpInside)
			view.addSubview(button)
			
			return view
		} ()
		self.exclusiveView.addSubview(crossView)
	}
	
	func closeButtonTapped () {
		self.dismiss(animated: true, completion: nil)
	}
	
    func handleWeChatCallback(_ authResponseCode: String){
        self.loginWeChatWithCode(authResponseCode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.navigationController?.delegate = nil
        self.setupHideKeyboard()
//        NotificationCenter.default.removeObserver(self, name: "LoginWeChat", object: nil)
    }
    
    override func setupVolumeButtonHandler() {
        self.volumeButtonHandler = JPSVolumeButtonHandler(up: {
            self.navigationController?.push(InterestCategoryPickViewController(), animated: true)
        }, downBlock: {
            
        })
    }
    
    func setupShowKeyboard(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    func setupHideKeyboard(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupLayout(){
        self.exclusiveView.frame = self.view.bounds
        self.exclusiveView.textFieldInviteCode.delegate  = self
        self.exclusiveView.buttonConfirm.addTarget(self, action: #selector(self.didClickConfirmButton), for: UIControlEvents.touchUpInside)
        self.exclusiveView.buttonConfirm.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.exclusiveView.buttonInvite.addTarget(self, action: #selector(self.didClickInviteCodeButton), for: UIControlEvents.touchUpInside)
        self.exclusiveView.buttonInvite.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.exclusiveView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss as () -> Void)))
        self.loginBar.buttonLogin.addTarget(self, action: #selector(self.didClickMobileLogin), for: UIControlEvents.touchUpInside)
        self.loginBar.buttonLogin.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.loginBar.frame = self.view.bounds
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.exclusiveView.textFieldInviteCode.text?.length > 0 {
            self.exclusiveView.textFieldInviteCode.textAlignment = .left
        } else {
            self.exclusiveView.clearPlaceHolder(false)
            self.exclusiveView.textFieldInviteCode.textAlignment = .center
        }
        self.updateConfirmButton()
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        if self.exclusiveView.textFieldInviteCode.text?.length > 0 {
//            self.exclusiveView.textFieldInviteCode.textAlignment = .Left
//        } else {
//            self.exclusiveView.textFieldInviteCode.textAlignment = .center
//        }
        self.exclusiveView.textFieldInviteCode.textAlignment = .left
        self.exclusiveView.clearPlaceHolder(true)
        return true
    }
    
    @objc func textFieldInviteCodeDidChanged(_ textField: UITextField){
//        if self.exclusiveView.textFieldInviteCode.text?.length > 0 {
//            self.exclusiveView.textFieldInviteCode.textAlignment = .Left
//            
//        } else {
//            self.exclusiveView.textFieldInviteCode.textAlignment = .center
//        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
         Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateConfirmButton), userInfo: nil, repeats: false)
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.exclusiveView.textFieldInviteCode.text = ""
        self.exclusiveView.updateStatusForConfirmButton()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func updateConfirmButton(){
        self.exclusiveView.updateStatusForConfirmButton()
    }
    
    @objc func dismiss() {
        self.view.endEditing(true)
    }
    
    
    
    //MARK: Actions region
    
    
    @objc func guestModeLogin(_ button : UIButton) {
        LoginManager.guestLogin()
//        LoginManager.goToStorefront()
    }
    
    @objc func didClickMobileLogin(_ button: UIButton) {
        self.dismiss()
        self.setupHideKeyboard()
        self.mobileLogin(button)
        button.recordAction(.Tap, sourceRef: "Login", sourceType: .Link, targetRef: "Login", targetType: .Table)
    }
    
    @objc func didClickConfirmButton(_ button: UIButton) {
        if let inviteCode = self.exclusiveView.textFieldInviteCode.text?.trim(){
            if inviteCode.length > 0 {
                self.dismiss()
                self.checkInviteCode(inviteCode)
                
                button.recordAction(.Tap, sourceRef: "Submit", sourceType: .Button, targetRef: inviteCode, targetType: .InvitationCode)
            }
        }
    }

    @objc func didClickInviteCodeButton(_ button: UIButton) {
        self.dismiss()
        Log.debug("didClickDontHaveInviteCodeButton")
        button.recordAction(.Tap, sourceRef: "GetInvitationCode", sourceType: .Link, targetRef: "GetInvitationCode", targetType: .View)
        let requestInvitationCodeViewController = RequestInvitationCodeViewController()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.push(requestInvitationCodeViewController, animated: true)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if isShowingKeyboard {
            return
        }
        if let userInfo = sender.userInfo {
            self.isShowingKeyboard = true
            let keyboardRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).uint32Value
            let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16 | UIViewAnimationOptions.beginFromCurrentState.rawValue)
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let offset =  (keyboardRect.height - (self.view.frame.size.height - self.exclusiveView.buttonInvite.frame.maxY))
            var frame = self.exclusiveView.viewContent.frame
            if offset > 0 {
                frame.origin.y =  -offset
            }
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    self.exclusiveView.viewContent.frame = frame
                },
                completion: { bool in
                    
            })
        }
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        if !self.isShowingKeyboard {
            return
        }
        if let userInfo = sender.userInfo {
            self.isShowingKeyboard = false
            let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber).uint32Value
            let options = UIViewAnimationOptions(rawValue: UInt(curve) << 16 | UIViewAnimationOptions.beginFromCurrentState.rawValue)
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey]! as! Double
            var frame = self.exclusiveView.viewContent.frame
            frame.origin.y = 0
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: options,
                animations: {
                    self.exclusiveView.viewContent.frame = frame
                },
                completion: { bool in
                    
                    
            })
        }
    }

    func checkInviteCode(_ inviteCode: String) {
      
        firstly {
            return checkInviteCodeService(inviteCode)
        }.then { _ -> Void in
            
            
            let invitationCodeSuccessfulViewController = InvitationCodeSuccessfulViewController()
            invitationCodeSuccessfulViewController.signupMode = self.signupMode
            Context.setInvitationCode(inviteCode)
            self.navigationController?.pushViewController(invitationCodeSuccessfulViewController, animated: true)
            

        }.always {

        }.catch { error -> Void in
        // MARK: As we should already handled the error, checkInviteCodeService
//                self.showNetworkError(error, animated: true)
                self.exclusiveView.buttonConfirm.transformToState(CircularProgressButtonState.normal)
        }
    }
    
    let delayDisplayAfterInvitationCodeAPI = 0.6
    
    func checkInviteCodeService(_ inviteCode: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            InviteService.checkInviteCode(inviteCode, completion: {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        
                        Timer.after(strongSelf.delayDisplayAfterInvitationCodeAPI) {
                            if response.response?.statusCode == 200 {
                                fulfill("OK")
                            } else {
                                strongSelf.handleError(response, animated: true, reject: reject)
                            }
                        }
                    } else{
                        strongSelf.handleError(response, animated: true, reject: reject)
                    }
                }
            })
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push && toVC.isKind(of: InvitationCodeSuccessfulViewController.self)  {
            return PushFadingAnimator()
        }
        return nil
    }
    //MARK: Mobile Login Delegate
    override func didDismissLogin() {
        self.setupShowKeyboard()
    }
    
    // MARK: Tagging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "Starting",
            viewRef: nil,
            viewType: "ExclusiveLaunch"
        )
    }

}
