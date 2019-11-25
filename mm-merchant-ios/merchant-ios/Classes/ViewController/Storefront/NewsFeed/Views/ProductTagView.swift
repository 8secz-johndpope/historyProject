//
//  Tag.swift
//  TagLabel
//
//  Created by Vu Dinh Trung on 4/18/16.
//  Copyright © 2016 Vu Dinh Trung. All rights reserved.
//

import UIKit
import ObjectMapper

enum ModeCustomize: Int {
    case edit = 0,
    normal,
	view,
    special
}
enum ModeDirection: Int {
    case left = 0,
    right
}
enum ProductTagStyle: Int {
    case Brand = 0
    case Commodity = 1
    case Add = 2
}

@objc
protocol TagViewDelegate: NSObjectProtocol {
    @objc optional func didSelectedCloseButton(_ view: ProductTagView)
    @objc optional func updateTag(_ tag: ProductTagView)
    @objc optional func endMoveTag()
    @objc optional func touchDown(_ tag: ProductTagView)
    @objc optional func touchUp(_ tag: ProductTagView)
}
class ProductTagView: UIView {

	private final let SizePinPoint:CGFloat = 16.0
	private final let saleFont = UIFont.systemFont(ofSize: 11)
    private final let retailFont = UIFont.systemFont(ofSize: 11)

    private final let margin:CGFloat = 10.0
    private final let heighSelf: CGFloat = 62
    private final let widthCart: CGFloat = 62
    private final let HeightProductTag:CGFloat = 30
    private final let heightLabel:CGFloat = 36
	private final let WidthLabelMin:CGFloat = 35
	private final let ShadowWidth:CGFloat = 4
    private final let ShadowHeight:CGFloat = 2
	private final let priceTagY:CGFloat = 11
	
	var pinImageView = UIImageView()
    var commodityImageView = UIImageView()
    var productTagStyle:ProductTagStyle = .Brand
    var pinView = TagPinView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
    var tagTitleLabel = UILabel()
    var lastCenterPoint:CGPoint = CGPoint(x: 0, y: 0)
    var mode = ModeCustomize.normal
    var styleCode = ""
    var skuCode = ""
    var skuName = ""
    weak var tagDelegate: TagViewDelegate?
    var direction = ModeDirection.right
    var anchorPoint = CGPoint.zero
	var tagBodyButton = UIButton()
    var swapDirection = false
    var tapLocation = CGPoint.zero
    private var widthFrame:CGFloat = 0
	
	var baseView = UIView()
	var tapPoint : CGPoint!
	
	var finalLocation:CGPoint = CGPoint(x: 0, y: 0)
	
	var imageSize : CGSize!
	var oldPriceFloat : Double = 0.0
	var newPriceFloat : Double = 0.0
	var logoString = ""
	var productMode = ModeTagProduct.wishlist
    var sku = Sku() {
        didSet {
            self.tagTitleLabel.text = sku.brandName
        }
    }
    var title:String?{
        didSet {
            self.tagTitleLabel.text = title
        }
    }
    var tagTitle:String?
    var tagImage:String?
    var price : Double = 0
	var skuId : Int = 0
    var timer = Timer()
	
	var photoFrameIndex : Int = -1
	var isAddedManually : Bool = false
	var shouleBeHidden = false
	private var isPanning = false
	var centerPoint : CGFloat = 0.0
	var widthText : CGFloat = 0.0
    var place : TagPlace {
        switch direction {
            case .left:
                return TagPlace.left
            case .right:
                return TagPlace.right
        }
    }
    var positionX : Int {
        get{
            return ProductTagView.getTapPercentage(self.finalLocation).x
        }
    }
    
    var positionY : Int {
        get {
            return ProductTagView.getTapPercentage(self.finalLocation).y
        }
    }
	
    
    func getSku() -> Sku {
        
        sku.skuId = skuId
        sku.positionX = positionX
        sku.positionY = positionY
        sku.place = place
            
        return sku
    }
    
    
    
	//MARK: -

	convenience init(position: CGPoint, price: Double, parentTag: Int, delegate: TagViewDelegate, oldPrice: Double, newPrice: Double, logoImage: UIImage, logo: String, tagImageSize: CGSize, skuId: Int, place: TagPlace, mode: ModeCustomize = .normal,tagStyle:ProductTagStyle?) {
		
        self.init(frame: CGRect.zero)
		
		NotificationCenter.default.addObserver(self, selector: #selector(ProductTagView.exitEditMode), name: Constants.Notification.exitTagProductEditMode, object: nil)
		
		self.backgroundColor = UIColor.clear

        
        if let tagStyle = tagStyle{
            productTagStyle = tagStyle
        }
		
		self.tag = parentTag
		self.tagDelegate = delegate

		self.tapPoint = position
		
		self.baseView.tag = parentTag
		self.tagBodyButton.tag = parentTag
		self.imageSize = tagImageSize
		self.oldPriceFloat = oldPrice
		self.newPriceFloat = newPrice
		self.logoString = logo
		self.skuId = skuId
		self.mode = mode
		self.price = price
		self.setupTagContentLayout()
        
		self.tagTitleLabel.formatSingleLine(12)
        self.tagTitleLabel.numberOfLines = 1;
        self.tagTitleLabel.adjustsFontSizeToFitWidth = true;
        self.tagTitleLabel.baselineAdjustment = UIBaselineAdjustment.alignCenters
        self.tagTitleLabel.textColor = UIColor.white
        //self.tagTitleLabel.text = "Kate Spade"
        self.tagTitleLabel.text = sku.brandName
		self.frame = CGRect(x: 0, y: 0, width: tagImageSize.width, height: tagImageSize.height)
		
		centerPoint = UIScreen.main.bounds.width / 2
        
        
		
		self.widthFrame = widthText + margin * 2
		
		finalLocation = tapPoint
        self.configDirection(place)
		
		layoutSubviews()

//		startAnimation()
		
    }
    func configDirection(_ place: TagPlace = TagPlace.undefined) {
        
        switch place {
            
        case .undefined:
            
            if finalLocation.x < centerX {
                self.direction = .right
            } else {
                self.direction = .left
            }
            
            break
            
        case .left:
            self.direction = .left
            break
            
        case .right:
            self.direction = .right
            break
        }

    }
	override init(frame: CGRect) {
        super.init(frame: frame)
    }

	deinit {
		NotificationCenter.default.removeObserver(self, name: Constants.Notification.exitTagProductEditMode, object: nil)
	}
	
	class func offsetTouchPointForAddNewTag(_ point: CGPoint) -> CGPoint {
		var offsetPoint = CGPoint.zero
		offsetPoint.x = point.x - 31 // pinImageView.centerX
		offsetPoint.y = point.y - 15 // pinImageView.centerY
		return offsetPoint
	}
	
	class func getTapPercentage(_ touchPoint: CGPoint) -> (x: Int, y: Int) {
		
        let imageSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.width)
		Log.debug("touchPoint : \(touchPoint)")
		Log.debug("imageSize : \(imageSize)")
        
		
		let x = Int(Double(touchPoint.x / imageSize.width) * Double(Constants.TagPercentage.Offset))
		let y = Int(Double(touchPoint.y / imageSize.height) * Double(Constants.TagPercentage.Offset))
		
		Log.debug(Double(touchPoint.x / imageSize.width) * Double(Constants.TagPercentage.Offset))
		Log.debug(Double(touchPoint.y / imageSize.height) * Double(Constants.TagPercentage.Offset))
		
		Log.debug("x : \(x)")
		Log.debug("y : \(y)")
		
		return (x, y)
	}
	
	class func getTapPonit(_ tagPercentage: (x: Int, y: Int), imageSize: CGSize) -> CGPoint {
		
		let x = (Double(tagPercentage.x) / Double(Constants.TagPercentage.Offset)) * Double(imageSize.width)
		let y = (Double(tagPercentage.y) / Double(Constants.TagPercentage.Offset)) * Double(imageSize.height)
		
		let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
		
		return point
	}
	
	@objc func exitEditMode() {
		if self.mode == .edit {
			self.mode = .normal
//			self.pinImageView.image = UIImage(named: "RedDot")
		}
	}
	
	func setupTagContentLayout() {
		
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ProductTagView.handleLongPress))
		let singleTap = UITapGestureRecognizer(target: self, action: #selector(ProductTagView.singleTap))
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ProductTagView.doubleTap))
		let panRecognizer = UIPanGestureRecognizer(target:self, action:#selector(ProductTagView.detectPan))
		
		singleTap.numberOfTapsRequired = 1
		doubleTap.numberOfTapsRequired = 2

		
		pinImageView.image = UIImage(named: "RedDot")
        
        tagBodyButton.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
		tagBodyButton.layer.cornerRadius = 5.0
        
		tagTitleLabel.text = ""
		tagBodyButton.addSubview(tagTitleLabel)
		
		self.isUserInteractionEnabled = true
		self.gestureRecognizers = [panRecognizer]
		self.tagBodyButton.isUserInteractionEnabled = true
		
		if mode == .special {
            self.tagBodyButton.addGestureRecognizer(singleTap)
		} else {
			// Edit , Normal, View,
			self.tagBodyButton.addGestureRecognizer(doubleTap)
            self.tagBodyButton.addGestureRecognizer(longPress)
            tagBodyButton.addTarget(self, action: #selector(self.toucheUp), for: UIControlEvents.touchUpInside);
            tagBodyButton.addTarget(self, action: #selector(self.toucheUp), for: UIControlEvents.touchCancel);
            tagBodyButton.addTarget(self, action: #selector(self.toucheDown), for: UIControlEvents.touchDown);
		}
	}

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
    override func layoutSubviews() {
        super.layoutSubviews()
		
		self.layoutTagContext()
    }

	func layoutTagContext() {
		 
        let heightTag = HeightProductTag
        if let text = self.tagTitleLabel.text{
            widthText = getTextWidth(text, height: heightLabel, font: self.tagTitleLabel.font, tapPoint: tapPoint)
        }
		
		let widthTag = SizePinPoint/2 + widthText + ShadowWidth * 2
		let width = widthTag + heightTag
		
		baseView.removeFromSuperview()
        let heightBaseView = heightTag
		baseView = UIView(frame: CGRect(x: finalLocation.x - (ShadowWidth + SizePinPoint / 2), y: finalLocation.y - heightBaseView / 2, width: width, height: heightBaseView))
        
        
        let commodityImageView = UIImageView()
        if productTagStyle == .Commodity {
            if self.direction == .left {
                commodityImageView.image = UIImage(named: "tag_bag2")
            }else if self.direction == .right {
                commodityImageView.image = UIImage(named: "tag_bag1")
            }
            
        }else if productTagStyle == .Brand {
            commodityImageView.image = UIImage(named: "tag_brand")
        }else if productTagStyle == .Add {
            commodityImageView.image = UIImage(named: "post_addtag")
        }
        commodityImageView.sizeToFit()
        
		self.addSubview(baseView)
        baseView.addSubview(tagBodyButton)
        baseView.addSubview(pinView)
        baseView.addSubview(commodityImageView)

		switch direction {
		case .left:
            if productTagStyle == .Commodity {
                self.tagBodyButton.frame = CGRect(x: baseView.frame.width - (SizePinPoint + widthTag + ShadowWidth * 2) + heightTag, y: 0, width: widthTag , height: heightTag)
                self.tagTitleLabel.frame = CGRect(x:margin,y: 0,width: widthText,height: HeightProductTag)
                
                var rect = self.baseView.frame
                rect.origin.x -= self.baseView.frame.width - (ShadowWidth + SizePinPoint )
                self.baseView.frame = rect
                self.pinView.frame = CGRect(x:self.tagBodyButton.frame.maxX ,y: (heightTag - SizePinPoint)/2,width: SizePinPoint,height: SizePinPoint)
                commodityImageView.frame = CGRect(x: self.tagBodyButton.frame.originX - heightTag + 5, y: 0, width: heightTag, height: heightTag)
                
            }else if productTagStyle == .Brand {
                self.tagBodyButton.frame = CGRect(x: baseView.frame.width - (SizePinPoint + widthTag + ShadowWidth * 2) + heightTag, y: 0, width: widthTag + heightTag , height: heightTag )
                self.tagTitleLabel.frame = CGRect(x:margin + 20 + 5,y: 0,width: widthText,height: HeightProductTag)
                
                var rect = self.baseView.frame
                rect.origin.x -= self.baseView.frame.width - (ShadowWidth + SizePinPoint )
                self.baseView.frame = rect
                
                self.pinView.frame = CGRect(x:self.tagBodyButton.frame.maxX ,y: (heightTag - SizePinPoint)/2,width: SizePinPoint,height: SizePinPoint)
                commodityImageView.frame = CGRect(x: 15 + heightTag, y: (heightTag - commodityImageView.size.height)/2, width: commodityImageView.size.width, height: commodityImageView.size.height)

            }


			break
			
		case .right:
            self.pinView.frame = CGRect(x: ShadowWidth, y: (heightTag - SizePinPoint)/2, width: SizePinPoint, height: SizePinPoint)
            if productTagStyle == .Commodity || productTagStyle == .Add{
                self.tagBodyButton.frame = CGRect(x: SizePinPoint + ShadowWidth, y: 0, width: widthTag + 5, height: heightTag)
                self.tagTitleLabel.frame = CGRect(x:margin,y: 0,width: widthText,height: HeightProductTag)
                commodityImageView.frame = CGRect(x: self.tagBodyButton.frame.maxX - 5, y: 0, width: heightTag, height: heightTag)
                
            }else if productTagStyle == .Brand {
                self.tagBodyButton.frame = CGRect(x: SizePinPoint + ShadowWidth, y: 0, width: widthTag + heightTag, height: heightTag)
                commodityImageView.frame = CGRect(x: SizePinPoint + ShadowWidth + margin, y: (heightTag - commodityImageView.size.height)/2, width: commodityImageView.size.width, height: commodityImageView.size.height)
                self.tagTitleLabel.frame = CGRect(x:margin + 20 + 5,y: 0,width: widthText,height: HeightProductTag)
            }

			break
			
		}
		
		
		adjustTagPosition(baseView)
        if !self.pinView.isAnimating {
            self.pinView.startAnimation()
        }
        
	}
	
	func rotateLabel(_ label: UILabel, angle: CGFloat) {
		label.transform = CGAffineTransform(rotationAngle: (angle / 180.0) * CGFloat.pi)
	}
	
	func getTextWidth(_ text: String, height: CGFloat, font: UIFont, tapPoint: CGPoint) -> CGFloat {
		
		let maxMarginForText = centerPoint - (margin * 2)
		
		// Calculate text label width based on the text length and the remaining screen width space
		let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
		let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
		
		if maxMarginForText > boundingBox.width {
            if boundingBox.width < WidthLabelMin {
                return WidthLabelMin
            }
			return boundingBox.width
		}
        
		return maxMarginForText
    }
    

    func setupFrameLabelText() -> Void {
        self.tagTitleLabel.frame = CGRect(x: margin, y: 0, width: widthText, height: HeightProductTag )
        
    }
    
    // MARK: - Detect Pan Gesture
	
    @objc func detectPan(_ recognizer:UIPanGestureRecognizer) {
        if (self.mode == .edit) && (String(describing: recognizer.classForCoder) == "UIPanGestureRecognizer") {
			
            switch recognizer.state {
            case .began:
				// Remember original location
				self.lastCenterPoint = baseView.center
                Log.debug("------------detectPan .Began")
                self.isPanning = true
                break
            case .changed:
				
				let translation  = recognizer.translation(in: baseView)
                let xTranslationBaseView = lastCenterPoint.x + translation.x
                let yTranslationBaseView = lastCenterPoint.y + translation.y
                let limitHeightAndShadowBaseView = HeightProductTag/2 + ShadowWidth
                
                var center = self.baseView.center
                if yTranslationBaseView <= UIScreen.main.bounds.size.width - limitHeightAndShadowBaseView && (yTranslationBaseView - HeightProductTag/2) > ShadowWidth{
                    center.y = lastCenterPoint.y + translation.y
                }
                
                if self.direction == .right{
                    let limitWidthBaseView = xTranslationBaseView + baseView.frame.sizeWidth/2 - self.pinView.frame.sizeWidth
                    if (xTranslationBaseView - baseView.frame.sizeWidth/2 + ShadowWidth) > 0 && UIScreen.main.bounds.size.width - limitWidthBaseView >= ShadowWidth{
                        center.x = lastCenterPoint.x + translation.x
                    }
                }
                else{
                    let limitWidthBaseView = xTranslationBaseView + baseView.frame.sizeWidth/2 - ShadowWidth
                    if (xTranslationBaseView - baseView.frame.sizeWidth/2 + self.pinView.frame.sizeWidth) >= ShadowWidth && UIScreen.main.bounds.size.width - limitWidthBaseView > 0{
                        center.x = lastCenterPoint.x + translation.x
                    }
                }
                
                self.baseView.center = center
                break
				
            case .ended:
                self.isPanning = false
                lastCenterPoint = baseView.center
				
				
				if direction == .left {
                    self.finalLocation = CGPoint(x: baseView.frame.origin.x + self.baseView.frame.width - SizePinPoint / 2 , y: baseView.frame.origin.y + baseView.frame.height / 2)
                } else {
                    self.finalLocation = CGPoint(x: baseView.frame.origin.x + (ShadowWidth + SizePinPoint / 2), y: baseView.frame.origin.y + baseView.frame.height / 2)
                }
								
				// update tag
				self.tagDelegate?.updateTag?(self)
                self.tagDelegate?.endMoveTag?()
                break
            default:
                break
                
            }

        }
        
    }
	
	func adjustTagPosition(_ tagBaseView: UIView) {
		
		var baseRect = tagBaseView.frame as CGRect
		baseRect.size.height = HeightProductTag
		
        let fullImageRect = CGRect(x: 0, y: 0, width: self.imageSize.width, height: self.imageSize.height)
		
		let intersectedRect = fullImageRect.intersection(baseRect)
		
		let rectX = Double(intersectedRect.origin.x)
		let rectY = Double(intersectedRect.origin.y)
		let baseSizeWidth = Double(baseRect.size.width)
		let baseSizeHeight = Double(baseRect.size.height)
		let rectSizeWidth = Double(intersectedRect.size.width)
		let rectSizeHeight = Double(intersectedRect.size.height)
//        Log.debug("rectSizeHeight\(rectSizeHeight) baseSizeHeight \(baseSizeHeight)")
				
		if rectX.isInfinite || rectX == 0.0 || rectY.isInfinite || rectY == 0.0 || rectSizeWidth < baseSizeWidth || rectSizeHeight < baseSizeHeight {
			//view is partially out of bounds
			log.debug("view is partially out of bounds")
			
			var rect = baseRect
			
			if rectX == 0.0 && rectSizeWidth < baseSizeWidth {
				rect.origin.x = 0.1
			}
			if rectY == 0.0 && rectSizeHeight < baseSizeHeight {
				rect.origin.y = 0.1
			}
			if rectSizeWidth < baseSizeWidth && rectX > 0.0 {
				rect.origin.x -= ((CGFloat(baseSizeWidth) - CGFloat(rectSizeWidth)) + 1)
			}
			if rectSizeHeight < baseSizeHeight && rectY > 0.0 {
				rect.origin.y -= ((CGFloat(baseSizeHeight) - CGFloat(rectSizeHeight)) + 1)
			}
			
            
			tagBaseView.frame = rect
			
			if rectX.isInfinite || rectY.isInfinite {
				log.debug("view is fully out of bounds")
				tagBaseView.center = self.center
			}
			
		}
		
		lastCenterPoint = tagBaseView.center
		
	}
	
	
    // MARK: - Hit Test
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		
		if mode == .view {
			return nil
		}
		
		if let hitView = super.hitTest(point, with: event) as UIView? {

			if hitView == self {
				return nil
			}
			
			if String(describing: hitView.classForCoder) == "UIButton" {
				hitView.superview?.superview?.bringSubview(toFront: self)
                
			}
			
			return hitView
			
		}
		
		return nil
		
	}
	
	
	
    func rotateView() -> Void {
        
    }
	
	// MARK: - Handle Long Press Gesture
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) -> Void {
		// disable long press on profile view mode
		guard self.mode == .edit else {
			return
		}
		
		if gesture.state == UIGestureRecognizerState.began {
			
			self.superview?.bringSubview(toFront: self)
			self.mode = .edit
			if self.mode == .edit {
				presentDeleteActionSheet()
			}
		}
    }
	
    
    func presentDeleteActionSheet(){
        self.tagDelegate?.didSelectedCloseButton?(self)
    }
    
	// MARK: - Handle Single Tap Gesture
	@objc func singleTap(_ gesture: UITapGestureRecognizer) -> Void {
		
		if gesture.state == UIGestureRecognizerState.ended {
			
			self.superview?.bringSubview(toFront: self)
			if mode == .special {
				// Tag are showing in newsfeed post, single tap will open this Tag's product details page
				self.tagDelegate?.updateTag?(self)
                
                //record action
                self.recordAction(.Tap, sourceRef: self.styleCode, sourceType: .Product, targetRef: "PDP", targetType: .View)
            }
		}
		
	}
	
	// MARK: - Handle Double Tap Gesture
	@objc func doubleTap(_ gesture: UITapGestureRecognizer) -> Void {
		
		if gesture.state == UIGestureRecognizerState.ended {
			
			self.superview?.bringSubview(toFront: self)
			
			switch mode {
			case .normal, .view, .edit:
				// disbled broadcast for disable edit mode
				//NotificationCenter.default.post(name: Constants.Notification.ExitTagProductEditMode, object: nil)
				
				if direction == .left {
					
					direction = .right
					
				} else {
					direction = .left
					
				}
				self.layoutSubviews()
				
				// update tag
				self.tagDelegate?.updateTag?(self)
				
				break
			default:
				break
			}
			
		}
		
	}
	
		
	//MARK: - TagEditor Delegate
	func handleTapClose(_ gesture: UITapGestureRecognizer) -> Void {
        if self.mode == .edit {
            Log.debug("view tag : \(String(describing: gesture.view?.tag))")
            self.tagDelegate?.didSelectedCloseButton!(self)
        }
    }
    
	
    func fillPriceByCartItem(_ sku: Sku) {
        self.price = sku.price()
        self.tagTitleLabel.text = sku.brandName
    }

    func startAnimation() -> Void {
		
		DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
			DispatchQueue.main.async(execute: {

				self.alpha = 0.0
				UIView.animate(withDuration: 0.5, animations: {
					self.alpha = 1.0
				}) 
			})
		}
    }
    
    func stopAnimation() {
        self.pinView.stopAnimation()
    }
    
   @objc  func toucheDown() {
        self.tagDelegate?.touchDown?(self)
    }
    
    @objc func toucheUp() {
        if !self.isPanning {
            self.tagDelegate?.touchUp?(self)
        }
    }
   
}
