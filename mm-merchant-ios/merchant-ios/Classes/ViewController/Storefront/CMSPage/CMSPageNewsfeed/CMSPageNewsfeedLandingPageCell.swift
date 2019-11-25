//
//  CMSPageNewsfeedLandingPageCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/28.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit
import YYText
import PromiseKit

class CMSPageNewsfeedLandingPageCell: CMSPageNewsfeedCell, FlyNotice {
    
    public var page: MagazineCover?
    
    lazy var contentImageView:UIImageView = {
        let contentImageView = UIImageView()
        contentImageView.backgroundColor = UIColor.white
        return contentImageView
    }()
    
    lazy var testLabel:UILabel = {
        let testLabel = UILabel()
        testLabel.font = UIFont.systemFont(ofSize: 13)
        testLabel.textColor = UIColor.white
        testLabel.numberOfLines = 0
        testLabel.isHidden = true
        return testLabel
    }()
    
    lazy var contentLabel:UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 12)
        contentLabel.numberOfLines = 2
        return contentLabel
    }()
    
    lazy var statusImageView:UIImageView = {
        let statusImageView = UIImageView()
        statusImageView.image = UIImage(named: "multi_icon")
        statusImageView.sizeToFit()
        statusImageView.isHidden = true
        return statusImageView
    }()
    
    lazy var likeButton:UIButton = {
        let likeButton = UIButton()
        let normalImage = UIImage(named: "grey_heart")
        normalImage?.track_consoleTitle = "喜欢"
        likeButton.setImage(normalImage, for: .normal)
        let selectedImage = UIImage(named: "red_heart")
        selectedImage?.track_consoleTitle = "取消喜欢"
        likeButton.setImage(selectedImage, for: .selected)
        likeButton.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: 12)
        likeButton.titleLabel?.textAlignment = .right
        likeButton.addTarget(self, action: #selector(self.tapAction), for: .touchDown)
        likeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        likeButton.setTitleColor(UIColor.secondary3(), for: .normal)
        likeButton.sizeToFit()
        return likeButton
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundImageView.addSubview(contentImageView)
        backgroundImageView.addSubview(contentLabel)
        backgroundImageView.addSubview(likeButton)
        backgroundImageView.addSubview(testLabel)
        backgroundImageView.addSubview(statusImageView)
        
        contentImageView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backgroundImageView)
            make.width.bottom.equalTo(backgroundImageView)
            make.height.equalTo(backgroundImageView.snp.width)
        }
        likeButton.snp.makeConstraints({ (make) in
            make.bottom.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
            make.right.equalTo(backgroundImageView).offset(-10)
        })
        contentLabel.snp.makeConstraints({ (make) in
            make.bottom.equalTo(likeButton.snp.top).offset(-MMMargin.CMS.imageToTitle)
            make.width.equalTo(backgroundImageView).offset(-20)
            make.centerX.equalTo(backgroundImageView)
        })
        testLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(contentImageView)
        }
        statusImageView.snp.makeConstraints { (make) in
            make.top.equalTo(backgroundImageView).offset(MMMargin.CMS.defultMargin)
            make.right.equalTo(backgroundImageView).offset(-MMMargin.CMS.defultMargin)
        }
    }
    
    @objc  func tapAction()  {
        guard (LoginManager.getLoginState() == .validUser) else {
            LoginManager.goToLogin()
            return
        }
        if let page = page{
            if self.likeButton.isSelected{
                if page.likeCount > 0{
                    self.likeButton.isUserInteractionEnabled = false
                    page.likeCount = page.likeCount - 1
                    actionLike(0, pageModel: page, completion: {
                        self.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(page.likeCount), for: .normal)
                        self.likeButton.isSelected = false
                        self.likeButton.isUserInteractionEnabled = true
                    }) {
                        self.likeButton.isUserInteractionEnabled = true
                        Log.debug("Error")
                    }
                }
            }else{
                self.likeButton.isUserInteractionEnabled = false
                page.likeCount = page.likeCount + 1
                actionLike(1, pageModel: page, completion: {
                    self.likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(page.likeCount), for: .normal)
                    self.likeButton.isSelected = true
                    self.likeButton.isUserInteractionEnabled = true
                }) {
                    self.likeButton.isUserInteractionEnabled = true
                    Log.debug("Error")
                }
            }
        }
    }
    
    /**
     action like on content page
     
     - parameter isLike:     1: 0
     - parameter contentKey: contetn page key
     
     - returns: Promize
     */
    @discardableResult
    func actionLike(_ isLike: Int, pageModel: MagazineCover, completion: (()->())?,  fail: (()->())? ) -> Promise<Any>{
        
        return Promise{ fulfill, reject in
            
            MagazineService.actionLikeMagazine(isLike, contentPageKey: pageModel.contentPageKey, completion: { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        
                        if let result = response.result.value as? [String: Any], (result["Success"] as? Int) == 1{
                            Log.debug("likePostCall OK" + pageModel.contentPageKey)
                            
                            let pageLike = Fly.PageHotData()
                            pageLike.pageKey = pageModel.contentPageKey
                            pageLike.isLike = isLike == 1
                            Fly.page.save(pageLike)
                            
                            //以下代码将废弃，使用Fly.page管理即可
                            if isLike == 1 {
                                CacheManager.sharedManager.addLikedMagazieCover(pageModel)
                            } else{
                                CacheManager.sharedManager.removeLikedMagazieCover(pageModel)
                            }
                            
                            fulfill(pageModel.contentPageKey)
                            if let callback = completion {
                                callback()
                            }
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                        
                        if let callback = fail {
                            callback()
                        }
                    }
                } else {
                    reject(response.result.error!)
                    
                    if let callback = fail {
                        callback()
                    }
                }
                
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Fly.page.unbind(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        page = nil
        Fly.page.unbind(self)

        self.contentImageView.image = nil
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
       let cellModel: CMSPageNewsfeedLandingPageCellModel = model as! CMSPageNewsfeedLandingPageCellModel
       testLabel.text = cellModel.title
        
        if let dataModel = cellModel.data{
            page = dataModel.page
            
            //埋点需要
            self.track_visitId = dataModel.vid
            self.track_media = dataModel.videoUrl
            
            setImageView(dataModel: dataModel, imageView: contentImageView)

            backgroundImageView.whenTapped {
                Navigator.shared.dopen(dataModel.link)
            }
            
            if let page = dataModel.page {
                contentLabel.text = page.contentPageName
                likeButton.isSelected = page.isLike
                Fly.page.bind(page.contentPageKey, notice: self) //绑定数据状态变化
                likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(page.likeCount), for: .normal)
            }
        }

    }
    
    func on_data_update(dataId: String, model: FlyModel?, isDeleted: Bool) {
        //同一个数据
        guard let pageLike = model as? Fly.PageHotData,let pg = self.page, pageLike.pageKey == pg.contentPageKey && !pg.contentPageKey.isEmpty else {
            return
        }
        let upLikeCount = pg.isLike != pageLike.isLike
        pg.isLike = pageLike.isLike
        likeButton.isSelected = pageLike.isLike
        
        if upLikeCount {
            pg.likeCount = pg.likeCount + ( pageLike.isLike ? 1 : -1 )
            likeButton.setTitle(NumberHelper.formatLikeAndCommentCount(pg.likeCount), for: .normal)
        }
    }
}
