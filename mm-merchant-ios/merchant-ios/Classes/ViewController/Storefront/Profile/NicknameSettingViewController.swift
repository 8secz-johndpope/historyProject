//
//  NicknameSettingViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

class NicknameSettingViewController: AccountSettingBaseViewController, UITextFieldDelegate {
    
    private final let SectionEdgeInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 5.0, right: 0.0)
    private final let NicknameValueKey = "Nickname"
    
    private var values = [String : String]()
    private var confirmButtonOriginalY: CGFloat = 0
    
    private final let HeaderViewHeight = CGFloat(16)
    private final let titleHeaderPaddingTop = CGFloat(3)
    private var nickNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_NICKNAME")
        
        setupHeaderView()
        
        self.collectionView.frame = CGRect(x: self.collectionView.frame.origin.x, y: self.collectionView.frame.origin.y + HeaderViewHeight, width: self.collectionView.frame.width, height: self.collectionView.frame.height - Constants.BottomButtonContainer.Height)
        
        setupDismissKeyboardGesture()
        
        createBackButton()
        createBottomButton(String.localize("LB_CA_CONFIRM"), customAction: #selector(NicknameSettingViewController.confirm))
        prepareDataList()
        setupSubViews()
        retrieveUser()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup Views
    
    private func prepareDataList() {
        values[NicknameValueKey] = "-"
        
        let nicknameSettingsData = SettingsData(valueKey: NicknameValueKey)
        settingsDataList.append([nicknameSettingsData])
    }
    
    private func setupSubViews() {
        collectionView.register(PersonalInformationSettingTextInputCell.self, forCellWithReuseIdentifier: PersonalInformationSettingTextInputCell.CellIdentifier)
        collectionView.register(PersonalInformationSettingNoteCell.self, forCellWithReuseIdentifier: PersonalInformationSettingNoteCell.CellIdentifier)
        
        if bottomButtonContainer != nil {
            confirmButtonOriginalY = bottomButtonContainer!.frame.origin.y
        }
    }
    
    func setupHeaderView() {
        let headerView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: self.collectionView.frame.origin.y, width: self.view.bounds.width, height: HeaderViewHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            return view
        } ()
        
        self.view.addSubview(headerView)
    }
    
    // MARK: - Action
    
    @objc func editingDidEndOnExit(_ textField: UITextField) {
        dismissKeyboardFromView()
    }
    
    @objc func confirm(_ button: UIButton) {
        if let sectionSettingsDataList = settingsDataList.first {
            for i in 0..<sectionSettingsDataList.count {
                if let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? PersonalInformationSettingTextInputCell {
                    if let valueKey = sectionSettingsDataList[i].valueKey {
                        values[valueKey] = cell.textField.text
                    }
                }
            }
        }
        
        let nickname = values[NicknameValueKey]
        
        if (nickname == nil || nickname!.isEmptyOrNil()) {
            
            showError(String.localize("MSG_ERR_CA_NICKNAME_NIL"), animated: true)
            nickNameTextField.shouldHighlight(true)
            nickNameTextField.becomeFirstResponder()
        } else {
            
            nickNameTextField.shouldHighlight(false)
            
            firstly {
                return updateNickname()
                }.then { [weak self] _ -> Void in
                    if let strongSelf = self  {
                        strongSelf.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_PERSONAL_INFO_SUC"))
                        
                        if nickname != nil {
                            strongSelf.user.displayName = nickname!
                            Context.saveUserProfile(strongSelf.user)
                        }
                        NotificationCenter.default.post(name: Constants.Notification.profileImageUploadSucceed, object: nil)
                        
                        strongSelf.navigationController?.popViewController(animated:true)
                        
                    }
            }
        }
    }
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        let keyboardInfoKey = notification.userInfo![UIKeyboardFrameEndUserInfoKey]
        
        if keyboardInfoKey != nil {
            let keyboardHeight = (keyboardInfoKey as! NSValue).cgRectValue.size.height
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardHeight, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if bottomButtonContainer != nil {
                bottomButtonContainer!.frame.originY = confirmButtonOriginalY - keyboardHeight + tabBarHeight
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        if bottomButtonContainer != nil {
            bottomButtonContainer!.frame.originY = confirmButtonOriginalY
        }
    }
    
    // MARK: - Data handling
    
    func retrieveUser() {
        firstly {
            return fetchUser()
            }.then { _ -> Void in
                self.reloadAllData()
        }
    }
    
    func updateNickname() -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateDisplayName(displayName: values[NicknameValueKey]!) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.showNetWorkErrorAlert(response.result.error)
                    }
                }
            }
        }
    }
    
    func reloadAllData() {
        values[NicknameValueKey] = user.displayName
        
        collectionView.reloadData()
    }
    
    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingTextInputCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingTextInputCell
            
            // Reset content
            cell.textField.text = ""
            cell.textField.format()
            if let valueKey = settingsData.valueKey {
                if let value = values[valueKey] {
                    cell.textField.text = value
                }
            }
            
            
            cell.textField.placeholder = settingsData.title
            cell.textField.tag = indexPath.item
            cell.textField.addTarget(self, action: #selector(NicknameSettingViewController.editingDidEndOnExit), for: .editingDidEndOnExit)
            cell.textField.returnKeyType = .done
            cell.textField.addTarget(self, action: #selector(NicknameSettingViewController.textFieldDidChange), for: .editingChanged)
            
            nickNameTextField = cell.textField
            cell.textField.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingNoteCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingNoteCell
            
            cell.noteLabel.text = settingsData.title
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return SectionEdgeInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: view.width, height: PersonalInformationSettingTextInputCell.DefaultHeight)
        } else {
            return CGSize(width: view.width, height: PersonalInformationSettingNoteCell.DefaultHeight)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        textField.setStyleDefault()
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = Constants.Value.NickNameMaxLength
        let currentString: NSString = textField.text as NSString? ?? ""
        let newString: String = currentString.replacingCharacters(in: range, with: string) as String
        let resultBytes = lengthOfStringBytes(str: newString)
        return  resultBytes <= maxLength
    }
    
    // 判断字符字节长度
    private func lengthOfStringBytes(str : String) -> Int {
        var strArray = [Any]()
        for c in str {
            if (("a" <= c && c <= "z") ||
                ("A" <= c && c <= "Z") ||
                c == "_" ||
                c == "*" ||
                c == "-" ||
                c == "/" ||
                c == " " ) {
                strArray.append(c)
            }
        }
        let stringNumer = strArray.count
        let chineseNumer = (str.count - strArray.count) * 2
        return (stringNumer + chineseNumer)
    }
}

