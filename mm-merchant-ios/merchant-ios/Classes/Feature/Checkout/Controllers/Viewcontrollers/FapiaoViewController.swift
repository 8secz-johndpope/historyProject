//
//  FapiaoViewController.swift
//  merchant-ios
//
//  Created by Jerry Chong on 13/10/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
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


class FapiaoViewController: MmViewController, UITextFieldDelegate {
    var fapiaoText = ""
    var fapiaoHandler: ((String) -> ())?
    private let selectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let inputTextView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary1()
        return view
    }()
    
    private let noFapiaoView: FapiaoSelectionView = {
        let view = FapiaoSelectionView()
        view.backgroundColor = UIColor.clear
        view.fapiaoTypeLabel.text = String.localize("LB_CA_FAPIAO_NO_NEED")
        return view
    }()
    
    private let personalFapiaoView: FapiaoSelectionView = {
        let view = FapiaoSelectionView()
        view.backgroundColor = UIColor.clear
        view.fapiaoTypeLabel.text = String.localize("LB_CA_FAPIAO_INDIVIDUAL")
        return view
    }()
    
    private let companyFapiaoView: FapiaoSelectionView = {
        let view = FapiaoSelectionView()
        view.backgroundColor = UIColor.clear
        view.fapiaoTypeLabel.text = String.localize("LB_CA_FAPIAO_UNIT")
        return view
    }()
    
    private let fapiaoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = String.localize("LB_CA_FAPIAO_TITLE")
        label.formatSizeBold(14)
        label.textColor = UIColor.secondary2()
        label.textAlignment = .left
        return label
    }()
    
    private let txtCompanyName: UITextField = {
        let textView = UITextField()
        textView.text = ""
        textView.formatSize(14)
        textView.textColor = UIColor.secondary2()
        textView.textAlignment = .left
        textView.attributedPlaceholder = NSAttributedString(string: String.localize("LB_CA_FAPIAO_INPUT_UNIT_TITLE"),
                                                               attributes: [NSAttributedStringKey.foregroundColor: UIColor(hexString: "#cccccc")])
        return textView
    }()
    
    private let txtTaxReg: UITextField = {
        let textView = UITextField()
        textView.text = ""
        textView.formatSize(14)
        textView.textColor = UIColor.secondary2()
        textView.textAlignment = .left
        textView.placeholder = String.localize("LB_CA_FAPIAO_INPUT_TAXPAYER_NUMBER")
        textView.attributedPlaceholder = NSAttributedString(string: String.localize("LB_CA_FAPIAO_INPUT_TAXPAYER_NUMBER"),
                                                            attributes: [NSAttributedStringKey.foregroundColor: UIColor(hexString: "#cccccc")])
        return textView
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.primary1()
        button.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIUpdate()
        
        noFapiaoView.pressHandler = {
            self.noFapiaoView.selected = true
            self.personalFapiaoView.selected = false
            self.companyFapiaoView.selected = false
            self.inputTextView.isHidden = true
            self.view.endEditing(true)
            self.fapiaoText = String.localize("LB_CA_FAPIAO_NO_NEED")
        }
        
        personalFapiaoView.pressHandler = {
            self.noFapiaoView.selected = false
            self.personalFapiaoView.selected = true
            self.companyFapiaoView.selected = false
            self.inputTextView.isHidden = true
            self.view.endEditing(true)
            self.fapiaoText = String.localize("LB_CA_FAPIAO_INDIVIDUAL")
        }
        
        companyFapiaoView.pressHandler = {
            self.noFapiaoView.selected = false
            self.personalFapiaoView.selected = false
            self.companyFapiaoView.selected = true
            self.inputTextView.isHidden = false
            self.view.endEditing(true)
            self.fapiaoText = self.txtCompanyName.text! + ";" + self.txtTaxReg.text!
            
        }
        
        switch fapiaoText {
        case String.localize("LB_CA_FAPIAO_NO_NEED"):
            self.noFapiaoView.selected = true
            self.personalFapiaoView.selected = false
            self.companyFapiaoView.selected = false
            self.inputTextView.isHidden = true

        case String.localize("LB_CA_FAPIAO_INDIVIDUAL"):
            self.noFapiaoView.selected = false
            self.personalFapiaoView.selected = true
            self.companyFapiaoView.selected = false
            self.inputTextView.isHidden = true
        default:
            self.noFapiaoView.selected = false
            self.personalFapiaoView.selected = false
            self.companyFapiaoView.selected = true
            self.inputTextView.isHidden = false
            
            let fapiaoCompanyArr = fapiaoText.split(whereSeparator: {$0 == ";"}).map(String.init)
            if (fapiaoCompanyArr.count == 2) {
                self.txtCompanyName.text = fapiaoCompanyArr[0]
                self.txtTaxReg.text = fapiaoCompanyArr[1]
            } else {
                self.txtCompanyName.text = ""
                self.txtTaxReg.text = ""
            }
        }
        confirmButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
        
        txtCompanyName.delegate = self
        txtTaxReg.delegate = self
    }
    

    
    private func UIUpdate(){
        
        self.title = String.localize("LB_CA_FAPIAO_INFO")
        self.navigationController!.isNavigationBarHidden = false
        self.createBackButton()
        
        var navigationBarMaxY = CGFloat(0)
        if let navigationController = self.navigationController, !navigationController.isNavigationBarHidden {
            navigationBarMaxY = navigationController.navigationBar.frame.maxY
        }
        self.collectionView.isHidden = true
        self.view.backgroundColor = UIColor.backgroundGray()
        view.addSubview(selectionView)
        view.addSubview(inputTextView)
        
        selectionView.snp.makeConstraints { (target) in
            target.top.equalTo(navigationBarMaxY + 10)
            target.left.equalTo(0)
            target.right.equalTo(0)
            //target.height.equalTo(150)
        }

        selectionView.addSubview(fapiaoTitleLabel)
        selectionView.addSubview(lineView)
        selectionView.addSubview(noFapiaoView)
        selectionView.addSubview(personalFapiaoView)
        selectionView.addSubview(companyFapiaoView)
        
        fapiaoTitleLabel.snp.makeConstraints {[weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.selectionView.snp.top).offset(12)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(12)
        }
        
        lineView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.fapiaoTitleLabel.snp.bottom).offset(12)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(0.5)
        }
        
        noFapiaoView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.lineView.snp.bottom).offset(18)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(16)
        }
        
        personalFapiaoView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.noFapiaoView.snp.bottom).offset(18)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(16)
        }
        
        companyFapiaoView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.personalFapiaoView.snp.bottom).offset(18)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(16)
            target.bottom.equalTo(-10)
        }
        
        
        inputTextView.snp.makeConstraints { [weak self]  (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.selectionView.snp.bottom).offset(0)
            target.left.equalTo(0)
            target.right.equalTo(0)
        }
        
        inputTextView.addSubview(txtCompanyName)
        inputTextView.addSubview(txtTaxReg)
        
        txtCompanyName.snp.makeConstraints {(target) in
            target.top.equalTo(0)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(36)
        }
        
        txtTaxReg.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.txtCompanyName.snp.bottom).offset(10)
            target.left.equalTo(14)
            target.right.equalTo(-14)
            target.height.equalTo(36)
            target.bottom.equalTo(-18)
        }
        
        view.addSubview(confirmButton)
        confirmButton.frame = CGRect(x: 14, y: ScreenHeight - 46 - ScreenBottom, width: ScreenWidth - 28, height: 36)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
 
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
            let keyboardSize = keyboardFrame.cgRectValue.size
            let originY = ScreenHeight - (46) - keyboardSize.height
            confirmButton.y = originY
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        confirmButton.y = ScreenHeight - 46 - ScreenBottom
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        if textField == txtCompanyName{
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 50
        }
        if textField == txtTaxReg{
            let newLength = text.utf16.count + string.utf16.count - range.length
            return newLength <= 20
        }
        
        
        
        if textField == txtTaxReg{
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            var isCharacterSet = true
            if (string.rangeOfCharacter(from: CharacterSet.letters) != nil) {
                isCharacterSet = false
            }
            
            if ((isCharacterSet) && (allowedCharacters.isSuperset(of: characterSet))) {
                return false
            }
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func textFieldDidChanged(_ textField: UITextField){
    }
    
    func actionCheckingBeforeConfirm() -> Bool{
        if (fapiaoText == String.localize("LB_CA_FAPIAO_NO_NEED") || fapiaoText == String.localize("LB_CA_FAPIAO_INDIVIDUAL")) {
            return true
        }
        if (txtCompanyName.text?.count == 0 && txtTaxReg.text?.count == 0){
            alertError(String.localize("LB_CA_FAPIAO_MISSING_INFO"))
            return false
        }
        
        if (txtCompanyName.text?.count == 0 && txtTaxReg.text?.count > 0){
            alertError(String.localize("LB_CA_FAPIAO_INPUT_UNIT_TITLE"))
            return false
        }
        
        if (txtCompanyName.text?.count > 0 && txtTaxReg.text?.count == 0){
            alertError(String.localize("LB_CA_FAPIAO_INPUT_TAXPAYER_NUMBER"))
            return false
        }
        
        if (txtTaxReg.text?.count != 15 && txtTaxReg.text?.count != 18 && txtTaxReg.text?.count != 20) {
            alertError(String.localize("LB_CA_FAPIAO_WRONG_DIGIT"))
            return false
        }
        return true
    }
    
    func alertError(_ messageString: String){
        let alertController = UIAlertController(title: "", message: messageString, preferredStyle: UIAlertControllerStyle.alert)
        var okString: String!
        okString = String.localize("LB_CA_CONFIRM")
        let okAction = UIAlertAction(title: okString, style: .default) { UIAlertAction in }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func actionTap(_ sender: UIButton){
        if (actionCheckingBeforeConfirm()) {
            if let callback = self.fapiaoHandler {
                if (self.fapiaoText != String.localize("LB_CA_FAPIAO_NO_NEED") && self.fapiaoText != String.localize("LB_CA_FAPIAO_INDIVIDUAL")) {
                    self.fapiaoText = self.txtCompanyName.text! + ";" + self.txtTaxReg.text!
                }
                callback(fapiaoText)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
}




class FapiaoSelectionView: UIView {
    var pressHandler: (() -> Void)?
    var labelText = "" {
        didSet{
            if (labelText.count > 0) {
                fapiaoTypeLabel.text = labelText
            }
        }
    }
    var selected = false {
        didSet{
            if(selected){
                tickImageView.image = UIImage(named: "checkbox_gray_small_selected")
            }else{
                tickImageView.image = UIImage(named: "Oval_Img_Selected")
                
            }
        }
    }
    
    private let selectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    private let tickImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.layer.borderWidth = 0
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.image = UIImage(named: "Oval_Img_Selected")
        return imageView
    }()
    
    let fapiaoTypeLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.formatSize(14)
        label.textColor = UIColor(hexString: "#4A4A4A")
        label.textAlignment = .left
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(tickImageView)
        addSubview(fapiaoTypeLabel)
        addSubview(selectButton)
        
        tickImageView.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.height.equalTo(16)
            target.width.equalTo(16)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.centerY.equalTo(fapiaoTypeLabel)
        }
        
        fapiaoTypeLabel.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(0)
            target.left.equalTo(strongSelf.tickImageView.snp.right).offset(10)
        }
        
        selectButton.snp.makeConstraints { [weak self] (target) in
            guard let strongSelf = self else {
                return
            }
            target.top.equalTo(strongSelf.snp.top).offset(0)
            target.bottom.equalTo(strongSelf.snp.bottom).offset(0)
            target.left.equalTo(strongSelf.snp.left).offset(0)
            target.right.equalTo(strongSelf.snp.right).offset(0)
        }
        
        selectButton.addTarget(self, action: #selector(actionTap), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func actionTap(_ sender: UIButton){
        if let callback = self.pressHandler {
            callback()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
}
