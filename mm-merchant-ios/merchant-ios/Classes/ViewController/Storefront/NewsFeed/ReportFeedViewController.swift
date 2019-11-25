//
//  ReportFeedViewController.swift
//  merchant-ios
//
//  Created by TrungVu on 9/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit


class ReportFeedViewController: MmViewController, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    enum ReportPostReason: Int {
        case unknown
        case spam
        case inappropriateContent
        case copyright
        case others
    }
     private final let DefaultCellID = "DefaultCellID"
    
    private var afterSalesReasonCell: AfterSalesReasonCell?
    private var afterSalesDescriptionCell: AfterSalesDescriptionCell?
    private var reasons = [BaseReason]()
    private var selectedReason: BaseReason?
    
    private final let SummaryViewHeight: CGFloat = 66
    private final let ReasonPickerHeight: CGFloat = 206
    private var descriptionCharacterLimit = Constants.CharacterLimit.AfterSalesDescription

    
    private var afterSalesDataList = [AfterSalesData]()
    
    private var reasonPicker: UIPickerView!
    
    private var afterSalesDescriptionTextView: UITextView?
    private var activeTextView: UITextView?
    
    private final let EmptyReasonTexts = [
        String.localize("MSG_ERR_CA_REPORT_POST_REASON_NIL")
    ]
    
    private final let DescriptionPlaceholders = [
        String.localize("LB_CA_REPORT_POST_DESC")
    ]
    
    private var afterSalesDescription = ""
    
    var postId: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = self.navigationController {
            navigationController.isNavigationBarHidden = false
           
        }
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItems = nil
        
        self.view.backgroundColor = UIColor.backgroundGray()
        self.title = String.localize("LB_CA_REPORT_POST")
        
        prepareDataReason()
        setupDismissKeyboardGesture()
        createRightBarItem()
        createSubViews()
        
        
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    private func prepareDataReason() {
        let spam = BaseReason()
        spam.reportReasonName = String.localize("LB_CA_REPORT_POST_REASON_ADS_SPAM")
        spam.reasonId = ReportPostReason.spam.rawValue
        
        let inapproriate = BaseReason()
        inapproriate.reportReasonName = String.localize("LB_CA_REPORT_POST_REASON_INAPPROPRIATE_CONTENT")
        inapproriate.reasonId = ReportPostReason.inappropriateContent.rawValue
        
        let coppyright = BaseReason()
        coppyright.reportReasonName = String.localize("LB_CA_REPORT_POST_REASON_COPYRIGHT")
        coppyright.reasonId = ReportPostReason.copyright.rawValue
        
        let other = BaseReason()
        other.reportReasonName = String.localize("LB_CA_REPORT_POST_REASON_OTHERS")
        other.reasonId = ReportPostReason.others.rawValue
        
        reasons = [ spam, inapproriate, coppyright, other]
    }
    
    
    private func createSubViews() {
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        collectionView.register(AfterSalesReasonCell.self, forCellWithReuseIdentifier: AfterSalesReasonCell.CellIdentifier)
        collectionView.register(AfterSalesDescriptionCell.self, forCellWithReuseIdentifier: AfterSalesDescriptionCell.CellIdentifier)
        
        afterSalesDataList.append(AfterSalesData(title: String.localize("LB_CA_REFUND_REASON"), cellHeight: 40, hasBorder: true, reuseIdentifier: AfterSalesReasonCell.CellIdentifier))
        afterSalesDataList.append(AfterSalesData(title: nil, cellHeight: 130, hasBorder: true, reuseIdentifier: AfterSalesDescriptionCell.CellIdentifier))
        
        collectionView.frame = CGRect(x: collectionView.x, y: collectionView.y, width: collectionView.width, height: collectionView.height)
        
        let summaryView = { () -> UIView in
            let frame = CGRect(x: 0, y: collectionView.frame.maxY - ScreenBottom, width: collectionView.width, height: SummaryViewHeight + ScreenBottom)
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            let confirmButton = { () -> UIButton in

                
                let button = UIButton(type: .custom)
                
                button.frame = CGRect(
                    x: Constants.BottomButtonContainer.MarginHorizontal,
                    y: Constants.BottomButtonContainer.MarginVertical,
                    width: self.view.frame.size.width - (Constants.BottomButtonContainer.MarginHorizontal * 2),
                    height: Constants.BottomButtonContainer.Height - (Constants.BottomButtonContainer.MarginVertical * 2)
                )
                
                button.formatPrimary()
                button.setTitle(String.localize("LB_CA_SUBMIT"), for: UIControlState())
                
                
                
                let topBorderView = UIView(frame:CGRect(x: 0, y: 0, width: view.frame.width, height: 1))
                topBorderView.backgroundColor = UIColor.secondary1()
                view.addSubview(topBorderView)
                button.addTarget(self, action: #selector(ReportFeedViewController.confirm), for: .touchUpInside)
                
                return button
                
            } ()
            view.addSubview(confirmButton)
            
            return view
        } ()
        view.addSubview(summaryView)
    }
    
    @objc func confirm() {
        
        submitReportReview()
        
    }
    
    private func submitReportReview() {
        var reasonId = -1
        if let selectedReason = selectedReason {
            reasonId = selectedReason.reasonId
        }
        if selectedReason == nil || (afterSalesReasonCell?.textField.text == EmptyReasonTexts[0]) {
            self.showError(String.localize("MSG_ERR_CA_REVIEW_REPORT"), animated: true)
        } else  if reasonId == ReportPostReason.others.rawValue && afterSalesDescription.length == 0 {
            self.showError(String.localize("MSG_ERR_CA_REPORT_POST_CONTENT"), animated: true)
            
        } else {
            self.showLoading()
            firstly {
                return self.createReportPost(reasonId)
                }.then { _ -> Void in
                    self.showSuccessPopupWithText(String.localize("MSG_ERR_CA_REPORT_POST_SUBMIT"))
                    self.navigationController?.popViewController(animated:true)
                }.always {
                    self.stopLoading()
            }
        }
        
    }
    
//    private func submitReportPost() {
//        var reasonId = -1
//        if let selectedReason = selectedReason {
//            reasonId = selectedReason.reasonId
//        }
//        
//        self.showLoading()
//        firstly {
//            return self.createReportPost(reasonId)
//            }.then { _ -> Void in
//                self.showSuccessPopupWithText(String.localize("MSG_ERR_CA_REPORT_POST_SUBMIT"))
//                self.navigationController?.popViewController(animated:true)
//            }.always {
//                self.stopLoading()
//        }
//    }
    
    private func createReportPost(_ id: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            NewsFeedService.createReportPost(reportReasonId: id, reportDescription: afterSalesDescription, postId: postId, completion: { [weak self](response) -> Void in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        }else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    }else {
                        reject(response.result.error!)
                        strongSelf.showNetWorkErrorAlert(response.result.error)
                    }
                }
                })
        }
    }

    override func collectionViewBottomPadding() -> CGFloat {
        return SummaryViewHeight
    }
    
    private func createRightBarItem() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "icon_order_refund_cancel"), for: UIControlState())
        closeButton.frame = CGRect(x: self.view.frame.size.width - Constants.Value.BackButtonWidth, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
        closeButton.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
    }
    
    @objc func dismiss(_ sender:UIButton!){
        self.navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return afterSalesDataList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let afterSalesData = afterSalesDataList[indexPath.row]
        
        if afterSalesData.reuseIdentifier != nil {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: afterSalesData.reuseIdentifier!, for: indexPath)
            
            switch afterSalesData.reuseIdentifier! {
            case AfterSalesReasonCell.CellIdentifier:
                let itemCell = cell as! AfterSalesReasonCell
                itemCell.leftLabel.text = String.localize("LB_CA_REPORT_POST_REASON")
                
                if let selectedReason = self.selectedReason {
                    itemCell.textField.text = selectedReason.reportReasonName
                    itemCell.textField.textColor = UIColor.blackTitleColor()
                } else {
                    var emptyReasonText: String = ""
                    emptyReasonText = EmptyReasonTexts[0]
                    itemCell.textField.placeholder = emptyReasonText
                    itemCell.textField.textColor = UIColor.secondary1()
                }
                
                let afterSalesReasonInputView = AfterSalesReasonInputView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: ReasonPickerHeight))
                reasonPicker = afterSalesReasonInputView.pickerView
                reasonPicker.delegate = self
                reasonPicker.dataSource = self
                
                itemCell.textField.inputView = afterSalesReasonInputView
                itemCell.textField.delegate = self
                reasonPicker.reloadAllComponents()
                itemCell.showBorder(true)
                
                afterSalesReasonInputView.didPressDone = {
                    itemCell.textField.resignFirstResponder()
                }
                
                afterSalesReasonCell = itemCell
                
                return itemCell
            case AfterSalesDescriptionCell.CellIdentifier: 
                let itemCell = cell as! AfterSalesDescriptionCell
                
                itemCell.placeHolder = DescriptionPlaceholders[0]
                itemCell.characterLimit = descriptionCharacterLimit
                itemCell.updateDescriptionCharactersCount(0)
                
                if afterSalesDescription.isEmpty {
                    var descriptionPlaceholder: String = ""
                    descriptionPlaceholder = DescriptionPlaceholders[0]
                    itemCell.descriptionTextView.text = descriptionPlaceholder
                    itemCell.descriptionTextView.textColor = UIColor.secondary1()
                } else {
                    itemCell.descriptionTextView.text = afterSalesDescription // TODO: Duplicated?
                    itemCell.setDescriptionText(afterSalesDescription)
                    itemCell.descriptionTextView.textColor = UIColor.blackTitleColor()
                }
                
                itemCell.descriptionTextView.delegate = self
                
                afterSalesDescriptionTextView = itemCell.descriptionTextView
                afterSalesDescriptionCell = itemCell
                
                return itemCell
            default:
                break
            }
        }
        
        return self.defaultCell(collectionView, cellForItemAt: indexPath)
    }
    
    private func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: afterSalesDataList[indexPath.row].cellHeight)
    }
    
    // MARK: - Picker View Delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == reasonPicker {
            return reasons.count
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == reasonPicker && component == 0 && row < reasons.count {
            let reason = reasons[row]
            return reason.reportReasonName
        }
        
        return ""
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == reasonPicker && component == 0 && row < reasons.count {
            selectedReason = reasons[row]
            
            if let selectedReason = selectedReason {
                
                afterSalesReasonCell?.textField.text = selectedReason.reportReasonName
                
            }
            
            afterSalesReasonCell?.textField.textColor = UIColor.blackTitleColor()
        }
    }
    
 
    
    // MARK: Text View Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView{
            afterSalesDescription = textView.text
            
            if let afterSalesDescriptionCell = self.afterSalesDescriptionCell {
                afterSalesDescriptionCell.updateDescriptionCharactersCount(afterSalesDescription.length)
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView {
            self.activeTextView = textView
            
            if afterSalesDescription.isEmpty {
                textView.text =  ""
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == self.afterSalesDescriptionTextView {
            self.activeTextView = nil
            if afterSalesDescription.isEmpty {
                textView.text =  String.localize("LB_REFUND_DESC")
                textView.textColor = UIColor.secondary1()
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == self.afterSalesDescriptionTextView {
            let currentText = textView.text as NSString
            let proposedText = currentText.replacingCharacters(in: range, with: text)
            if proposedText.count > descriptionCharacterLimit {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Text Field Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if let amountCell = self.afterSalesAmountCell {
//            if textField == amountCell.valueTextField {
//                var textResult: NSString? = textField.text
//                if textResult != nil && textResult!.length > 0 {
//                    textResult = textResult!.replacingCharacters(in: range, with:string)
//                    
//                    var arraySplit = textResult!.components(separatedBy: ".")
//                    
//                    if arraySplit.count > 2 {
//                        // More than 2 dot signs in number doesn't allow
//                        return false
//                    } else if arraySplit.count == 2 {
//                        // Allow Max number after dot is 2
//                        let numberAfterDot = arraySplit[1]
//                        if numberAfterDot.length > 2 {
//                            return false
//                        }
//                    }
//                }
//            }
//        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let afterSalesReasonCell = afterSalesReasonCell {
            if textField == afterSalesReasonCell.textField {
                if selectedReason == nil && reasons.count > 0 {
                    selectedReason = reasons.first
                    
                    if let selectedReason = selectedReason {
                        
                        afterSalesReasonCell.textField.text = selectedReason.reportReasonName

                        
                    }
                    
                    afterSalesReasonCell.textField.textColor = UIColor.blackTitleColor()
                }
            }
        }
    }
    
    func getHeightErrorView() -> CGFloat {
        
        var height: CGFloat = 40
        if self.navigationController == nil && self.navigationController?.isNavigationBarHidden == true {
            height = 60
        }
        return height
    }
    
    
    func incorrectViewShow(_ isShow: Bool) {
        if isShow {
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.collectionView.transform = CGAffineTransform(translationX: 0, y: self.getHeightErrorView())
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                
                self.collectionView.transform = CGAffineTransform.identity
            })
        }
    }

}
