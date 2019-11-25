//
//  AmbassadorPostingViewController.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

protocol AmbassadorPostingViewControllerDelelgate: NSObjectProtocol {
	func sendPost(_ merchants: [Merchant], includeSelf: Bool)
    func cancelSendPost()
}
class AmbassadorPostingViewController: MmViewController {

    private final let idCell = "OutfitBrandViewCell"
    private final let idDefault = "CellId"
    private final let ContentViewHeight = CGFloat(321)
    var contentView = UIView()
    private final let ConfirmViewHeight = CGFloat(75)
    private final let heightHeader = CGFloat(75)
    private final let widthButtonConfirm = CGFloat(118)
    private final let heightButtonConfirm = CGFloat(41)
    private final let CellHeight : CGFloat = 57
    let lineWidth:CGFloat = 150
    
    var headerView = UIView()
    var lineView = UIView()
    var labelTitleHeader = UILabel()
    var bottomView = UIView()
    var buttonConfirm = UIButton()
    var selectedObject = [Int]()
    
    var merchants = [Merchant]()
    weak var ambassdorPostingDelegate : AmbassadorPostingViewControllerDelelgate? //Prevent memory leak and move force unwrap
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        
        self.selectedObject.append(Context.getUserId())
//        for element in merchants {
//            selectedObject.append(element.merchantId)
//        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -self.contentView.bounds.height)
        }) 
    }
    

    func setupLayout() {
        
        self.view.backgroundColor = UIColor.clear
        
        // content view
        let contentViewFrame =  CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: ContentViewHeight)
        self.contentView =  UIView(frame:contentViewFrame)
        self.contentView.backgroundColor = UIColor.clear
        view.addSubview(self.contentView)
        
        // transparent view
        let transparentView = UIView()
        transparentView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        transparentView.frame = self.view.bounds
        transparentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss as () -> Void)))
        self.view.insertSubview(transparentView, belowSubview: contentView)
        
        
        //add header 
        let headerFrame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: heightHeader)
        self.headerView.frame = headerFrame
        self.headerView.backgroundColor = UIColor.white
        self.contentView.addSubview(self.headerView)
        
        let linefrm = CGRect(x: (self.view.bounds.width - lineWidth) / 2, y: (heightHeader - 1)/2, width: lineWidth, height: 1.0)
        lineView.frame = linefrm
        lineView.backgroundColor = UIColor.primary1()
        self.headerView.addSubview(lineView)
        
        self.labelTitleHeader.formatSize(15)
        self.labelTitleHeader.text = String.localize("LB_CA_POST_DESTINATION")
        self.labelTitleHeader.textAlignment = .center
        let widthLabel = StringHelper.getTextWidth(self.labelTitleHeader.text!, height: 21, font: self.labelTitleHeader.font) + 14
        self.labelTitleHeader.frame = CGRect(x: (self.view.bounds.width - widthLabel) / 2, y: (heightHeader - 21) / 2, width: widthLabel, height: 21)
        self.labelTitleHeader.backgroundColor = UIColor.white
        self.headerView.addSubview(labelTitleHeader)
        addBottomBorderWithColor(UIColor.secondary1(), andWidth: 1.0)
        
        // collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(OutfitBrandViewCell.self, forCellWithReuseIdentifier: idCell)
        self.contentView.addSubview(collectionView)
        
        bottomView.backgroundColor = UIColor.white
        addTopBorderWithColor(UIColor.secondary1(), andWidth: 1.0)
        self.contentView.addSubview(bottomView)
        self.buttonConfirm.layer.cornerRadius = 5.0
        self.buttonConfirm.backgroundColor = UIColor.primary1()
        self.buttonConfirm.setTitleColor(UIColor.white, for: UIControlState())
        self.buttonConfirm.setTitle(String.localize("LB_CA_POST_PUBLISH"), for: UIControlState())
        self.buttonConfirm.addTarget(self, action: #selector(AmbassadorPostingViewController.sendPost), for: .touchUpInside)
        self.bottomView.addSubview(buttonConfirm)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        let contentViewFrame =  CGRect(x:0, y: self.view.bounds.height - ContentViewHeight, width: self.view.bounds.width, height: ContentViewHeight)
//        self.contentView.frame = contentViewFrame
        
        collectionView.frame = CGRect(x: 0, y: heightHeader, width: self.contentView.bounds.width, height: self.contentView.bounds.height - ConfirmViewHeight - heightHeader)
        
        self.bottomView.frame = CGRect(x: 0, y: collectionView.frame.maxY, width: self.view.bounds.width, height: ConfirmViewHeight)
        self.buttonConfirm.frame = CGRect(x: self.view.bounds.width - Margin.left - widthButtonConfirm, y: (ConfirmViewHeight - heightButtonConfirm) / 2, width: widthButtonConfirm, height: heightButtonConfirm)
    }
    
    func dismissWithCompleteAction(_ completion:(()->())? = nil) -> Void {
        self.ambassdorPostingDelegate?.cancelSendPost()
        UIView.animate(
            withDuration: 0.3,
            animations: { () -> Void in
                self.contentView.transform = CGAffineTransform.identity
            },
            completion: { (success) -> Void in
                self.dismiss(animated: false, completion: {
                    if let strongCompletion = completion{
                        strongCompletion()
                    }
                })
            }
        )
    }
    
    @objc func dismiss() -> Void {
        self.dismissWithCompleteAction(nil)
    }
    
    func addBottomBorderWithColor(_ color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        border.frame = CGRect(x: 0, y: self.headerView.frame.height - borderWidth, width: self.view.frame.size.width, height: borderWidth)
        self.headerView.addSubview(border)
    }
    
    func addTopBorderWithColor(_ color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        border.frame = CGRect(x: 0, y: 0, width: bottomView.frame.size.width, height: borderWidth)
        self.bottomView.addSubview(border)
    }
    
    //MARK: delegate & datasource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (collectionView) {
        case self.collectionView:
            return self.merchants.count + 1
        default:
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: idCell, for: indexPath) as! OutfitBrandViewCell
            
            
            
            if indexPath.row == 0 {
                cell.imageView.layer.cornerRadius = cell.imageView.frame.width / 2
                cell.imageView.layer.masksToBounds = true
                let user = Context.getUserProfile()
                cell.setupDataCellByUser(user, mode: .friendTagList, placeHolder: Constants.ImageName.ProfileImagePlaceholder)
                cell.tag = Context.getUserId()
                
            } else {
                cell.imageView.layer.cornerRadius = 0
                cell.imageView.layer.masksToBounds = true
                let merchant = self.merchants[indexPath.row - 1]
                cell.modeList = .friendTagList
                cell.setupDataCell(merchant)
                cell.tag = merchant.merchantId
                
            }
            
            if self.selectedObject.contains(cell.tag){
                cell.imageViewIcon.image = UIImage(named: "icon_checkbox_checked")
            } else {
                cell.imageViewIcon.image = UIImage(named: "icon_checkbox_unchecked2")
            }
            return cell
            
        default:
            return getDefaultCell(collectionView, cellForItemAt: indexPath)
            
        }
    }
    
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: idDefault, for: indexPath)
        return cell
    }
    
    func loadingCellForIndexPath(_ indexPath: IndexPath) -> UICollectionViewCell {
        let cell = getDefaultCell(self.collectionView, cellForItemAt: indexPath)
        let activity = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        activity.center = cell.center
        cell .addSubview(activity)
        activity.startAnimating()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectedItemAtIndex(indexPath)
    }
    
    func didSelectedItemAtIndex(_ indexPath: IndexPath) -> Void {
        handleSelected(indexPath)
        self.collectionView.reloadData()
    }

    func handleSelected(_ indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? OutfitBrandViewCell {
            selectedObject.removeAll()
            if !selectedObject.contains(cell.tag){
                selectedObject.append(cell.tag)
                
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch (collectionView) {
        case self.collectionView:
            return CGSize(width: self.view.frame.size.width , height: CellHeight)
        default:
            return CGSize(width: self.view.frame.size.width / 4, height: Constants.Value.CatCellHeight)
        }
        
    }
    
    @objc func sendPost(_ sender: UIButton) {
        if self.selectedObject.count > 0 {
            
            var incluededSelf = false
            
            for i in 0 ..< self.selectedObject.count {
                if self.selectedObject[i] == Context.getUserId() {
                    incluededSelf = true
                    break
                }
            }
            
            var selectedMerchants = [Merchant]()
            for (merchantId) in selectedObject{
                let merchant = self.merchants.filter({$0.merchantId == merchantId}).first
                if let merchantSelected = merchant{
                    selectedMerchants.append(merchantSelected)
                }
            }
            
            self.dismissWithCompleteAction({ [weak self] in
                self?.ambassdorPostingDelegate?.sendPost(selectedMerchants, includeSelf: incluededSelf)
            })
        }
        
    }
}
