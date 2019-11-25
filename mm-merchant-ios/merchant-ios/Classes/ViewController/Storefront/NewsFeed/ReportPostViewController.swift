//
//  ReportPostViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 5/17/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
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


class ReportPostViewController: MmViewController, UITextViewDelegate {
    private var reportPostView : ReportPostView!
    private let ReasonMenuHeight : CGFloat = 50
    private var reasonCollectionView : UICollectionView?
    private let reasons : [String] = [
        String.localize("LB_CA_REPORT_POST_REASON_ADS_SPAM"),
        String.localize("LB_CA_REPORT_POST_REASON_INAPPROPRIATE_CONTENT"),
        String.localize("LB_CA_REPORT_POST_REASON_COPYRIGHT"),
        String.localize("LB_CA_REPORT_POST_REASON_OTHERS")]
    
    private var containerView : ContainerView?
    private var reasonSelected : Int = -1
    private final let BackgroundColor : UIColor = UIColor(hexString: "#FAFAFA")
    private var isDoingAnimation = false
    var postId : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_REPORT_POST")
        
        self.createRightButton()
        self.setupSubView()
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton =  true
        self.navigationItem.leftBarButtonItem = nil
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Keyboard Management
    @objc func keyboardWillHide(_ sender: Notification) {
        self.reportPostView?.handleKeyboard(false, notification: sender)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        self.reportPostView?.handleKeyboard(true, notification: sender)
    }

    func createRightButton() {
        let rightButton = UIButton(type: .custom)
        rightButton.setImage(UIImage(named: "icon_cross"), for: UIControlState())
        rightButton.addTarget(self, action: #selector(self.didClickCloseButton), for: .touchUpInside)
        rightButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSubView() {
        reportPostView = ReportPostView(frame: self.view.bounds)
        self.view.addSubview(reportPostView)
        reportPostView.buttonSelectReason.addTarget(self, action: #selector(self.didClickSelectReasonButton), for: UIControlEvents.touchUpInside)
        reportPostView.buttonSubmit.addTarget(self, action: #selector(self.didClickSubmitButton), for: UIControlEvents.touchUpInside)
        reportPostView.textViewDescription.delegate = self
        self.containerView = ContainerView(frame: CGRect(x: 0, y: 108, width: self.view.frame.width, height: self.view.frame.height))
        self.containerView?.clipsToBounds = true
        self.containerView?.isHidden = true
        if let containerView = self.containerView {
            self.view.addSubview(containerView)
        }
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        self.reasonCollectionView = UICollectionView(frame: CGRect(x: 0, y: -CGFloat(self.reasons.count) * ReasonMenuHeight, width: self.view.frame.width, height: CGFloat(self.reasons.count) * ReasonMenuHeight), collectionViewLayout: layout)
        if let reasonCollectionView = self.reasonCollectionView {
            reasonCollectionView.tag = 1
            reasonCollectionView.dataSource = self
            reasonCollectionView.delegate = self
            reasonCollectionView.backgroundColor = UIColor.brown
            containerView?.addSubview(reasonCollectionView)
            reasonCollectionView.register( PickerCell.self, forCellWithReuseIdentifier: "PickerCell")
            reasonCollectionView.backgroundColor = UIColor.white
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dissmissKeyboard))
        self.reportPostView?.addGestureRecognizer(tapGesture)
        
    }
    
    //MARK: Action handler
    @objc func didClickCloseButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func didClickSelectReasonButton(){
        if !isDoingAnimation {
            if !self.reportPostView.buttonArrow.isSelected {
                self.showMenu()
            } else {
                self.hideMenu()
            }
        }
    }
    
    @objc func didClickSubmitButton() {
        self.dissmissKeyboard()
        self.hideMenu()
        if self.reportPostView.textfieldSelectReason.text?.length < 1 {
            self.showError(String.localize("MSG_ERR_CA_REVIEW_REPORT"), animated: true)
            return
        }
        else if self.reportPostView.textfieldSelectReason.text == String.localize("LB_CA_REPORT_POST_REASON_OTHERS") && self.reportPostView.textViewDescription.text.trim().length == 0{
            self.showError(String.localize("MSG_ERR_CA_REPORT_POST_CONTENT"), animated: true)
            return
        }
        //TODO implement report here
        self.submitReportPost()
    }
    
    //MARK: UICollectionDelegate & UICollectionDataSource
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCell", for: indexPath) as! PickerCell
        cell.label.text = self.reasons[indexPath.row]
        if indexPath.row == self.reasonSelected {
            cell.imageView.image = UIImage(named:"tick")
        } else {
            cell.imageView.image = nil
        }
        cell.backgroundColor = BackgroundColor
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return self.reasons.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: ReasonMenuHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        self.reasonSelected = indexPath.row
        self.reasonCollectionView?.reloadData()
        self.reportPostView.textfieldSelectReason.text = reasons[indexPath.row]
        self.hideMenu()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
        
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
        
    }

    
    //MARK: Helper function to hide and unhide the container view and manipulate the arrow sign
    func hideMenu() {
        if(isDoingAnimation || !self.reportPostView.buttonArrow.isSelected) {
            return
        }
        isDoingAnimation = true
        self.containerView?.hide()
        if let collectionView = self.reasonCollectionView {
            UIView.animate(withDuration: 0.5, animations: {
                collectionView.frame = CGRect(x: 0, y: -CGFloat(self.reasons.count) * self.ReasonMenuHeight, width: self.view.frame.width, height: CGFloat(self.reasons.count) * self.ReasonMenuHeight)
                }, completion: {
                    (finished: Bool) -> Void in
                    self.isDoingAnimation = false
                    self.reportPostView.buttonArrow.isSelected = false
                })
        }
    }

    func showMenu() {
        if(isDoingAnimation || self.reportPostView.buttonArrow.isSelected) {
            return
        }
        self.reportPostView.buttonArrow.isSelected = true
        self.dissmissKeyboard()
        isDoingAnimation = true
        self.reasonCollectionView?.reloadData()
        self.containerView?.show()
        if let collectionView = self.reasonCollectionView {
            UIView.animate(withDuration: 0.5, animations: {
                collectionView.frame = CGRect(x: 0, y: 1, width: self.view.frame.width, height: CGFloat(self.reasons.count) * self.ReasonMenuHeight)}, completion: {(finished: Bool) -> Void in
                    self.isDoingAnimation = false
            })
        }
    }
    
    @objc func dissmissKeyboard() {
        self.view.endEditing(true)
    }

    private func submitReportPost() {
        self.showLoading()
        firstly {
            return self.createReportPost()
            }.then { _ -> Void in
                self.showSuccessPopupWithText(String.localize("MSG_ERR_CA_REPORT_POST_SUBMIT"))
                self.navigationController?.popViewController(animated:true)
            }.always {
                self.stopLoading()
        }
    }
    
    private func createReportPost() -> Promise<Any> {
        return Promise { fulfill, reject in
            NewsFeedService.createReportPost(reportReasonId: reasonSelected + 1, reportDescription: reportPostView.textViewDescription.text, postId: postId, completion: { [weak self](response) -> Void in
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
    
    //MARK: UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.text.count + (text.count - range.length) < 201
    }
}
