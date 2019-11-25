//
//  ThankYouView.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 4/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ThankYouView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var mainContainer = UIView()
    var descriptionContainer = UIView()
    
    var labelPayment = UILabel()
    var labelTaxNum = UILabel()
    let buttonLink = UIButton()
    var continueButton = UIButton()
    
    private var thankyouImageView = UIImageView()
    //private var lowerlineImageView = UIImageView()
    //private var upperlineImageView = UIImageView()
    private var thankyouMessageTextView = UITextView()
    var suggestedProductsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewLayout())
    
    private var dismissHandler: (() -> Void)?
    var didSelectProduct: ((Style) -> ())?
    
    private let LineSpacing: CGFloat = 20*Constants.ScreenSize.RATIO_HEIGHT
    private let ImageSize = Constants.DeviceType.IS_IPHONE_4_OR_LESS ? CGSize(width: 142*Constants.ScreenSize.RATIO_HEIGHT, height: 145*Constants.ScreenSize.RATIO_HEIGHT) : CGSize(width: 172*Constants.ScreenSize.RATIO_HEIGHT, height: 175*Constants.ScreenSize.RATIO_HEIGHT)
    private let DescriptionContainerHorizontalPadding: CGFloat = 40
    private let LabelHeight: CGFloat = 20
    private let ProductHorizontalPadding: CGFloat = 30
    private let ProductInteritemSpacing: CGFloat = 10
    private let MaxContainerVerticalPadding: CGFloat = Constants.DeviceType.IS_IPHONE_4_OR_LESS ? 10*Constants.ScreenSize.RATIO_HEIGHT : 40*Constants.ScreenSize.RATIO_HEIGHT
    private let MinContainerVerticalPadding: CGFloat = Constants.DeviceType.IS_IPHONE_4_OR_LESS ? 0 : 10*Constants.ScreenSize.RATIO_HEIGHT
    private var suggestedStyles = [Style]()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor.clear
        
        self.addSubview(mainContainer)
        self.setUpCollectionView()
        self.addSubview(descriptionContainer)
        
        // Main container
        thankyouImageView = UIImageView(image: UIImage(named: "thank_you"))
        mainContainer.addSubview(thankyouImageView)
        
        labelPayment.formatSizeInFloat(12*CGFloat(Constants.ScreenSize.FONT_SCALE_IPHONE6S))
        labelPayment.textColor = UIColor.white
        labelPayment.textAlignment = .center
        mainContainer.addSubview(labelPayment)
        
        labelTaxNum.formatSize(12*Int(Constants.ScreenSize.FONT_SCALE_IPHONE6S))
        labelTaxNum.textColor = UIColor.white
        labelTaxNum.textAlignment = .center
        mainContainer.addSubview(labelTaxNum)
        
        let linkString = String.localize("LB_CA_BILLING_DETAILS")
        buttonLink.titleLabel?.font = labelTaxNum.font
        buttonLink.titleLabel?.escapeFontSubstitution = true
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font : buttonLink.titleLabel?.font ?? UIFont(), NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.underlineStyle : NSUnderlineStyle.styleSingle.rawValue]
        let linkStringAttribute = NSAttributedString(string: linkString, attributes: attributes)
        buttonLink.setAttributedTitle(linkStringAttribute, for: UIControlState())
        buttonLink.isHidden = false
        mainContainer.addSubview(buttonLink)
        
        // Continue button
        continueButton.layer.backgroundColor = UIColor.primary1().cgColor
        continueButton.setTitle(String.localize("LB_CA_CONT_SHOP"), for: UIControlState())
        continueButton.titleLabel?.font = labelTaxNum.font
        continueButton.layer.cornerRadius = 3
        continueButton.isHidden = true
        self.addSubview(continueButton)
        
        //lowerlineImageView = UIImageView(image: UIImage(named: "white_line"))
        //lowerlineImageView.sizeToFit()
        //descriptionContainer.addSubview(lowerlineImageView)
        
        thankyouMessageTextView = { () -> UITextView in
            let textView = UITextView()
            textView.backgroundColor = UIColor.clear
            textView.text = String.localize("LB_CA_THANKYOU_C4A")
            textView.textColor = UIColor.white
            textView.isUserInteractionEnabled = false
            textView.textAlignment = .center
            if let fontName = textView.font?.fontName{
                textView.font = UIFont(name: fontName, size: 12*CGFloat(Constants.ScreenSize.FONT_SCALE_IPHONE6S))
            }
            
            return textView
        } ()
        descriptionContainer.addSubview(thankyouMessageTextView)
        
        //upperlineImageView = UIImageView(image: UIImage(named: "white_line"))
        //upperlineImageView.sizeToFit()
        //descriptionContainer.addSubview(upperlineImageView)
        
        setUpCollectionView()
        
        fetchProducts(true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpCollectionView(){
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.frame.width, height: 120)
        
        suggestedProductsCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        suggestedProductsCollectionView.dataSource = self
        suggestedProductsCollectionView.delegate = self
        suggestedProductsCollectionView.alwaysBounceVertical = true
        suggestedProductsCollectionView.register(ProductCell.self, forCellWithReuseIdentifier: ProductCell.CellIdentifier)
        suggestedProductsCollectionView.backgroundColor = UIColor.clear
        suggestedProductsCollectionView.isScrollEnabled = false
        suggestedProductsCollectionView.showsVerticalScrollIndicator = false
        suggestedProductsCollectionView.showsHorizontalScrollIndicator = false
        self.addSubview(suggestedProductsCollectionView)
    }
    
    func secondaryFormat() {
        self.buttonLink.isHidden = true // TODO: Per Jack, hide the button in UAT (Preview)
        self.continueButton.isHidden = false
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let containerVerticalPadding: CGFloat = continueButton.isHidden ? MaxContainerVerticalPadding : MinContainerVerticalPadding
        let continueButtonBottomPadding: CGFloat = continueButton.isHidden ? 0 : 20*Constants.ScreenSize.RATIO_HEIGHT
        let continueButtonSize = CGSize(width: self.width - 2*continueButtonBottomPadding, height: 40)
        
        // Continue button
        let continueButtonHeight: CGFloat = continueButton.isHidden ? 0 : continueButtonSize.height
        continueButton.frame = CGRect(x: (frame.width - continueButtonSize.width) / 2, y: frame.height - continueButtonHeight - continueButtonBottomPadding, width: continueButtonSize.width, height: continueButtonHeight)
        
        // Description container
        descriptionContainer.frame = CGRect(x: DescriptionContainerHorizontalPadding, y: 0, width: frame.width - (DescriptionContainerHorizontalPadding * 2), height: 1)

        thankyouMessageTextView.frame = CGRect(x: 0, y: 0, width: descriptionContainer.width, height: 0)
        thankyouMessageTextView.fitHeight()
        thankyouMessageTextView.frame = CGRect(x: 0, y: 0, width: descriptionContainer.width, height: thankyouMessageTextView.height)
        
//        upperlineImageView.frame = CGRect(x:0, y: thankyouMessageTextView.frame.minY - LineSpacing, width: descriptionContainer.width, height: 1)
//        lowerlineImageView.frame = CGRect(x:0, y: thankyouMessageTextView.frame.maxY + LineSpacing, width: descriptionContainer.width, height: 1)
        
        descriptionContainer.height = thankyouMessageTextView.height
        descriptionContainer.y = continueButton.y - thankyouMessageTextView.height - containerVerticalPadding
        
        // Suggested products
        updateSuggestedProductCollectionViewFrame()
        
        // Main container
        mainContainer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - descriptionContainer.y)
        
        thankyouImageView.frame = CGRect(x: (frame.width - ImageSize.width) / 2, y: 0, width: ImageSize.width, height: ImageSize.height)
        labelPayment.frame = CGRect(x: 0, y: thankyouImageView.frame.maxY + LineSpacing, width: frame.width, height: LabelHeight)
        labelTaxNum.frame = CGRect(x: 0, y: labelPayment.frame.maxY, width: frame.width, height: LabelHeight)
        
        let buttonLinkHeight: CGFloat = buttonLink.isHidden ? 0 : 30
        let linkWidth = StringHelper.getTextWidth((buttonLink.titleLabel?.text) ?? "", height: buttonLinkHeight, font: buttonLink.titleLabel?.font ?? UIFont())
        buttonLink.frame = CGRect(x: (frame.width - linkWidth) / 2 , y: labelTaxNum.frame.maxY, width: linkWidth, height: buttonLinkHeight)
        
        mainContainer.height = buttonLink.frame.maxY
        mainContainer.y = suggestedProductsCollectionView.y - mainContainer.height - containerVerticalPadding
    }
    
    private func updateSuggestedProductCollectionViewFrame(){
        let bottomPadding: CGFloat = continueButton.isHidden ? MaxContainerVerticalPadding : MinContainerVerticalPadding
        let productWidth = self.getProductWidth()
        let productHeight = self.getProductHeight(productWidth)
        var collectionWidth: CGFloat = 0.0
        let productCount = suggestedStyles.count
        if productCount == 0{
            collectionWidth = 0.0
        }
        else if productCount > 0{
            collectionWidth = CGFloat(productCount)*productWidth + 2*self.ProductInteritemSpacing
        }
        suggestedProductsCollectionView.frame = CGRect(x: (self.width - collectionWidth)/2, y: descriptionContainer.y - bottomPadding - productHeight, width: collectionWidth, height: productHeight)
    }
    
    // MARK: - CollectionView Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestedStyles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.getProductWidth()
        return CGSize(width: width, height: self.getProductHeight(width))
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return ProductInteritemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        return productCellAtIndexPath(collectionView, indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectProduct?(suggestedStyles[indexPath.row])
    }
    
    // MARK: - Cell setup
    
    private func productCellAtIndexPath(_ collectionView: UICollectionView, indexPath: IndexPath) -> ProductCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCell.CellIdentifier, for: indexPath) as! ProductCell
        customProductCell(cell)
        loadDataForProductCell(cell, style: suggestedStyles[indexPath.row])
        return cell
    }
    
    private func customProductCell(_ cell: ProductCell){
        cell.round(2.0)
        cell.backgroundColor = UIColor.white
        cell.heartImageView.isHidden = true
        
        let nameLabelFrame = cell.nameLabel.frame
        cell.nameLabel.frame = CGRect(x: 5, y: nameLabelFrame.minY, width: cell.frame.width - 10, height: nameLabelFrame.height)
        cell.nameLabel.formatSizeInFloat(11*CGFloat(Constants.ScreenSize.FONT_SCALE_IPHONE6S))
    }
    
    private func loadDataForProductCell(_ cell: ProductCell, style: Style){
        if let defaultSku = style.defaultSku() {
            cell.nameLabel.text =  defaultSku.skuName
            cell.imageView.backgroundColor = UIColor.primary2()
            
            ProductManager.setProductImage(imageView: cell.imageView, style: style, colorKey: defaultSku.colorKey, placeholderImage: UIImage(named: "brand_placeholder"), completion: { (image, error) -> Void in
                if image != nil {
                    cell.imageView.backgroundColor = UIColor.clear
                }
            })
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        cell.setBrandImage(style.brandHeaderLogoImage)
    }
    
    // MARK: Helpers
    
    private func fetchProducts(_ isNew: Bool){
        let styleFilter = StyleFilter()
        
        if isNew{
           styleFilter.isNew = 1
        }
        
        ProductManager.fetchStyles(styleFilter, pageSize: 3, pageNo: 1, completion: { [weak self] (styles, error) in
            if let strongSelf = self{
                if styles.isEmpty{
                    strongSelf.fetchProducts(false)
                }
                else{
                    strongSelf.suggestedStyles = styles
                    strongSelf.updateSuggestedProductCollectionViewFrame()
                    strongSelf.suggestedProductsCollectionView.reloadData()
                }
            }
        })
    }
    
    private func getProductWidth() -> CGFloat{
        return (frame.width - 2*self.ProductHorizontalPadding - 2*self.ProductInteritemSpacing)/3
    }
    
    private func getProductHeight(_ width: CGFloat) -> CGFloat{
        return width * Constants.Ratio.ProductImageHeight + 75
    }
}
