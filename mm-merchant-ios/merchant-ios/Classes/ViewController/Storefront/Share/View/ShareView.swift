//
//  ShareView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import QRCode

protocol ShareViewDelegate : NSObjectProtocol {
    func didClickPublishButton()
}
enum ShareObjectType:Int {
    case shareProduct = 0,
    shareUser,
    shareMerchant,
    shareBrand,
    shareContentPage,
    sharePost,
    shareUnknown
}
class ShareView: UIView {
    // MARK: - Social network share function -
    private let key_title = "title"
    private let key_description = "description"
    private let key_contentImage = "imageKey"
    private let key_article_thumb = "article_thumb_image"
    private final let MarginLeftRight : CGFloat = 10.0
    private final let MarginTopBottom : CGFloat = 10.0
    private final let ButtonPublishHeight : CGFloat = 44
    private final let ButtonCloseHeight : CGFloat = 30
    private final let IconWidth : CGFloat = 40
    private final let LabelHeight : CGFloat = 20
    private final let ContentMarginTop : CGFloat = 64
    private final let ViewBottomHeight : CGFloat = 110
    private final let ImageHeight : CGFloat = 240
    private final let HeaderHeight : CGFloat = 55
    private final let QrCodeWidth : CGFloat = 90
    private final let PdpBrandImageWidth : CGFloat = 315
    private final let PdpBrandImageHeight : CGFloat = 84.0
    private final let ViewCenterHeight : CGFloat = 344
    private final let DiamondWidth : CGFloat = 30
    weak var shareViewDelegate : ShareViewDelegate?
    //View Header
    private let mmIconView = UIImageView()
    private let  labelAppName = UILabel()
    private let labelUnder = UILabel()
    private let viewLine = UIView()
    private let viewHeader = UIView()
    
    private var viewBitmap  = UIView()
    private let scrollView = UIScrollView()
    private var viewContent  = UIView()
    private let viewOverlay = UIView()
    private let imageView = UIImageView()
    private let viewBottom = UIView()
    private let viewCenter = UIView()
    var buttonPublish = UIButton()
    var buttonClose = UIButton(type: UIButtonType.custom)
    let labelPageName = UILabel()
    let labelCateName = UILabel()
    let labelQrNote = UILabel()
    let labelItemName = UILabel()
	let labelDescription = UILabel()
    let labelPrice = UILabel()
    let imageViewQrCode = UIImageView()
    let imageViewLogo = UIImageView()
    let imageViewDiamond = UIImageView()
    private var shareMethod = ShareMethod.unknown
    private var dict : [String: Any] = [:]
    private var shareObjectType : ShareObjectType = .shareProduct
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        self.backgroundColor = UIColor.clear
        viewOverlay.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        viewOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hide)))
        self.addSubview(viewOverlay)
        viewBitmap.backgroundColor = UIColor.white
        viewContent.backgroundColor = UIColor.white
        imageView.backgroundColor = UIColor.white

        //Header view
        let primaryIconsDictionary = (Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary)?["CFBundlePrimaryIcon"] as? NSDictionary
        let iconFiles = primaryIconsDictionary!["CFBundleIconFiles"] as! NSArray
        let lastIcon = iconFiles.lastObject as! NSString
        mmIconView.image = UIImage(named: lastIcon as String)
        mmIconView.layer.cornerRadius = 3.0
        viewHeader.addSubview(mmIconView)
        labelAppName.format()
        labelAppName.text = String.localize("LB_CAPP_APPNAME")
        viewHeader.addSubview(labelAppName)
        labelUnder.format()
        labelUnder.textColor = UIColor.secondary4()
        labelUnder.text = String.localize("LB_CAPP_MKT_SLOGON")
        viewHeader.addSubview(labelUnder)
        viewLine.backgroundColor = UIColor.secondary1()
        viewHeader.addSubview(viewLine)
        viewBitmap.addSubview(viewHeader)
        
        //Center view
        viewCenter.backgroundColor = UIColor.white
        viewBitmap.addSubview(viewCenter)
        
        //Bottom View
        viewBottom.addSubview(imageViewQrCode)
        labelQrNote.format()
        labelQrNote.text = String.localize("LB_QR_NOTE")
        labelQrNote.textColor = UIColor.secondary4()
        viewBottom.addSubview(labelQrNote)
        labelItemName.format()
        labelItemName.text = ""
		
		labelDescription.format()
		labelDescription.text = ""
		labelDescription.textColor = UIColor.secondary4()
		viewBottom.addSubview(labelDescription)
		
		viewBottom.addSubview(labelItemName)
        viewBottom.backgroundColor = UIColor.white
        viewBitmap.addSubview(viewBottom)
		
        viewContent.addSubview(viewBitmap)
        buttonPublish.formatPrimary()
        buttonPublish.addTarget(self, action: #selector(self.didClickSubmmitButon), for: .touchUpInside)
        buttonPublish.setTitle(String.localize("LB_CA_PUBLISH"), for: UIControlState())
        viewContent.addSubview(buttonPublish)
        
        buttonClose.setTitleColor(UIColor.white, for: UIControlState())
        buttonClose.addTarget(self, action: #selector(self.hide), for: .touchUpInside)
        buttonClose.setImage(UIImage.init(named: "btn_close_grey"), for: UIControlState())
        viewContent.addSubview(buttonClose)
        
        let contentHeight = ViewCenterHeight + ViewBottomHeight + ButtonPublishHeight + MarginTopBottom * 2 + HeaderHeight
        if contentHeight + 64 > frame.size.height {
            self.scrollView.addSubview(viewContent)
            scrollView.backgroundColor = UIColor.clear
            self.scrollView.frame = self.bounds
            self.scrollView.contentSize = CGSize(width: self.bounds.width, height: contentHeight + 64)
            self.addSubview(scrollView)
            
        } else {
            self.addSubview(viewContent)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCenterView(_ shareType: ShareObjectType) {
        switch shareType {
        case .shareProduct:
            imageView.contentMode = .scaleAspectFit
            viewCenter.addSubview(imageView)
            labelPrice.format()
            labelPrice.text = ""
            viewBottom.addSubview(labelPrice)
            break
        case .shareUser:
            imageView.contentMode = .scaleAspectFill
            viewCenter.addSubview(imageView)
            imageViewLogo.contentMode = .scaleAspectFill
            viewCenter.addSubview(imageViewLogo)
            labelPageName.formatSize(20)
            labelPageName.textAlignment = .center
            labelPageName.isHidden = false
            viewCenter.addSubview(labelPageName)
            imageViewDiamond.contentMode = .scaleAspectFit
            imageViewDiamond.image = UIImage(named: "curator_diamond")
            viewCenter.addSubview(imageViewDiamond)
            break
        case .shareMerchant:
            imageView.contentMode = .scaleAspectFit
            viewCenter.addSubview(imageView)
            imageViewLogo.contentMode = .scaleAspectFit
            viewCenter.addSubview(imageViewLogo)
            break
        case .shareContentPage:
            imageView.contentMode = .scaleAspectFit
            viewCenter.addSubview(imageView)
            labelPageName.formatSizeInFloat(18)
            labelPageName.text = "labelPageName"
            labelPageName.textAlignment = .center
            viewCenter.addSubview(labelPageName)
            labelCateName.format()
            labelCateName.textColor = UIColor.secondary4()
            labelCateName.text = "labelCateName"
            labelCateName.textAlignment = .center
            viewCenter.addSubview(labelCateName)
            break
        case .sharePost:
            imageView.contentMode = .scaleAspectFit
            viewCenter.addSubview(imageView)
            break
        default:
            break
        }
    }
    
    func layoutForProduct(){
        let width = (ImageHeight + PdpBrandImageHeight) / Constants.Ratio.ProductImageHeight
        imageView.frame = CGRect(x: (viewBitmap.bounds.width - width) / 2, y: MarginTopBottom, width: width , height: ImageHeight + PdpBrandImageHeight)
        labelItemName.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelQrNote.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        labelItemName.textColor = UIColor.secondary4()
		labelDescription.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelItemName.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
		labelPrice.frame = CGRect(x: labelItemName.frame.minX, y: labelItemName.frame.maxY, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        labelPrice.textColor = UIColor.secondary4()
        viewLine.frame = CGRect(x: 5, y: HeaderHeight - 1, width: viewHeader.bounds.width - 10, height: 1)
    }
    
    func layoutForUser() {
        imageView.frame = CGRect(x: 0 ,y: 0, width: viewCenter.bounds.width , height: ImageHeight)
        imageViewLogo.frame = CGRect(x: viewCenter.frame.midX - 50 , y: imageView.frame.maxY - 70, width: 100, height: 100)
        imageViewLogo.layer.cornerRadius = 50
        labelPageName.frame = CGRect(x: 0 ,y: imageViewLogo.frame.maxY + 10, width: viewCenter.bounds.width , height: 30)
        imageViewDiamond.frame = CGRect(x: imageViewLogo.frame.maxX - (DiamondWidth - 5) , y: imageViewLogo.frame.maxY - (DiamondWidth - 5), width: DiamondWidth, height: DiamondWidth)
    }
    
    func layoutForMerchant() {
        imageView.frame = CGRect(x: 0 ,y: 0, width: viewCenter.bounds.width , height: ImageHeight)
        let width = PdpBrandImageWidth * 2 / 3
        imageViewLogo.frame = CGRect(x: viewCenter.frame.midX - width / 2 , y: imageView.frame.maxY + MarginTopBottom, width: width, height: PdpBrandImageHeight * 2 / 3)
    }
    
    
    func layOutForContentPage() {
        imageView.frame = CGRect(x: 0 ,y: 0, width: viewCenter.bounds.width , height: ImageHeight)
        labelPageName.frame = CGRect(x: 0, y: imageView.frame.maxY + MarginTopBottom, width: viewCenter.bounds.width, height: 30)
        labelCateName.frame = CGRect(x: 0, y: labelPageName.frame.maxY, width: viewCenter.bounds.width, height: LabelHeight)
    }
    
    func layoutForPost() {
        imageView.frame = CGRect(x: 0, y: MarginTopBottom, width: viewCenter.bounds.width , height: ImageHeight + PdpBrandImageHeight)
        labelItemName.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelQrNote.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        labelItemName.textColor = UIColor.secondary4()
		labelDescription.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelItemName.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        viewLine.frame = CGRect(x: 5, y: HeaderHeight - 1, width: viewHeader.bounds.width - 10, height: 1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewOverlay.frame = self.bounds
       
        let contentHeight = ViewCenterHeight + ViewBottomHeight + ButtonPublishHeight + MarginTopBottom * 2 + HeaderHeight
        if contentHeight > self.bounds.height {
            viewContent.frame = CGRect(x: 15, y: 32, width: bounds.width - 30, height: contentHeight)
        } else {
            viewContent.frame = CGRect(x: 15, y: (bounds.height - contentHeight) / 2, width: bounds.width - 30, height: contentHeight)
        }
        viewBitmap.frame = CGRect(x: 0, y: 0, width: viewContent.bounds.width, height: viewContent.bounds.height - (ButtonPublishHeight + MarginTopBottom))
        //Header view
        viewHeader.frame = CGRect(x: 0, y: 0, width: viewBitmap.bounds.width, height: HeaderHeight)
        mmIconView.frame = CGRect(x: MarginLeftRight, y: 5, width: IconWidth, height: IconWidth)
        labelAppName.frame = CGRect(x: mmIconView.frame.maxX + MarginLeftRight, y: 5, width: viewContent.frame.width - (mmIconView.frame.maxX + buttonPublish.frame.width + MarginLeftRight * 2), height: LabelHeight)
        labelUnder.frame = CGRect(x: mmIconView.frame.maxX + MarginLeftRight, y: labelAppName.frame.maxY, width: viewContent.frame.width - (mmIconView.frame.maxX + buttonPublish.frame.width + MarginLeftRight * 2), height: LabelHeight)
        
        buttonPublish.frame = CGRect( x: MarginLeftRight, y: viewContent.bounds.height - (ButtonPublishHeight + MarginTopBottom), width: viewContent.bounds.width - MarginLeftRight * 2, height: ButtonPublishHeight)
        
        buttonClose.frame = CGRect(x: viewContent.frame.width - (ButtonCloseHeight + MarginLeftRight), y: (HeaderHeight - ButtonCloseHeight) / 2, width: ButtonCloseHeight, height: ButtonCloseHeight)
        viewCenter.frame = CGRect(x: 0,y: HeaderHeight, width: viewBitmap.bounds.width , height: ViewCenterHeight)
        
        viewBottom.frame = CGRect(x: 0,y: viewCenter.frame.maxY, width: viewBitmap.bounds.width , height: ViewBottomHeight)
        imageViewQrCode.frame = CGRect(x: 15,y: MarginTopBottom, width: QrCodeWidth , height: QrCodeWidth)
        labelQrNote.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: imageViewQrCode.frame.minY, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        labelItemName.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelQrNote.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
		labelDescription.frame = CGRect(x: imageViewQrCode.frame.maxX + 15, y: labelItemName.frame.maxY + MarginTopBottom, width: viewBottom.bounds.width - (QrCodeWidth + 30), height: LabelHeight)
        switch shareObjectType {
        case .shareProduct:
            self.layoutForProduct()
            break
        case .shareMerchant:
            self.layoutForMerchant()
            break
        case .shareUser:
            self.layoutForUser()
            break
        case .shareContentPage:
            self.layOutForContentPage()
        case .sharePost:
            self.layoutForPost()
            break
        default:
            break
        }
       
    }
    
    @objc func didClickSubmmitButon(){
        ShareManager.sharedManager.shareObjectByMethod(dict, method: shareMethod)
        self.hide()
        if let delegate = self.shareViewDelegate {
            delegate.didClickPublishButton()
        }
    }
    
    
    func showShareBrand(_ brand: Brand, method: ShareMethod, dictData : [String: Any]) {
        shareObjectType = .shareMerchant
        self.setupCenterView(shareObjectType)
       // dict[key_title] = brand.brandName
        dict = dictData
        shareMethod = method
        if brand.profileBannerImage.length > 0 {
            imageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(brand.profileBannerImage, category:.brand), placeholderImage: UIImage(named: "holder"), contentMode: .scaleAspectFill)
        } else {
            imageView.image = UIImage(named: "default_cover")
        }
        imageViewLogo.mm_setImageWithURL(ImageURLFactory.URLSize512(brand.headerLogoImage, category:.brand), placeholderImage : nil, contentMode: .scaleAspectFit)
       
        labelItemName.text = brand.brandName
       
        self.createQrCode(EntityURLFactory.brandURL(brand).absoluteString)
        self.show()
    }
    
    
    
    func show() {
        let win:UIWindow = UIApplication.shared.delegate!.window!!
        win.addSubview(self)
    }
    
    @objc func hide() {
        self.removeFromSuperview()
    }
    
    private func createQrCode(_ urlString: String){
        var qrCode = QRCode(urlString)
        qrCode?.color = CIColor(rgba: "000000")
        imageViewQrCode.image = qrCode?.image
    }
    
    private func generateBitmap() -> UIImage{
        var ratio = 1080 / self.viewBitmap.frame.size.width//Max with 1080 (width of iphone 6s plus)
        if let image = self.imageView.image {
            let scale = image.size.width / self.imageView.frame.width
            if scale < ratio {
                ratio = scale
            }
        }
        UIGraphicsBeginImageContext(CGSize(width: self.viewBitmap.frame.size.width * ratio, height: self.viewBitmap.frame.size.height * ratio))
		if let context = UIGraphicsGetCurrentContext() {
			context.scaleBy(x: ratio, y: ratio);
			self.viewBitmap.layer.render(in: context)
			let image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			return image!
		}
		return UIImage()
    }
    
    func price(_ style: Style) -> String? {
        var price: String?
        
        if style.isSale > 0 {
            price = style.priceSale.formatPrice()
        } else {
            price = style.priceRetail.formatPrice()
        }
        
        return price
    }
}
