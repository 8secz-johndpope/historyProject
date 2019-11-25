//
//  CuratorCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 01/06/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
import Alamofire

import UIKit.UIGestureRecognizerSubclass



class PanDirectionGestureRecognizer: UIPanGestureRecognizer {
    
    enum PanDirection {
        case vertical
        case horizontal
    }
    
    let direction : PanDirection
    
    init(direction: PanDirection, target: Any, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        if state == .began {
            let velocity = self.velocity(in: self.view!)
            switch direction {
            case .horizontal where fabs(velocity.y) > fabs(velocity.x):
                state = .cancelled
            case .vertical where fabs(velocity.x) > fabs(velocity.y):
                state = .cancelled
            default:
                break
            }
        }
    }
}

protocol CuratorImageViewDelegate: NSObjectProtocol {
    func didSelectFollowUser(_ curator: Curator, isFollowing: Bool, sender: UIButton)
}
class CuratorImageView: UIImageView {
    
    weak var delegate: CuratorImageViewDelegate?
    var data: Curator? {
        didSet {
            if let curatorItem = self.data {
                nameLabel.text = curatorItem.displayName
                followersLabel.text = String(format: "%@ %@",String.localize("LB_CA_FOLLOWER"), NumberHelper.getNumberMeasurementString(curatorItem.followerCount))
                
                self.updateFollowButton()
                var url = curatorItem.profileImage
                if let squareImageURL = curatorItem.profileAlternateImage {
                    url = squareImageURL
                }
                
                if url.length > 0{
                    self.mm_setImageWithURL(ImageURLFactory.URLSize1000(url, category: .user), placeholderImage: UIImage(named: "curator_cover_image_placeholder"), clipsToBounds: true, contentMode: .scaleAspectFill)
                }else {
                    self.image = UIImage(named: "curator_cover_image_placeholder")
                }
                
                self.layoutSubviews()
            }
        }
    }
    
    private var followButton = ButtonFollow()
    private var followersLabel = UILabel()
    private var nameLabel = UILabel()
    private var overlayImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(followButton)
        self.addSubview(followersLabel)
        self.addSubview(nameLabel)
        followButton.addTarget(self, action: #selector(CuratorImageView.didSelectFollowButton), for: UIControlEvents.touchUpInside)
        self.isUserInteractionEnabled = true
        self.addSubview(overlayImageView)
        
        self.backgroundColor = UIColor.primary2()
        self.contentMode = .center
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var paddingBottom = CGFloat(10)
        let buttonWidth = CGFloat(120)
        var buttonHeight = CGFloat(30)
        let labelHeight = CGFloat(20)
        
        if let curator = self.data {
            if curator.userKey == Context.getUserKey() {
                buttonHeight = 0
                paddingBottom = 22
            }
        }
        
        followButton.frame = CGRect(x: (self.bounds.sizeWidth - ButtonFollow.ButtonFollowSize.width)/2, y: self.bounds.maxY - paddingBottom - buttonHeight, width: ButtonFollow.ButtonFollowSize.width, height: ButtonFollow.ButtonFollowSize.height)
        self.bringSubview(toFront: followButton)
		
        followersLabel.frame = CGRect(x: (self.bounds.sizeWidth - buttonWidth)/2, y: self.followButton.frame.minY - 8 - labelHeight, width: buttonWidth, height: labelHeight)
        followersLabel.textAlignment = .center
        followersLabel.formatSmall()
        followersLabel.textColor = UIColor.white
        
        let width = self.size.width - 2 * Margin.left
        nameLabel.frame = CGRect(x: (self.bounds.sizeWidth - width)/2, y: followersLabel.frame.minY - 8 - labelHeight, width: width, height: labelHeight)
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.usernameFont()
        
        nameLabel.textColor = UIColor.white
        
        let imageOverlayHeight = CGFloat(120)
        overlayImageView.frame = CGRect(x: 0, y: self.frame.sizeHeight - imageOverlayHeight, width: self.frame.sizeWidth, height: imageOverlayHeight)
        overlayImageView.image = UIImage(named: "curator_overlay")
        self.sendSubview(toBack: overlayImageView)

    }
    
    //MARK:- Follow Methods
    @objc func didSelectFollowButton(_ sender: UIButton) -> Void {
		
		if LoginManager.getLoginState() == .guestUser {
			NotificationCenter.default.post(name: Constants.Notification.followCuratorWithGuestUser, object: nil)
			return
		}
		
        if let data = self.data {
            delegate?.didSelectFollowUser(data, isFollowing: data.isFollowing, sender: sender)
            
            //record action
            let sourceRef = data.isFollowing == true ? "UnFollow":"Follow"
            sender.recordAction(.Tap, sourceRef: sourceRef, sourceType: .Button, targetRef: Context.getUserKey(), targetType: .Curator)
        }
    }
    
    func updateFollowButton() {
        if let curatorItem = self.data {
            followButton.updateFollowButtonState(curatorItem.isFollowing)
            followButton.isHidden = curatorItem.userKey == Context.getUserKey() ? true : false
            if curatorItem.isLoading {
                followButton.showLoading(UIColor.clear)
            }else {
                followButton.hideLoading()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.layer.cornerRadius = 8
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.clipsToBounds = true
        self.layer.borderWidth = 0.5
    }
}



protocol CuratorCellDelegate: NSObjectProtocol {
    func curatorCellDidTapOnCuratorImageProfile(_ item: Curator)
    func curatorCellDidAnimateToCuratorProfile(_ item: Curator)
    func curatorCellDidSelectSeeAllCuratorButton()
    func showLoading()
    func stopLoading()
    func curatorCellHandleApiResponseError(_ apiResponse: ApiResponse, errorCode: Int)
    func showFollowSuccessPopUp()
}

class CuratorCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate, CuratorImageViewDelegate {
    
    enum Direction: Int {
        case leftToRight = 1,
        rightToLeft,
        unknown
    }
    static let CellId = "CuratorCellId"
    
    private var backgroundImageView = UIImageView()
    private var overlayView = UIView()
    private var firstImageView = CuratorImageView()
    private var secondImageView = CuratorImageView()
    private var thirdImageView = CuratorImageView()
    private var outsideImageView = CuratorImageView()
    
    private var direction = Direction.unknown
    private var imageWidth = CGFloat(240)
    private var imageHeight = CGFloat(240)
    private var ratioHeight = CGFloat(1.0/1.0)
    private var outsideFrameOriginX = CGFloat(-300)
    
    private var startPoint = CGPoint.zero
    private var limitationX = CGFloat(0)
    
    private var centerFrame = CGRect.zero
    private var centerViewPaddingTop = CGFloat(-10)
    private var secondFrame = CGRect.zero
    private var thirdFrame = CGRect.zero
    private var outsideFrame = CGRect.zero
    
    private var duration = TimeInterval(0.1)
    private var isMoving = false
    private var completed = true
    private var tapGesture : UITapGestureRecognizer?
    static let MinimumCurator = 1
    
    weak var delegate: CuratorCellDelegate?
    
    var curatorDatasources = [Curator]() {
        didSet {
            updateImageViewFromStack()
            self.isUserInteractionEnabled = isDatasourceAvailable()
        }
    }
    
    func updateCurrentCurator(_ currentCurator : Curator?) -> Void {
        if let curator = currentCurator {
            if let currentIndex = curatorDatasources.index(where: {$0.userKey == curator.userKey}){
                if currentIndex < curatorDatasources.count && currentIndex > 0 {
                    var array: [Curator] = [Curator]()
                    array.append(contentsOf: curatorDatasources)
                    for _ in  0..<currentIndex {
                        let temp = curatorDatasources[0]
                        curatorDatasources.remove(at: 0)
                        curatorDatasources.append(temp)
                    }
                }
            }
        }
    }
    
    private func isDatasourceAvailable() -> Bool {
        return curatorDatasources.count >= CuratorCollectionViewCell.MinimumCurator
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundImageView.frame = self.bounds
        contentView.addSubview(backgroundImageView)
        
        overlayView.frame = self.bounds
        overlayView.backgroundColor = UIColor.black
        overlayView.alpha = 0.3
        contentView.insertSubview(overlayView, aboveSubview: backgroundImageView)
        
        imageWidth = imageWidth * self.frame.sizeWidth / 375
        imageHeight = imageWidth * ratioHeight
        outsideFrameOriginX = imageWidth * -1
        
        let offsetForSecondFrame = CGFloat(20)
        let offsetForThirdFrame = CGFloat(40)
        
        centerFrame = CGRect(x: (self.width - imageWidth) / 2, y: (self.height - imageHeight) / 2 + centerViewPaddingTop, width: imageWidth, height: imageHeight)
        secondFrame = CGRect(x: centerFrame.origin.x + offsetForSecondFrame / 2, y: centerFrame.origin.y - offsetForSecondFrame/2, width: centerFrame.size.width - offsetForSecondFrame, height: centerFrame.height - offsetForSecondFrame)
        thirdFrame = CGRect(x: centerFrame.origin.x + offsetForThirdFrame / 2, y: centerFrame.origin.y - offsetForThirdFrame/2, width: centerFrame.size.width - offsetForThirdFrame, height: centerFrame.height - offsetForThirdFrame)
        outsideFrame = CGRect(x: outsideFrameOriginX, y: (self.height - imageHeight) / 2 + centerViewPaddingTop, width: imageWidth, height: imageHeight)
        
        secondImageView.frame = secondFrame
        contentView.addSubview(secondImageView)
        
        firstImageView.frame = centerFrame
        contentView.addSubview(firstImageView)
        
        outsideImageView.frame = outsideFrame
        contentView.addSubview(outsideImageView)
        
        thirdImageView.frame = thirdFrame
        
        contentView.addSubview(thirdImageView)
        contentView.sendSubview(toBack: thirdImageView)
        
//        contentView.sendSubviewToBack(blurredEffectView)
        contentView.sendSubview(toBack: backgroundImageView)
        
        let panGesture = PanDirectionGestureRecognizer(direction:.horizontal, target: self, action:#selector(CuratorCollectionViewCell.handlePanGesture))
        contentView.addGestureRecognizer(panGesture)
        
        limitationX = self.contentView.frame.size.width / 4
        
        self.addTopAndBottomView()
        
    }
    
    func addTopAndBottomView() {
//        let label = UILabel()
//        label.frame = CGRect(x:(self.contentView.frame.sizeWidth - thirdFrame.sizeWidth) / 2, y: thirdFrame.originY - 15 - 20, width: thirdFrame.sizeWidth, height: 20)
//        label.text = String.localize("LB_CA_CURATOR_RECOMM")
//        label.textAlignment = .center
//        label.formatSmall()
//        label.textColor = UIColor.white
//        self.contentView.addSubview(label)
        
        let button = UIButton(type: .custom)
        let buttonWidth = CGFloat(114)
        let buttonHeight = CGFloat(38)
        
        button.frame = CGRect(x: centerFrame.midX - buttonWidth / 2  , y: centerFrame.maxY + 18, width: buttonWidth, height: buttonHeight)
        button.backgroundColor = UIColor.whiteColorWithAlpha(0.2)
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 2
        button.layer.borderColor = UIColor.secondary1().cgColor
        
        button.setTitle(String(format: "%@",String.localize("LB_CA_CURATOR_ALL")), for: UIControlState())
        button.titleLabel?.applyFontSize(14, isBold: false)
        button.addTarget(self, action: #selector(CuratorCollectionViewCell.didSelectSeeAllCuratorButton), for: UIControlEvents.touchUpInside)
        
        contentView.addSubview(button)
        
        let rightIcon = UIImageView()
        rightIcon.image = UIImage(named: "right_image_white")
        let size = CGSize(width: 6, height: 10)
        rightIcon.frame = CGRect(x: buttonWidth - size.width - 8, y: (buttonHeight - size.height)/2, width: size.width, height: size.height)
        button.addSubview(rightIcon)
        
    }
    
    @objc func didSelectSeeAllCuratorButton(_ sender: UIButton){
        delegate?.curatorCellDidSelectSeeAllCuratorButton()
        
        //record action
        sender.recordAction(.Tap, sourceRef: "AllCurators", sourceType: .Button, targetRef: "AllCurators", targetType: .View)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        

        if !isDatasourceAvailable() || (!completed && panGesture.state != .ended || self.curatorDatasources.count == 1) {
            return
        }
        
        let translation = panGesture.translation(in: self.contentView)
        let tx = translation.x;
        let ty = translation.y
        
        var point = CGPoint(x:panGesture.view!.center.x + tx, y:panGesture.view!.center.y + ty)
        
        switch panGesture.state {
        case .began:
            if !isMoving {
                startPoint = point
                outsideImageView.frame = outsideFrame
                firstImageView.frame = centerFrame
                secondImageView.frame = secondFrame
                isMoving = true
            }else { // the current animation isn't completed
                startPoint = CGPoint.zero
                completed = false
            }
        case .changed:
            
            let offsetX = point.x - startPoint.x
            if point.x > startPoint.x  && direction != .rightToLeft {
                direction = .leftToRight
                point.y = centerFrame.origin.y
                outsideImageView.frame.origin.x = outsideFrameOriginX + offsetX
                
                let rect = outsideImageView.frame
                if rect.origin.x + rect.size.width > 0 {
                    let totalDistance = centerFrame.origin.x
                    let ratio = (rect.origin.x + rect.size.width) / totalDistance
                    var rect2 = centerFrame
                    rect2.size.height -= (5*ratio)
                    rect2.size.width -= (5*ratio)
                    if rect2.size.width < secondFrame.size.width {
                        rect2.size.width = secondFrame.size.width
                    }
                    if rect2.size.height < secondFrame.size.height {
                        rect2.size.height = secondFrame.size.height
                    }
                    var detlaX = centerFrame.size.width - rect2.size.width
                    rect2.origin.x += detlaX / 2
                    if rect2.origin.x > secondFrame.origin.x {
                        rect2.origin.x = secondFrame.origin.x
                    }
                    
                    var detlaY = centerFrame.size.height - rect2.size.height
                    rect2.origin.y -= detlaY / 2
                    if rect2.origin.y < secondFrame.origin.y {
                        rect2.origin.y = secondFrame.origin.y
                    }
                    self.firstImageView.frame = rect2
                    
                    
                    var rect3 = secondFrame
                    rect3.size.height -= (5*ratio)
                    rect3.size.width -= (5*ratio)
                    if rect3.size.width < thirdFrame.size.width {
                        rect3.size.width = thirdFrame.size.width
                    }
                    if rect3.size.height < thirdFrame.size.height {
                        rect3.size.height = thirdFrame.size.height
                    }
                    detlaX = secondFrame.size.width - rect3.size.width
                    rect3.origin.x += detlaX / 2
                    
                    detlaY = secondFrame.size.height - rect3.size.height
                    rect3.origin.y -= detlaY / 2
                    
                    if rect3.origin.x > thirdFrame.origin.x {
                        rect3.origin.x = thirdFrame.origin.x
                    }
                    if rect3.origin.y < thirdFrame.origin.y {
                        rect3.origin.y = thirdFrame.origin.y
                    }
                    secondImageView.frame = rect3
                }
                
            }else if direction != .leftToRight {
                direction = .rightToLeft
                
                var rect = centerFrame
                rect.origin.x += offsetX
                firstImageView.frame = rect
                
                if firstImageView.frame.maxX > centerFrame.maxX {
                    firstImageView.frame.origin.x = centerFrame.origin.x
                }
                
                let totalDistance = centerFrame.origin.x
                let ratio = (totalDistance - firstImageView.frame.origin.x) / totalDistance
                var rect2 = secondFrame
                rect2.size.height += (5*ratio)
                rect2.size.width += (5*ratio)
                if rect2.size.width > centerFrame.size.width {
                    rect2.size.width = centerFrame.size.width
                }
                if rect2.size.height > centerFrame.size.height {
                    rect2.size.height = centerFrame.size.height
                }
                var detlaX = rect2.size.width - secondFrame.size.width
                rect2.origin.x -= detlaX / 2
                
                var detlaY = rect2.size.height - secondFrame.size.height
                rect2.origin.y += detlaY / 2
                
                if rect2.origin.x < centerFrame.origin.x {
                    rect2.origin.x = centerFrame.origin.x
                }
                if rect2.origin.y > centerFrame.origin.y {
                    rect2.origin.y = centerFrame.origin.y
                }
                secondImageView.frame = rect2
                
                var rect3 = thirdFrame
                rect3.size.height += (5*ratio)
                rect3.size.width += (5*ratio)
                if rect3.size.width > secondFrame.size.width {
                    rect3.size.width = secondFrame.size.width
                }
                if rect3.size.height > secondFrame.size.height {
                    rect3.size.height = secondFrame.size.height
                }
                detlaX = rect3.size.width - thirdFrame.size.width
                rect3.origin.x -= detlaX / 2
                
                detlaY = rect3.size.height - thirdFrame.size.height
                rect3.origin.y += detlaY / 2
                
                if rect3.origin.x < secondFrame.origin.x {
                    rect3.origin.x = secondFrame.origin.x
                }
                if rect3.origin.y > secondFrame.origin.y {
                    rect3.origin.y = secondFrame.origin.y
                }
                thirdImageView.frame = rect3
                
            }
        case .ended:
            if direction == .leftToRight {
                if outsideImageView.frame.origin.x + outsideImageView.frame.size.width > limitationX {
                    
                    UIView.animate(withDuration: duration, animations: { () -> Void in
                        self.outsideImageView.frame = self.centerFrame
                        self.firstImageView.frame = self.secondFrame
                        self.secondImageView.frame = self.thirdFrame
                        }, completion: { (completion: Bool) -> Void in
                            if completion {
                                self.reset(completion: true)
                            }
                    })
                }else {
                    
                    UIView.animate(withDuration: duration, animations: { () -> Void in
                        self.outsideImageView.frame = self.outsideFrame
                        self.firstImageView.frame = self.centerFrame
                        self.secondImageView.frame = self.secondFrame
                        self.reset(completion: false)
                    })
                }
            }else {
                if firstImageView.frame.origin.x < 0 {
                    
                    UIView.animate(withDuration: duration, animations: { () -> Void in
                        self.firstImageView.frame = self.outsideFrame
                        self.secondImageView.frame = self.centerFrame
                        self.thirdImageView.frame = self.secondFrame
                        }, completion: { (completion: Bool) -> Void in
                            if completion {
                                self.reset(completion: true)
                            }
                    })
                    
                }else {
                    
                    UIView.animate(withDuration: duration, animations: { () -> Void in
                        self.firstImageView.frame = self.centerFrame
                        self.secondImageView.frame = self.secondFrame
                        self.reset(completion: false)
                    })
                    
                }
            }
            
        default:
            break
        }
    }
    
    @objc func handleTapGesture(_ tapGesture: UIPanGestureRecognizer) -> Void {
        
        let curator = curatorDatasources[0]
        if isDatasourceAvailable() {
            delegate?.curatorCellDidTapOnCuratorImageProfile(curator)
        }
        
        //record action
        tapGesture.view?.recordAction(.Tap, sourceRef: "\(curator.userKey)", sourceType: .Curator, targetRef: "CPP", targetType: .View)
    }
    
    func remakeDatasources() {
        if isDatasourceAvailable() {
            if direction == .leftToRight {
                let tempIndex = (curatorDatasources.count - 1) >= 0 ? (curatorDatasources.count - 1) : 0
                let temp = curatorDatasources[tempIndex]
                curatorDatasources.remove(at: tempIndex)
                curatorDatasources.insert(temp, at: 0)
            }else {
                let temp = curatorDatasources[0]
                curatorDatasources.remove(at: 0)
                curatorDatasources.append(temp)
            }
        }
    }
    
    func reset(completion: Bool) {
        isMoving = false
        completed = true
        if completion
        {
            self.outsideImageView.isHidden = true
            self.remakeDatasources()
            self.updateImageViewFromStack()
            if direction == .leftToRight {
                
                outsideImageView.frame = outsideFrame
                firstImageView.frame = centerFrame
                secondImageView.frame = secondFrame
                thirdImageView.frame = thirdFrame
                
            }else {
                
                outsideImageView.frame = outsideFrame
                firstImageView.frame = centerFrame
                secondImageView.frame = secondFrame
                thirdImageView.frame = thirdFrame
                
            }
            outsideImageView.isHidden = false
            delegate?.curatorCellDidAnimateToCuratorProfile(curatorDatasources[0])
            
        }
        direction = .unknown
    }
    
    func updateImageViewFromStack() {
        
        let placeHolderImage = UIImage(named: "tile_placeholder")
        if isDatasourceAvailable() {
            firstImageView.data = curatorDatasources[0]
            if curatorDatasources.count > 1 {
                secondImageView.data = curatorDatasources[1]
                secondImageView.isHidden = false
            }else {
                secondImageView.isHidden = true
            }
            if curatorDatasources.count > 2 {
                thirdImageView.data = curatorDatasources[2]
                thirdImageView.isHidden = false
            }else {
                thirdImageView.isHidden = true
            }
            
			let outsideImageIndex = (curatorDatasources.count - 1) >= 0 ? (curatorDatasources.count - 1) : 0
            outsideImageView.data = curatorDatasources[outsideImageIndex]
            
            let data = curatorDatasources[0]
            var url = data.profileImage
            if let squareImageURL = data.profileAlternateImage {
                url = squareImageURL
            }
            backgroundImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(url, category: .user), placeholderImage: nil, clipsToBounds: true, contentMode: .scaleAspectFill, progress: nil, optionsInfo: nil, completion: { (image : UIImage?, error, cacheType, imageURL) in
                if let imageDownloaded = image {
                    self.backgroundImageView.image = imageDownloaded.blurredImage(withRadius: CGFloat(20), iterations: 1, tintColor: UIColor.clear, useBitmapInfo: false)
                }
            })
            if let gesture = self.tapGesture {
                firstImageView.removeGestureRecognizer(gesture)
            }
            tapGesture = UITapGestureRecognizer(target: self, action:#selector(CuratorCollectionViewCell.handleTapGesture))
            firstImageView.addGestureRecognizer(tapGesture!)
            firstImageView.delegate = self
            
        }else {
            firstImageView.image = placeHolderImage
            secondImageView.image = placeHolderImage
            thirdImageView.image = placeHolderImage
            backgroundImageView.image = nil
        }
    }
    
    //MARK: - ImageView Delegate
    func didSelectFollowUser(_ curator: Curator, isFollowing: Bool, sender: UIButton) {
        
        if isFollowing {
            if let controllerDelegate = self.delegate as? MmViewController{
                let message = String.localize("LB_CA_UNFOLLOW_CONF").replacingOccurrences(of: "{0}", with: curator.displayName)
                Alert.alert(controllerDelegate, title: "", message: message, okActionComplete: { () -> Void in
                    if let followButton = sender as? ButtonFollow {
                        followButton.showLoading(UIColor.clear)
                        curator.isLoading = true
                    }
                    firstly {
                        return FollowService.requestUnfollow(curator.userKey)
                        }.then { _ -> Void in
                            self.stopLoadingOnFollowButton(curator, isFollowing: isFollowing, sender: sender)
                            curator.isFollowing = false
                            curator.followerCount -= 1
                            self.updateImageViewFromStack()
                        }.catch { error -> Void in
                            Log.error("error")
                            let error = error as NSError
                            if let apiResp = error.userInfo["data"] as? ApiResponse {
                                self.delegate?.curatorCellHandleApiResponseError(apiResp, errorCode: error.code)
                            }
                            self.stopLoadingOnFollowButton(curator, isFollowing: isFollowing, sender: sender)
                            self.updateImageViewFromStack()
                    }
                    }, cancelActionComplete:nil)
            }
        }else {
            if let followButton = sender as? ButtonFollow {
                followButton.showLoading(UIColor.clear)
                curator.isLoading = true
            }
            firstly {
                return FollowService.requestFollow(curator.userKey)
                }.then { _ -> Void in
                    self.stopLoadingOnFollowButton(curator, isFollowing: isFollowing, sender: sender)
                    curator.isFollowing = true
                    curator.followerCount += 1
                    self.updateImageViewFromStack()
                }.catch { error -> Void in
                    Log.error("error")
                    let error = error as NSError
                    if let apiResp = error.userInfo["data"] as? ApiResponse {
                        self.delegate?.curatorCellHandleApiResponseError(apiResp, errorCode: error.code)
                    }
                    self.stopLoadingOnFollowButton(curator, isFollowing: isFollowing, sender: sender)
                    self.updateImageViewFromStack()
            }
        }
    }
    
    func stopLoadingOnFollowButton(_ curator: Curator, isFollowing: Bool, sender: UIButton) {
        if let followButton = sender as? ButtonFollow {
            followButton.hideLoading()
            curator.isLoading = false
        }
    }
    
    
}
