//
//  StyleDetailViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 14/09/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//


import UIKit
import MJRefresh
import ObjectMapper

class StyleDetailViewController: MMUICollectionController<MMCellModel>,StyleDetailInfoCellDelegage{
    func collectButtonSelect() {
        print("self")
    }
    
    private var pageNo = 1
    private let GET_DATAS_SIZE = 6
    private var skuId:Int?
    private var brandList = [Brand]()
    private var syteLoaded: Bool = false //是否加载过syte数据
    private var syteStyles: [Style] = [] //相关帖子数据
    private var style = Style()
    private var contentOffsetY:CGFloat = 0.0
    private var navigationBarVisibility: MmFadeNavigationControllerNavigationBarVisibility = .hidden {
        didSet {
            UIApplication.shared.statusBarStyle = self.navigationBarVisibility == .visible ? .default : .default
        }
    }
    
    //MARK: - life
    override func onViewWillAppear(_ animated: Bool) {
        super.onViewWillAppear(animated)
        
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: contentOffsetY)
            navigationController.navigationBar.shadowImage = UIImage()
        }
        var alpha = contentOffsetY / 100
        if alpha > 1 {
            alpha = 1
        }
        titleLabel.alpha = alpha
    }
    override func onViewDidLoad() {
        super.onViewDidLoad()
        table.backgroundColor = .white
        self.title = ""

        let originY = -StartYPos + (IsIphoneX ? ScreenStatusHeight + 8 : ScreenStatusHeight)
        table.frame = CGRect(x: 0, y: originY, width: ScreenWidth, height: ScreenHeight - originY)

        table.mj_footer = MMRefreshFooter(refreshingTarget: self, refreshingAction: #selector(footerRefursh))
        
        if let skuId = ssn_Arguments["skuId"]?.int {
            self.skuId = skuId
        }
        
        loadStyle()
        
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: backButton)]
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: shareButton)]
        
    }
    
    func loadStyle() {
        if let skuId = skuId {
            SearchService.searchStyleBySkuId(skuId) { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value),
                            let pageData = styleResponse.pageData,
                            let style = pageData.first {
                            self.style = style
                            self.fetchs()
                            return
                        } else if !self.style.isValid() { //直接展示售罄就行了
                            //                        self.isProductActive = false
                        }
                    }
                }
            }
        }
    }
    
    func fetchs() {
        view.addSubview(bottomView)
        if let navigationBar = self.navigationController?.navigationBar {
            titleLabel.frame = CGRect(x:0, y: 0, width: navigationBar.width, height: navigationBar.height)
            titleLabel.text = style.brandName
            titleLabel.whenTapped {
                Navigator.shared.dopen(Navigator.mymm.website_brand_brandId + String(self.style.brandId))
            }
            self.navigationItem.titleView = titleLabel
        }
        
        if style.featuredImageList.count == 0 {
            style.featuredImageList = style.getDefaultImageList()
        }
        self.fetchs.fetch.append(StyleDetailBuilder.buiderImagesCellModel(videoUrl:self.style.videoURL,imageData: self.style.featuredImageList))
//        self.fetchs.fetch.append(StyleDetailBuilder.)
        self.fetchs.fetch.append(StyleDetailBuilder.buiderPriceAndInfoCellModel(style:self.style, delegate: self))
        self.fetchs.fetch.append(StyleDetailBuilder.buiderIntroduceCellModel(skuDesc:self.style.skuDesc, imageData: self.style.descriptionImageList))
        self.styleSearchData()
    }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    @objc private func footerRefursh()  {
        styleSearchData()
    }
    
    //MARK: - service
    private func styleSearchData() {
        SingnRecommendService.searchRecommendedProducts(skuid: self.style.defaultSkuId(),
                                                        merchantId: self.style.merchantId,
                                                        pagesize: 6,
                                                        pageno: self.pageNo,
                                                        syteLoaded:syteLoaded,
                                                        dataCount:self.syteStyles.count,
                                                        success: { (response) in
            self.table.mj_footer.endRefreshing()
            if let pageData = response.pageData,pageData.count > 0 {
                if response.containedSyte {
                    self.syteLoaded = true
                }
                self.pageNo = self.pageNo + 1
                self.syteStyles = self.syteStyles + pageData
                self.fetchs.fetch.append(StyleDetailBuilder.buiderStyleCellModel(pageData, isFirst: self.pageNo > 2 ? false : true))
            }
        }) { (erro) -> Bool in
            self.table.mj_footer.endRefreshing()
            return true
        }
    }
    
    //MARK: - MMCollectionViewDelegate
    @objc func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat {
        guard let m = fetchs.object(at: indexPath) as? CMSCellModel else {
            return 0.0
        }
        return m.supportMagicEdge
    }
    
    //MARK: - loadLayoutConfig
    override func loadLayoutConfig() -> MMLayoutConfig {
        var _config:MMLayoutConfig = MMLayoutConfig()
        _config.rowHeight = 0
        _config.columnCount = 2
        _config.rowDefaultSpace = 0
        _config.columnSpace = 8
        _config.supportMagicHorizontalEdge = true
        return _config
    }

   @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentOffsetY = scrollView.contentOffset.y + StartYPos
        if let navigationController = self.navigationController as? MmNavigationController {
            navigationController.setNavigationBarVisibility(offset: contentOffsetY)
        }
        var alpha = contentOffsetY / 100
        if alpha > 1 {
            alpha = 1
        }
        if (contentOffsetY > 100) {
            self.navigationBarVisibility = .visible
            shareButton.setImage(UIImage(named: "blackShare"), for: .normal)
            backButton.setImage(UIImage(named: "blackBack"), for: .normal)
            shareButton.alpha = 1
            backButton.alpha = 1
        } else {
            self.navigationBarVisibility = .hidden
            shareButton.setImage(UIImage(named: "greyShare"), for: .normal)
            backButton.setImage(UIImage(named: "greyBack"), for: .normal)
            shareButton.alpha = 1 - alpha
            backButton.alpha = 1 - alpha
        }
        self.navigationItem.titleView?.alpha = alpha
    }
    
    //MARK: - lazy
    private lazy var backButton:UIButton = {
        let backButton: UIButton = UIButton()
        backButton.setImage(UIImage(named: "greyBack"), for: .normal)
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 0)
        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return backButton
    }()
    private lazy var shareButton:UIButton = {
        let shareButton: UIButton = UIButton()
        shareButton.setImage(UIImage(named: "greyShare"), for: .normal)
        shareButton.frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        shareButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 0)
//        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        return shareButton
    }()
    
    private lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = style.brandName
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        //            if let tapGesture = tapGesture {
        //                label.addGestureRecognizer(tapGesture)
        //            }
        return titleLabel
    }()
    private lazy var bottomView:ProductDetailBottomView = {
        let bottomView = ProductDetailBottomView()
        let bottomViewHeight = 45 + ScreenBottom
        bottomView.frame = CGRect(x: 0, y: ScreenHeight - (45 + ScreenBottom), width: ScreenWidth, height: bottomViewHeight)
        bottomView.setIsFlashSale(false)
        bottomView.setLike(style.isWished())
        
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomViewHeight, right: 0)
        
        bottomView.addtocartTapHandler = {[weak self] in
          print("加入购物车")
        }
        bottomView.buyFlashSaleHandler = {[weak self] in
           print("立即抢")
        }
        bottomView.csTapHandler = {[weak self] in
           print("客服")
        }
        bottomView.postTapHandler = {
            print("购物车")
            Navigator.shared.dopen(Navigator.mymm.website_cart)
            
        }
        bottomView.wishTapHandler = {[weak self] in
            print("收藏")
        }
        
        return bottomView
    }()
}

extension StyleDetailViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return self.navigationBarVisibility
    }
}
