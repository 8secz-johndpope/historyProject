//
//  TSChatShareProductCell.swift
//  merchant-ios
//
//  Created by Alan YU on 21/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class TSChatShareProductCell: TSChatBaseCell { 
    
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var merchantImage: UIImageView!
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var productRemark: UILabel!
    @IBOutlet weak var lblTimestamp: UILabel!
    @IBOutlet weak var warningImage: UIImageView!
    
    var swipeMenu: SwipeMenu!
    private var style: Style!
    var targetUser: User?
    var me: User?
    var buyHandler: ((_ cell: TSChatShareProductCell, _ style: Style, _ isSwipe: Bool?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTimestamp.textColor = UIColor.secondary3()
        lblTimestamp.font = UIFont.systemFont(ofSize: 11)

        productName.formatSmall()
        productRemark.formatSmall()
        
        let longPress = LongPressGestureRecognizer()
        viewContent.addGestureRecognizer(longPress)
        viewContent.isUserInteractionEnabled = true
        longPress.longPressHandler = { [weak self] sender in
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            if sender.state == .began {
                if let delegate = strongSelf.delegate {
                    delegate.cellDidPressLong(strongSelf)
                }
            }
            
        }
        
        
        let tap = TapGestureRecognizer()
        viewContent.addGestureRecognizer(tap)
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTaped = delegate.cellDidTaped else {
                    return
                }
                cellDidTaped(strongSelf)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
        
        let Margin = CGFloat(5)
        
        swipeMenu = SwipeMenu(price: nil, centerText: true)
        swipeMenu!.frame = CGRect(x: 10, y: productRemark.frame.minY - Margin - swipeMenu!.frame.height, width: swipeMenu!.frame.width, height: swipeMenu!.frame.height)

        self.swipeMenu.top = self.productImage.bottom + 7
        self.productRemark.top = self.swipeMenu.bottom + 7

        viewContent.addSubview(swipeMenu)
        
        swipeMenu?.doBuyBolock = { [weak self] isSwipe in
            
            guard let strongSelf = self else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                return
            }
            
            Log.debug("buy")
            if let callback = strongSelf.buyHandler {
                callback(strongSelf, strongSelf.style, isSwipe)
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
        }

    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        
        var rect = self.imageBackground.frame
        rect.size.height = self.productRemark.bottom + 15
        self.imageBackground.frame = rect
        
        self.viewContent.frame = rect

        if let productModel = model.productModel {
            fillContentWithData(productModel.style, model: model)
        } else if let shareSkuId = model.shareSkuId, let skuId = Int(shareSkuId) {
            _ = SearchService.searchStyleBySkuId(skuId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        let productModel = ProductModel()

                        if let searchResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = searchResponse.pageData, let style = pageData.first {
                            
                            productModel.style = style
                            
                            strongSelf.fillContentWithData(style, model: model)
                        } else {
                            strongSelf.fillContentWithData(nil, model: nil)
                        }
                        
                        model.productModel = productModel
                    }
                    else {
                        strongSelf.fillContentWithData(nil, model: nil)
                    }
                }
                else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }

            })
        }
        
        self.lblTimestamp.text = model.timeDate.detailChatTimeString

        self.setNeedsLayout()
    }
    
    func fillContentWithData(_ style: Style?, model: ChatModel?) {
        
        showWarning(false)
        
        if let myStyle = style, let myModel = model {
            
            self.style = myStyle
            merchantImage.ts_setImageWithURLString(ImageURLFactory.URLSize(.size128, key: myStyle.brandHeaderLogoImage, category: .brand).absoluteString)
            
            var productImageKey: String? = nil
            if let sku = myStyle.defaultSku() {
                productImageKey = myStyle.findImageKeyByColorKey(sku.colorKey)
            }
            
            productName.text = myStyle.skuName
            if myModel.fromMe {
                productRemark.text = (me?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_PDP_REMARK")
            }
            else {
                productRemark.text = (targetUser?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_PDP_REMARK")
            }
            self.productImage.backgroundColor = UIColor.white

            if let key = productImageKey {
                productImage.mm_setImageWithURL(
                    ImageURLFactory.URLSize750(key),
                    placeholderImage: UIImage(named: "Spacer"),
                    contentMode: .scaleAspectFit
                )}
            
            //Get default sku price
            swipeMenu.price = myStyle.getSkuPrice(colorIndex: -1, sizeIndex: -1).formatPrice()
            
            updateInactiveOrOutOfStockWithStyle(myStyle)
            
        } else {
            showWarning(true)
        }
    }
    
    func showWarning(_ isShowing: Bool) {
        
        self.warningImage.isHidden = !isShowing
        
        if isShowing {
            self.warningImage.center = productImage.center
            self.productImage.image = nil
            self.productImage.backgroundColor = UIColor.primary2()
            
            self.productRemark.text = String.localize("MSG_ERR_IM_DELETE_POST")
            self.productName.text = ""
            self.isUserInteractionEnabled = false
            
            swipeMenu.alpha = 0.4
            swipeMenu.isUserInteractionEnabled = false
            
        } else {
            self.productImage.backgroundColor = UIColor.gray
            self.productImage.image = UIImage(named: "mm_white")
            self.productImage.contentMode = .center
            self.productRemark.text = ""
            self.productName.text = ""
            self.isUserInteractionEnabled = true
        }
    }
    
    func updateInactiveOrOutOfStockWithStyle(_ style: Style) {
        let isValid = (style.isValid() && !style.isOutOfStock())
        
        swipeMenu.alpha = isValid ? 1.0 : 0.4
        swipeMenu.isUserInteractionEnabled = isValid
        
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        
        if model.fromMe {
            self.viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.viewContent.width
            imageBackground.image = UIImage(named: "shareUser_pink")
        } else {
            self.viewContent.left = kChatBubbleLeft
            imageBackground.image = UIImage(named: "shareUser_wht")
        }
        
        self.viewContent.top = self.avatarImageView.top
        self.lblTimestamp.bottom = self.imageBackground.bottom
        self.lblTimestamp.right = self.imageBackground.right - 7
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        return model.cellHeight
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    func CGRectCenterRectForResizableImage(_ image: UIImage) -> CGRect {
        return CGRect(
            x: image.capInsets.left / image.size.width,
            y: image.capInsets.top / image.size.height,
            width: (image.size.width - image.capInsets.right - image.capInsets.left) / image.size.width,
            height: (image.size.height - image.capInsets.bottom - image.capInsets.top) / image.size.height
        )
    }
    
    func _maskImage(_ image: UIImage, maskImage: UIImage) -> UIImage {
        let maskRef: CGImage = maskImage.cgImage!
        let mask: CGImage = CGImage(
            maskWidth: maskRef.width,
            height: maskRef.height,
            bitsPerComponent: maskRef.bitsPerComponent,
            bitsPerPixel: maskRef.bitsPerPixel,
            bytesPerRow: maskRef.bytesPerRow,
            provider: maskRef.dataProvider!,
            decode: nil,
            shouldInterpolate: false
            )!
        let maskedImageRef: CGImage = image.cgImage!.masking(mask)!
        let maskedImage: UIImage = UIImage(cgImage:maskedImageRef)
        // returns new image with mask applied
        return maskedImage
    }

    
}
