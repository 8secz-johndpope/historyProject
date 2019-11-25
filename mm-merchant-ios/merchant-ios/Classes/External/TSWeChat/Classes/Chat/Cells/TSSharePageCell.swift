//
//  TSSharePageCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 14/06/2016.
//  Copyright © 2016 Sang Nguyen. All rights reserved.
//

import Foundation
import ObjectMapper

import PromiseKit

class TSSharePageCell: TSChatBaseCell {
    
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var remark: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var warningImage: UIImageView!
    
    var targetUser: User?
    var me: User?
    var cornerRadiusForMagazinImage = CGSize(width: 7.0, height: 7.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        name.formatSmall()
        remark.formatSmall()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TSSharePageCell.cellDidPressLong))
        viewContent.addGestureRecognizer(longPress)
        viewContent.isUserInteractionEnabled = true
        let tap = TapGestureRecognizer()
        self.viewContent.addGestureRecognizer(tap)
        self.viewContent.isUserInteractionEnabled = true
        tap.tapHandler = { [weak self] _ in
            if let strongSelf = self {
                guard let delegate = strongSelf.delegate, let cellDidTapped = delegate.cellDidTaped else {
                    return
                }
                cellDidTapped(strongSelf)
            }
        }
        
        //set magazine image content type if scale aspect fill, so need to mask bound to clear redundancy
        postImage.layer.masksToBounds = true
    }
    
    @objc func cellDidPressLong(_ gesture: UIGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.began {
            if let delegate = self.delegate {
                delegate.cellDidPressLong(self)
            }
        }
    }
    
    override func setCellContent(_ model: ChatModel) {
        super.setCellContent(model)
        if let magazineCover = (model.model as? MagazineCoverModel)?.magazineCover {
            fillContentWithMagazine(magazineCover, model: model)
        } else if let shareContentPageKey = model.shareContentPageKey {
            MagazineService.viewContentPage(shareContentPageKey, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        if let magazineCover = Mapper<MagazineCover>().map(JSONObject: response.result.value) {
                            let magazineCoverModel = MagazineCoverModel()
                            magazineCoverModel.magazineCover = magazineCover
                            model.model = magazineCoverModel
                            strongSelf.fillContentWithMagazine(magazineCover, model: model)
                        } else  {
                            strongSelf.fillContentWithMagazine(nil, model: model)
                        }
                    } else {
                        strongSelf.fillContentWithMagazine(nil, model: model)
                    }
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
            })
        }
        self.setNeedsLayout()
    }
    
    func fillContentWithMagazine(_ magazineCover: MagazineCover?, model: ChatModel?) {
        
        showWarning(false)
        
        if let myMagazineCover = magazineCover, let myModel = model {
            postImage.ts_setImageWithURLString(ImageURLFactory.URLSize750(myMagazineCover.coverImage, category: .contentPageImages).absoluteString)
            name.text = myMagazineCover.contentPageName
            if myModel.fromMe {
                remark.text = (me?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_OUTFIT_REMARK")
            }
            else {
                remark.text = (targetUser?.displayName ?? "") + String.localize("LB_CA_IM_SHARE_OUTFIT_REMARK")
            }
        } else {
            showWarning(true)
        }
    }
    
    func showWarning(_ isShowing: Bool) {
        
        warningImage.isHidden = !isShowing
        
        postImage.image = nil
        name.text = nil
        
        if isShowing {
            name.text = String.localize("MSG_ERR_IM_DELETE_POST")
            postImage.backgroundColor = UIColor.primary2()
            warningImage.center = postImage.center
        } else {
            postImage.backgroundColor = UIColor.white
        }
    }
    
    class func layoutHeight(_ model: ChatModel) -> CGFloat {
        return 112.5 + kChatAvatarMarginTop + kChatBubblePaddingBottom
    }
    
    override func layoutContents() {
        super.layoutContents()
        guard let model = self.model else {
            return
        }
        if model.fromMe {
            self.viewContent.left = ScreenWidth - kChatAvatarMarginLeft - kChatAvatarWidth - kChatBubbleMaginLeft - self.viewContent.width
            backgroundImage.image = UIImage(named: "shareUser_pink")
            
            //make corner radius at top left of magazine image
            let path = UIBezierPath(roundedRect:postImage.bounds, byRoundingCorners:[.topLeft], cornerRadii: cornerRadiusForMagazinImage)
            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            postImage.layer.mask = maskLayer
        } else {
            self.viewContent.left = kChatBubbleLeft
            backgroundImage.image = UIImage(named: "shareUser_wht")
            postImage.layer.mask = nil
        }
        self.viewContent.top = self.avatarImageView.top
    }
}
