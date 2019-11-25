//
//  ViewController.swift
//  UICollectionViewTest
//
//  Created by HVN_Pivotal on 1/28/16.
//  Copyright © 2016 HVN_Pivotal. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class InterestKeywordViewController: MmViewController {
    private final let KeywordCellId = "TagCell"
    private final let SubCatCellId = "SubCatCell"
    private final let MarginLeft : CGFloat = 10
    private final let LineSpacing : CGFloat = 2
    private final let CellHeight : CGFloat = 35
    private final let TextMargin : CGFloat = 30
    private final let TagMarginLeftRight : CGFloat = 30
    private final let ConditionButtonHeight : CGFloat = 50
    private final let MandatoryViewHeight : CGFloat = 50
    private final let LabelHeight : CGFloat = 24
    private final let ContinueButtonMarginBottom : CGFloat = 20
    private var textFont = UIFont()
    private var labelTop = UILabel()
    private var titleTextAttributes : [NSAttributedStringKey: Any]!
    private var navigationBGImage : UIImage!
    private var navigationShadowImage : UIImage!
    private var navigationTranslucent : Bool = false
    private var navigationBGColor : UIColor!
    private var barTintColor : UIColor!
    private var isFakeNavigationBarHiden : Bool = false
    private let continueButton = ProgressButton()
    private final let DefaultTagNumber : Int = 1
    let buttonCheckbox = UIButton()
    let buttonLink = UIButton()
    var tags : [Tag] = []
    var tagGroups : [TagGroup] = []
    var tagSelectedCount = 0
    var isMobileSignup = true
    private var isScrolling = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createBackButton()
        self.setupSubviews()
        self.showLoading()
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = String.localize("LB_CA_MY_INTEREST_KEYWORDS")
//        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.revertNavigationBar()
    }
    
    override func getCustomFlowLayout() -> UICollectionViewFlowLayout {
        return KeywordCollectionViewFlowLayout()
    }
    func setupSubviews(){
        let label = UILabel()
        label.formatSize(13)
        textFont = label.font
//        self.setupBackground()
        labelTop.formatSize(10)
        labelTop.textColor = UIColor.gray
        labelTop.backgroundColor = UIColor.backgroundGray()
        labelTop.textAlignment = .center
        labelTop.frame = CGRect(x: 0, y: StartYPos, width: self.view.width, height: LabelHeight)
        labelTop.text = String.localize("LB_CA_MY_INTEREST_KEYWORDS_DESC")
        self.view.addSubview(labelTop)
        if self.isMobileSignup {
            self.buttonCheckbox.isHidden = true
            self.buttonLink.isHidden = true
        }
        let marginBottom = ConditionButtonHeight + MandatoryViewHeight 
        let marginTop : CGFloat = labelTop.frame.maxY
        
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.contentInset = UIEdgeInsets.zero
        self.collectionView.frame = CGRect(x: 0 , y: marginTop, width: self.view.bounds.width, height: self.view.bounds.height - (marginBottom + marginTop))
        self.collectionView?.register(KeywordCellExtension.self, forCellWithReuseIdentifier: KeywordCellId)
        self.collectionView?.register(SubCatCell.self, forCellWithReuseIdentifier: SubCatCellId)
        self.createBottomView()
        self.createSkipButton()
       
    }
    
    
    
    func setupBackground() {
        let imageView = UIImageView(image: UIImage(named: "interest_keyword_background"))
        imageView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenHeight)
        let overlayView = UIView(frame: imageView.bounds)
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = 0.8
        imageView.addSubview(overlayView)
        self.view.addSubview(imageView)
        self.view.bringSubview(toFront: self.collectionView)
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
        let attributes = [
            NSAttributedStringKey.font : textFont,
            NSAttributedStringKey.foregroundColor : UIColor.primary1(),
            NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue
            ] as [NSAttributedStringKey : Any]
        let linkStringAttribute = NSAttributedString(
            string: linkString,
            attributes: attributes)
        buttonLink.setAttributedTitle(linkStringAttribute, for: UIControlState())
        buttonLink.setTitleColor(UIColor.primary1(), for: UIControlState())
        buttonLink.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        buttonLink.addTarget(self, action: #selector(InterestKeywordViewController.linkClicked), for: UIControlEvents.touchUpInside)
        buttonLink.backgroundColor = UIColor.clear
        mandatoryView.addSubview(buttonLink)
        self.view.addSubview(mandatoryView)
        
//        let margin = CGFloat(10)
        let heightBottomView = Constants.BottomButtonContainer.Height
        let bottomView = UIView(frame: CGRect(x: 0, y: self.view.bounds.height - heightBottomView, width: self.view.bounds.width, height: heightBottomView))
        self.view.addSubview(bottomView)
        
        let line = UIView(frame: CGRect(x: 0, y: 0, width: bottomView.width, height: 1.0))
        line.backgroundColor = UIColor.primary2()
        bottomView.addSubview(line)
//        continueButton.frame = CGRect(x: margin, y: margin, width: self.view.bounds.width - 20, height: ConditionButtonHeight)
        
        continueButton.frame = CGRect(
            x: Constants.BottomButtonContainer.MarginHorizontal,
            y: Constants.BottomButtonContainer.MarginVertical,
            width: bottomView.frame.size.width - (Constants.BottomButtonContainer.MarginHorizontal * 2),
            height: bottomView.frame.size.height - (Constants.BottomButtonContainer.MarginVertical * 2)
        )
        continueButton.layer.cornerRadius = 2
        continueButton.clipsToBounds = true
        continueButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState())
        continueButton.addTarget(self, action: #selector(InterestKeywordViewController.continueClicked), for: UIControlEvents.touchUpInside)
        
        continueButton.formatPrimary()
        continueButton.setTitleColor(UIColor.white, for: UIControlState())
        continueButton.isEnabled = true
        bottomView.addSubview(continueButton)
    }
    
    func updateConditionButton()
    {
        if tagSelectedCount > 0 {
            let percent : Float = Float(tagSelectedCount) / Float(DefaultTagNumber)
            continueButton.updateProgress(percent)
            //            continueButton.alpha = 1.0
            continueButton.isEnabled = true
        }
        else {
            continueButton.updateProgress(0)
            
            //            continueButton.alpha = 0.7
            continueButton.isEnabled = false
        }
    }
    
    @objc func checkboxClicked(_ sender : UIButton){
        sender.isSelected = !sender.isSelected
//        self.updateConditionButton()
    }
    
    @objc func linkClicked(_ sender : UIButton){
		if let url = ContentURLFactory.urlForContentType(.mmTnc) {
			self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_TNC"), urlGetContentPage: url), animated: true)
		}
    }
    
    @objc func continueClicked(_ sender : UIButton) {
        
        var selectedTags : [Tag] = []
        for tag in tags {
            if tag.isSelected {
                //                var item = [String : Any]()
                //                item["TagId"] = tag.tagId
                //                item["Priority"] = tag.priority
                selectedTags.append(tag)
            }
        }
        Log.debug("count: \(selectedTags.count) tags")
//        self.saveTags(selectedTags)
    }
    
    //MARK: Navigation Bar methods
    func backupNavigationBar() {
        if let navigationController = self.navigationController {
            if let textAttributes = navigationController.navigationBar.titleTextAttributes {
                titleTextAttributes = textAttributes
            }
            navigationBGImage = navigationController.navigationBar.backgroundImage(for: UIBarMetrics.default)
            navigationShadowImage = navigationController.navigationBar.shadowImage
            navigationTranslucent = navigationController.navigationBar.isTranslucent
            navigationBGColor = navigationController.view.backgroundColor
            barTintColor = navigationController.navigationBar.tintColor
        }
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            isFakeNavigationBarHiden = navigationController.isFakeViewHiden()
//        }
    }
    func revertNavigationBar() {
        if let navigationController = self.navigationController {
            navigationController.navigationBar.titleTextAttributes = titleTextAttributes
            navigationController.navigationBar.setBackgroundImage(navigationBGImage, for: UIBarMetrics.default)
            navigationController.navigationBar.shadowImage = navigationShadowImage
            navigationController.navigationBar.isTranslucent = navigationTranslucent
            navigationController.view.backgroundColor = navigationBGColor
            navigationController.navigationBar.tintColor = barTintColor
        }
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            navigationController.setFakeViewHiden(isFakeNavigationBarHiden)
//        }
    }
    func setupNavigationBar() {
        if let navigationController = self.navigationController {
            navigationController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.tintColor = UIColor.clear
            navigationController.view.backgroundColor = UIColor.clear
        }
//        if let navigationController = self.navigationController as? GKFadeNavigationController {
//            navigationController.setFakeViewHiden(true)
//        }
        self.navigationItem.setHidesBackButton(true, animated:false);
    }
    
    func crateTagGroup () {
        
        let availableWidth = self.view.bounds.width - (MarginLeft * 2 + LineSpacing)
        var rowWidth = CGFloat(0)
        var tagGroup = TagGroup()
        for tag in tags {
            var tagWidth = StringHelper.getTextWidth(tag.tagName, height: CellHeight, font: textFont) + TagMarginLeftRight * 2
            if tagWidth > availableWidth {
                tagWidth = availableWidth
            }
            if tagWidth + rowWidth <= availableWidth {
                tagGroup.arrayTags.append(tag)
                rowWidth += (tagWidth + LineSpacing)
            }
            else
            {
                tagGroup.width = rowWidth - LineSpacing
                tagGroups.append(tagGroup)
                tagGroup = TagGroup()
                tagGroup.arrayTags.append(tag)
                rowWidth = (tagWidth + LineSpacing)
            }
        }
        tagGroup.width = rowWidth
        tagGroups.append(tagGroup)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KeywordCellId, for: indexPath) as! KeywordCellExtension
        let tag = tagGroups[indexPath.section].arrayTags[indexPath.row]
        cell.nameLabel.text = tag.tagName
        cell.selected(tag.isSelected, animated: false)
        if self.isScrolling {
            cell.alpha = 1.0
        } else {
            cell.alpha = 0
            cell.transform = CGAffineTransform.identity.translatedBy(x: 0, y: 7)
            let previousTags = getPreviousTagsCount(indexPath.section)
            UIView.animate(withDuration: 0.5, delay: Double(previousTags + indexPath.item) * 0.05 , options: UIViewAnimationOptions(), animations: {
                
                cell.alpha = 1.0
                cell.transform = CGAffineTransform.identity
                }, completion: { (complete) in
                    
            })
        }
        return cell
    }
    
    func getPreviousTagsCount(_ section: Int) -> Int{
        if (section == 0){  return 0 }
        
        var tagCount = 0
        for i in 0..<section {
            tagCount += tagGroups[i].arrayTags.count
        }
        return tagCount
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagGroups[section].arrayTags.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return tagGroups.count
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var width = StringHelper.getTextWidth(tagGroups[indexPath.section].arrayTags[indexPath.row].tagName, height: CellHeight, font: textFont) + TagMarginLeftRight * 2
        if width > self.view.bounds.width - MarginLeft * 2 {
            width = self.view.bounds.width - MarginLeft * 2
        }
        return CGSize(width: width,height: CellHeight)
        
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let marginLeft =  (self.view.bounds.width - tagGroups[section].width) / 2
        return UIEdgeInsets(top: LineSpacing, left: marginLeft, bottom: 2, right: marginLeft)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return LineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LineSpacing
    }
    
    //MARK: Collection View Delegate methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let tag = tagGroups[indexPath.section].arrayTags[indexPath.row]
        tag.isSelected = !tag.isSelected
        if tag.isSelected {
            tagSelectedCount += 1
        }
        else {
            tagSelectedCount -= 1
        }
        //        collectionView.reloadItemsAtIndexPaths([indexPath])
        
        if let cell = collectionView.cellForItem(at: indexPath) as? KeywordCellExtension {
            cell.selected(tag.isSelected, animated: false)
        }
        
        
//        self.updateConditionButton()
    }
 
    //MARK: Reload all data
    func reloadAllData(){
        self.collectionView.reloadData()
    }
    
    //Override right bar button
    func createSkipButton() {
        let rightArrow = UIImageView(image: UIImage(named: "bar_icon_arrow_white"))
        let rightButton = UIButton(type: UIButtonType.system)
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
        rightButton.addTarget(self, action: #selector(self.skipButtonClicked), for: UIControlEvents.touchUpInside)
        self.view.addSubview(rightButton)
    }
    
    // MARK: Skip button
    @objc func skipButtonClicked (_ sender:UIBarButtonItem) {
        self.navigationController?.push(CuratorPickViewController(), animated: true)
    }
    
    //MARK: Scroll Delegate
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
         Log.debug("++++++++++++++: scrollViewDidEndDragging")
        if (!decelerate) {
            Log.debug("++++++++++++++: scrollViewDidEndDragging $$$$$$$$$$$")
        }
        self.isScrolling = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        Log.debug("***********: scrollViewDidEndDecelerating")
        self.isScrolling = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        Log.debug("============= scrollViewDidScroll")
        self.isScrolling = true
    }

    
}

//TODO temporary, will implement this class later
class TagGroup: NSObject {
    var groupName = ""
    var width = CGFloat(0)
    var arrayTags : [Tag] = []
}

