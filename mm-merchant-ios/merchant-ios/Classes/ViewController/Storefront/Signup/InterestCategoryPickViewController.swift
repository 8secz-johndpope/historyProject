//
//  InterestCategoryPickViewController.swift
//  merchant-ios
//
//  Created by Tony Fung on 19/7/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

class InterestCategoryPickViewController: MmViewController {
    
    private final let KeywordCellId = "TagCell"
    private final let ContinueButtonMarginBottom : CGFloat = 20
    private final let LabelHeight : CGFloat = 40
    let overlayView = UIView()
    var isMobileSignup = true
    let buttonCheckbox = UIButton()
    let buttonLink = UIButton()
    let rightButton = UIButton(type: UIButtonType.system)
    private let continueButton = ProgressButton()
    private var labelTop = UILabel()
    private var categories:[String] = []
    var tagSelectedCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.setupSubviews()
        
    }
    
    func setupBackground() {
        let imageView = UIImageView(image: UIImage(named: "interest_keyword_background"))
        imageView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        overlayView.frame = imageView.bounds
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = 0
        imageView.addSubview(overlayView)
        self.view.addSubview(imageView)
        self.view.bringSubview(toFront: self.collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        if self.isMobileSignup {
            buttonCheckbox.isHidden = true
            buttonLink.isHidden = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool){
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0.8
        }, completion: { (completed) in
            self.categories = ["男", "女", "男＋女"]
            self.collectionView.reloadData()
        }) 
    }
    
    // MARK: Bottom bar
    private final let MarginLeft : CGFloat = 10
    private final let LineSpacing : CGFloat = 5
    private final let CellHeight : CGFloat = 50
    private final let TextMargin : CGFloat = 30
    private final let ConditionButtonHeight : CGFloat = 50
    private final let MandatoryViewHeight : CGFloat = 50
    private var textFont: UIFont!
    
    func setupSubviews(){
        let label = UILabel()
        label.formatSize(13)
        textFont = label.font
        self.setupBackground()
        labelTop.formatSmall()
        labelTop.textColor = UIColor.white
        labelTop.textAlignment = .center
        labelTop.frame = CGRect(x: 0, y: 80, width: self.view.width, height: LabelHeight)
        labelTop.text = String.localize("你想看的类别")
        self.view.addSubview(labelTop)
        var marginBottom = ConditionButtonHeight + ContinueButtonMarginBottom
        let marginTop : CGFloat = labelTop.frame.maxY + 20
        if self.isMobileSignup {
            buttonCheckbox.isHidden = true
            buttonLink.isHidden = true
        } else {
            marginBottom += MandatoryViewHeight
        }
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.isScrollEnabled = false
        self.collectionView.contentInset = UIEdgeInsets.zero
        self.collectionView.frame = CGRect(x: 0 , y: marginTop, width: self.view.bounds.width, height: self.view.bounds.height - (marginBottom + marginTop))
        self.collectionView?.register(KeywordCell.self, forCellWithReuseIdentifier: KeywordCellId)
        self.createBottomView()
        self.createSkipButton()
        self.updateConditionButton()
    }
    
    func createBottomView() {
        let agreeString = "  " + String.localize("LB_CA_TNC_CHECK")
        let linkString = String.localize("LB_CA_TNC_LINK")
        let linkWidth = StringHelper.getTextWidth(linkString, height: MandatoryViewHeight, font: textFont)
        let agreeTextMarginLink = CGFloat(28)
        buttonCheckbox.config(normalImage: UIImage(named: "icon_checkbox_unchecked"), selectedImage: UIImage(named: "icon_checkbox_checked"))
        buttonCheckbox.setTitle(agreeString, for: UIControlState())
        buttonCheckbox.setTitleColor(UIColor.white, for: UIControlState())
        buttonCheckbox.titleLabel?.font = textFont
        buttonCheckbox.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        buttonCheckbox.addTarget(self, action: #selector(self.checkboxClicked), for: UIControlEvents.touchUpInside)
        buttonCheckbox.sizeToFit()
        buttonCheckbox.frame = CGRect(x: 0, y: 0, width: buttonCheckbox.frame.width, height: MandatoryViewHeight)
        let mandatoryViewWidth = buttonCheckbox.frame.width + agreeTextMarginLink + linkWidth
        let mandatoryView = UIView(frame: CGRect(x: (self.view.bounds.maxX - mandatoryViewWidth) / 2, y: self.view.bounds.maxY - (MandatoryViewHeight + ConditionButtonHeight + ContinueButtonMarginBottom), width: mandatoryViewWidth, height: MandatoryViewHeight))
        mandatoryView.backgroundColor = UIColor.clear
        mandatoryView.addSubview(buttonCheckbox)
        //Create link button
        buttonLink.frame = CGRect(x: buttonCheckbox.frame.maxX + agreeTextMarginLink, y: 0, width: linkWidth, height: MandatoryViewHeight)
        buttonLink.titleLabel?.font = textFont
        buttonLink.titleLabel?.escapeFontSubstitution = true
        let attributes: [NSAttributedStringKey : Any] = [
            NSAttributedStringKey.font : textFont,
            NSAttributedStringKey.foregroundColor : UIColor.primary1(),
            NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue
        ]
        let linkStringAttribute = NSAttributedString(
            string: linkString,
            attributes: attributes
        )
        buttonLink.setAttributedTitle(linkStringAttribute, for: UIControlState())
        buttonLink.setTitleColor(UIColor.primary1(), for: UIControlState())
        buttonLink.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        buttonLink.addTarget(self, action: #selector(self.linkClicked), for: UIControlEvents.touchUpInside)
        buttonLink.backgroundColor = UIColor.clear
        mandatoryView.addSubview(buttonLink)
        self.view.addSubview(mandatoryView)
        continueButton.frame = CGRect(x: 10, y: self.view.bounds.maxY - (ConditionButtonHeight + ContinueButtonMarginBottom), width: self.view.bounds.width - 20, height: ConditionButtonHeight)
        continueButton.layer.cornerRadius = 2
        continueButton.clipsToBounds = true
        continueButton.setTitle(String.localize("LB_CA_FOLLOW_CURATORS_CONT"), for: UIControlState())
        continueButton.addTarget(self, action: #selector(self.proceedToNextPage), for: UIControlEvents.touchUpInside)
        self.view.addSubview(continueButton)
    }
    
    // MARK: Colleciton view delegate
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KeywordCellId, for: indexPath) as! KeywordCell
        cell.nameLabel.text = categories[indexPath.row]
        cell.alpha = 0
        cell.transform = CGAffineTransform.identity.translatedBy(x: 0, y: 20)
        UIView.animate(withDuration: 0.5, delay: Double(indexPath.item) * 0.05 , options: UIViewAnimationOptions(), animations: {
            cell.alpha = 1.0
            cell.transform = CGAffineTransform.identity
            }, completion: { (complete) in
                
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tagSelectedCount = 1
        if self.buttonCheckbox.isSelected {
            let cells = collectionView.visibleCells
            for cell in cells {
                if let indexPath = collectionView.indexPath(for: cell) {
                    cell.transform = CGAffineTransform.identity
                    cell.alpha = 1.0
                    UIView.animate(withDuration: 0.5, delay: Double(indexPath.item) * 0.1 , options: UIViewAnimationOptions(), animations: {
                        cell.alpha = 0
                        cell.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -20)
                        }, completion: { (complete) in
                            
                            if cells.last == cell {
                                //we finished all teh animation
                                self.proceedToNextPage()
                            }
                    })
                    
                }
            }
        } else {
            self.showWarningPopup()
        }
    }
    
    func showWarningPopup(){
        //TODO pending for product team
    }
    
    @objc func proceedToNextPage(){
        if !self.isMobileSignup && !self.buttonCheckbox.isSelected {
            self.self.showWarningPopup()
            return
        }
        let transition = CATransition()
        transition.duration = 0.4
        transition.type = kCATransitionFade
        let viewController = InterestKeywordViewController()
        self.navigationController?.view.layer.add(transition, forKey:kCATransition)
        self.navigationController?.push(viewController, animated: false)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.view.bounds.width / 2 ,height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LineSpacing
    }
    
    //Override right bar button
    func createSkipButton() {
        let rightArrow = UIImageView(image: UIImage(named: "bar_icon_arrow_white"))
        let title = String.localize("LB_CA_FOLLOWING_SKIP")
        rightButton.setTitle(title, for: UIControlState())
        rightButton.titleLabel?.formatSmall()
        rightButton.setTitleColor( UIColor.white, for: UIControlState())
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Constants.Value.BackButtonHeight)
        let boundingBox = title.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: rightButton.titleLabel!.font], context: nil)
        let rightArrowWith = rightArrow.image?.size.width ?? 0
        let buttonWidth = boundingBox.width + rightArrowWith * 2
        rightButton.frame = CGRect(x: self.view.frame.width - (buttonWidth + 15), y: 30, width: buttonWidth, height: Constants.Value.BackButtonHeight)
        var frame = rightArrow.frame
        frame.origin.x = rightButton.bounds.maxX - rightArrowWith
        frame.origin.y = (rightButton.frame.height - (rightArrow.image?.size.height ?? 0)) / 2
        rightArrow.frame = frame
        rightButton.addSubview(rightArrow)
        rightButton.addTarget(self, action: #selector(self.proceedToNextPage), for: UIControlEvents.touchUpInside)
        self.view.addSubview(rightButton)
        rightButton.isEnabled = self.isMobileSignup
    }
    
    @objc func checkboxClicked(_ sender : UIButton){
        sender.isSelected = !sender.isSelected
        rightButton.isEnabled = sender.isSelected
        self.updateConditionButton()
    }
    
    @objc func linkClicked(_ sender : UIButton){
		if let url = ContentURLFactory.urlForContentType(.mmTnc) {			
			self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_TNC"), urlGetContentPage: url), animated: true)
		}
    }
	
    func updateConditionButton()
    {
        if tagSelectedCount > 0 && (isMobileSignup || buttonCheckbox.isSelected) {
            continueButton.updateProgress(1)
            continueButton.isEnabled = true
        }
        else {
            continueButton.updateProgress(0)
            continueButton.isEnabled = false
        }
    }

}
