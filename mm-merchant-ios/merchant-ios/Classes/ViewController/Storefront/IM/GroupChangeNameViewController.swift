//
//  GroupChangeNameViewController.swift
//  merchant-ios
//
//  Created by HungPM on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class GroupChangeNameViewController: MmViewController, UITextFieldDelegate {
    
    private final var tfGroupName: UITextField!
    var groupName: String?
    var conv: Conv?
    
    var groupNameDidSave: ((_ name: String?) -> ())?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        let viewContainer = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: 84, width: Constants.ScreenSize.SCREEN_WIDTH, height: 50))
            
            let separatorViewTop = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1))
                view.backgroundColor = UIColor.secondary1()
                
                return view
            } ()
            
            view.addSubview(separatorViewTop)
            let separatorViewBottom = { () -> UIView in
                let view = UIView(frame: CGRect(x: 0, y: view.frame.height - 1, width: view.frame.width, height: 1))
                view.backgroundColor = UIColor.secondary1()
                
                return view
            } ()
            view.addSubview(separatorViewBottom)
            
            let Padding = CGFloat(10)
            tfGroupName = UITextField(frame: CGRect(x: Padding, y: Padding, width: view.frame.width - (2 * Padding), height: view.frame.height - (2 * Padding)))
            tfGroupName.clearButtonMode = .whileEditing
            tfGroupName.text = groupName
            tfGroupName.delegate = self
            view.addSubview(tfGroupName)

            return view
        }()
        view.addSubview(viewContainer)
    }

    func setupNavigationBar() {
        self.title = String.localize("LB_IM_CHAT_GROUP_NAME")
        self.createRightButton(String.localize("LB_CA_SAVE"), action: #selector(saveButtonTapped))
        
        let leftButton = UIButton(type: .custom)
        leftButton.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        leftButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        leftButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
    }

    // MARK: - Actions
    @objc func cancelButtonTapped() {
        Log.debug("cancelButtonTapped")
        tfGroupName.resignFirstResponder()

        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func saveButtonTapped() {
        Log.debug("saveButtonTapped")
        tfGroupName.resignFirstResponder()

        if let groupName = tfGroupName.text, let convKey = conv?.convKey, groupName.length > 0 {
            WebSocketManager.sharedInstance().sendMessage(
                IMConvNameMessage(convKey: convKey, convName: groupName/*tfGroupName.text?.length > 0 ? tfGroupName.text : nil*/),
                checkNetwork: true,
                viewController: self,
                completion: { [weak self] (ack) in
                    if let strongSelf = self {
                        //if let convKey = ack.data {
                        //}
                        strongSelf.dismiss(animated: true, completion: {
                            strongSelf.groupNameDidSave?(strongSelf.tfGroupName.text)
                        })
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                }
            )
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, (text.length >= 50 && !string.isEmpty) || (text.isEmpty && string == " ") {
            return false
        }
        return true
    }

}
