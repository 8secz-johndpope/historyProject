//
//  WRCycleScrollView.swift
//  WRCycleScrollViewDemo
//
//  Created by wangrui on 2017/5/12.
//  Copyright © 2017年 wangrui. All rights reserved.
//
//  Github地址：https://github.com/wangrui460/WRCycleScrollView

import UIKit

private let KEndlessScrollTimes = 128

@objc protocol WRCycleScrollViewDelegate
{
    /// 点击图片回调
    @objc optional func cycleScrollViewDidSelect(at index:Int, cycleScrollView:WRCycleScrollView, headView: UIView?)
    /// 图片滚动回调
    @objc optional func cycleScrollViewDidScroll(to index:Int, cycleScrollView:WRCycleScrollView)
}

class WRCycleScrollView: UIView
{
//=======================================================
// MARK: 对外提供的属性
//=======================================================
    weak var delegate:WRCycleScrollViewDelegate?
    
    private var cellMargin:CGFloat = 0.0
    
/// 数据相关
    var imgsType:ImgType = .SERVER
//    var localImgArray :[String]? {
//        didSet {
//            if let local = localImgArray {
////                proxy = Proxy(type: .LOCAL, array: local)
//                reloadData()
//            }
//        }
//    }
//    var serverImgArray:[String]? {
//        didSet {
//            if let server = serverImgArray {
////                proxy = Proxy(type: .SERVER, array: server)
//                reloadData()
//            }
//        }
//    }
    
    var datas: [CMSPageDataModel]?
    {
        didSet {
            reloadData()
        }
    }
    var descTextArray :[String]?
    
/// WRCycleCell相关
    var descLabelFont: UIFont?
    var descLabelTextColor: UIColor?
    var descLabelHeight: CGFloat?
    var descLabelTextAlignment:NSTextAlignment?
    var bottomViewBackgroundColor: UIColor?
    var bottomMargin:CGFloat =  0.0
    var isCornerRadius:Bool = false
    var otherFlowLayout:UICollectionViewFlowLayout?
    var finishLyout:Bool = false
    var isArcRandom: Bool = false // 是否随机
    
    
/// 主要功能需求相关
    override var frame: CGRect {
        didSet {
            flowLayout?.itemSize = CGSize(width: frame.size.width, height: frame.size.height - bottomMargin)
            collectionView?.frame = frame
        }
    }
    var isAutoScroll:Bool = true {
        didSet {
            timer?.invalidate()
            timer = nil
            if isAutoScroll == true {
                setupTimer()
            }
        }
    }
    var isEndlessScroll:Bool = true {
        didSet {
            reloadData()
        }
    }
    var autoScrollInterval: Double = 3
    
/// pageControl相关
    var showPageControl: Bool = true {
        didSet {
            setupPageControl()
        }
    }
    var currentDotColor: UIColor = UIColor.orange {
        didSet {
            self.pageControl?.currentPageIndicatorTintColor = currentDotColor
        }
    }
    var otherDotColor: UIColor = UIColor.gray {
        didSet {
            self.pageControl?.pageIndicatorTintColor = otherDotColor
        }
    }
    
//=======================================================
// MARK: 对外提供的方法
//=======================================================
    func reloadData()
    {
        timer?.invalidate()
        timer = nil
      
        collectionView?.reloadData()
        setupPageControl()
        changeToFirstCycleCell(animated: false)
        if isAutoScroll == true {
            setupTimer()
        }
    }

//=======================================================
// MARK: 内部属性
//=======================================================
    fileprivate var imgsCount:Int {
        if isEndlessScroll {
            if itemsInSection > 1 {
                return (itemsInSection / KEndlessScrollTimes)
            }
        }
        return itemsInSection
//        return (isEndlessScroll == true) ? (itemsInSection / KEndlessScrollTimes) : itemsInSection
    }
    
    fileprivate var itemsInSection:Int {
        guard let datas = self.datas else {
            return 0
        }
        if isEndlessScroll {
            if datas.count > 1 {
                return datas.count * KEndlessScrollTimes
            }
        }
        return datas.count
    }
    
    fileprivate var firstItem:Int {
        return (isEndlessScroll == true) ? (itemsInSection / 2) : 0
    }
    
    fileprivate var canChangeCycleCell:Bool {
        guard itemsInSection  != 0 ,
            let _ = collectionView,
            let _ = flowLayout else {
                return false
        }
        return true
    }
    
    //无法实现一屏幕有多个cell呈现问题
    fileprivate var indexOnPageControl:Int {
        var curIndex = Int((collectionView!.contentOffset.x + flowLayout!.itemSize.width * 0.5) / flowLayout!.itemSize.width)
        curIndex = max(0, curIndex)
        return curIndex % imgsCount
    }

    fileprivate var flowLayout:UICollectionViewFlowLayout?
    fileprivate var collectionView:UICollectionView?
    fileprivate let CellVideoID = "BannerVideoCell"
    fileprivate let CellImageID = "WRCycleCell"
    fileprivate let CellSkuID = "CMSPageRankingBannerContentCell"
    fileprivate var pageControl:UIPageControl?
    fileprivate var timer:Timer?
    // 标识子控件是否布局完成，布局完成后在layoutSubviews方法中就不执行 changeToFirstCycleCell 方法
    fileprivate var isLoadOver = false
    

//=======================================================
// MARK: 构造方法
//=======================================================
    /// 构造方法
    ///
    /// - Parameters:
    ///   - frame: frame
    ///   - type:  ImagesType                         default:Server
    ///   - imgs:  localImgArray / serverImgArray     default:nil
    ///   - descs: descTextArray                      default:nil
    init(frame: CGRect, type:ImgType = .SERVER, imgs:[String]? = nil, descs:[String]? = nil,margin:CGFloat? = nil,flowLayout:UICollectionViewFlowLayout? = nil,cornerRadius:Bool? = false, arcRandom: Bool? = false)
    {
        if let margin = margin{
            bottomMargin = margin
        }
        if let cornerRadius = cornerRadius{
            isCornerRadius = cornerRadius
        }
        super.init(frame: frame)

        if let flowLayout =  flowLayout{
            otherFlowLayout = flowLayout
            setupCollectionView(true)
        }else{
            setupCollectionView(false)
        }
        
        if let arcRandom = arcRandom {
            isArcRandom = arcRandom
        }
        
        imgsType = type
        if imgsType == .SERVER {
            if let _ = imgs {
//                proxy = Proxy(type: .SERVER, array: server)
            }
        }
        else {
            if let _ = imgs {
//                proxy = Proxy(type: .LOCAL, array: local)
            }
        }
        
        if let descTexts = descs {
            descTextArray = descTexts
        }
        reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        collectionView?.delegate = nil
        print("WRCycleScrollView  deinit")
    }
    
    private var isHeroBanner: Bool {
        get {
            return otherFlowLayout != nil
        }
    }
    
//=======================================================
// MARK: 内部方法（layoutSubviews、willMove）
//=======================================================
    override func layoutSubviews()
    {
        super.layoutSubviews()
        // 解决WRCycleCell自动偏移问题
        collectionView?.contentInset = .zero
        if isLoadOver == false {
            changeToFirstCycleCell(animated: false)
        }
        if showPageControl == true {
            setupPageControlFrame()
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?)
    {   // 解决定时器导致的循环引用
        super.willMove(toSuperview: newSuperview)
        // 展现的时候newSuper不为nil，离开的时候newSuper为nil
        guard let _ = newSuperview else {
            timer?.invalidate()
            timer = nil
            return
        }
    }
}

//=======================================================
// MARK: - 无限轮播相关（定时器、切换图片、scrollView代理方法）
//=======================================================
extension WRCycleScrollView
{
    func setupTimer()
    {
        timer = Timer(timeInterval: autoScrollInterval, target: self, selector: #selector(changeCycleCell), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    fileprivate func changeToFirstCycleCell(animated:Bool)
    {
        if canChangeCycleCell == true {
            
            if let otherFlowLayout = otherFlowLayout,let collectionView = collectionView{
                if let rect = collectionView.layoutAttributesForItem(at: IndexPath(item: firstItem, section: 0)){
                     collectionView.contentOffset = CGPoint.init(x:rect.frame.origin.x - (ScreenWidth - otherFlowLayout.itemSize.width) / 2, y: rect.frame.origin.y)
                    cellMargin = collectionView.contentOffset.x / CGFloat(firstItem)
                }

            } else {
                if isArcRandom {
                    arcRandomItem()
                } else {
                    scrollToItem(firstItem,animated:animated)
                }
            }
        }
    }
    
    func scrollToItem(_: Int,animated:Bool) {
        let indexPath = IndexPath(item: firstItem, section: 0)
        collectionView!.scrollToItem(at: indexPath, at: .init(rawValue: 0), animated: animated)
    }
    
    /// 随机一个item
    fileprivate func arcRandomItem() {
        if let data = datas {
            if data.count > 1 {
//                isArcRandom = true
                let randomNum = Int(arc4random() % UInt32(data.count))
                let startItem = (KEndlessScrollTimes / 2 * data.count) + randomNum
                let indexPath = IndexPath(item: startItem, section: 0)
                collectionView!.scrollToItem(at: indexPath, at: .init(rawValue: 0), animated: false)
            }
        }
    }
    
    // 执行这个方法的前提是 isAutoScroll = true
    @objc func changeCycleCell()
    {
        if canChangeCycleCell == true
        {
            let curItem = Int(collectionView!.contentOffset.x / flowLayout!.itemSize.width)
            if curItem == itemsInSection - 1
            {
                let animated = (isEndlessScroll == true) ? false : true
                changeToFirstCycleCell(animated: animated)
            }
            else
            {
                let indexPath = IndexPath(item: curItem + 1, section: 0)
                collectionView!.scrollToItem(at: indexPath, at: .init(rawValue: 0), animated: true)
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if isAutoScroll == true {
            setupTimer()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
        
        guard let collectionView = collectionView else {
            return
        }
        let paths = collectionView.indexPathsForVisibleItems
        var delegateWillFocus: PlayVideoDelegate?
        
        for path in paths {
            if let cell = collectionView.cellForItem(at: path) as? BannerVideoCell /* for hero banner */ {
                if cell.isPlayerOutOfScreen(ratio: 0.3) /* assume not focusing */ {
                    VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell)
                } else {
                    delegateWillFocus = cell
                }
            }
        }
        
        /* will do video play in here after all videos are unfocus */
        if let cell = delegateWillFocus {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell)
        }
    }
    
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
    {
        guard canChangeCycleCell else {
            return
        }
        
        if let _ = otherFlowLayout{

                var curIndex = Int(roundf(Float(collectionView!.contentOffset.x / cellMargin)))
                curIndex = max(0, curIndex % imgsCount)
                delegate?.cycleScrollViewDidScroll?(to:  curIndex, cycleScrollView: self)
     
        }else{
             delegate?.cycleScrollViewDidScroll?(to: indexOnPageControl, cycleScrollView: self)
        }
        

        
        if indexOnPageControl >= firstItem {
            isLoadOver = true
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        guard canChangeCycleCell else {
            return
        }
        pageControl?.currentPage = indexOnPageControl
    }
}

//=======================================================
// MARK: - pageControl页面
//=======================================================
extension WRCycleScrollView
{
    fileprivate func setupPageControl()
    {
        pageControl?.removeFromSuperview()
        if showPageControl == true
        {
            pageControl = UIPageControl()
            pageControl?.numberOfPages = imgsCount
            pageControl?.hidesForSinglePage = true
            pageControl?.currentPageIndicatorTintColor = self.currentDotColor
            pageControl?.pageIndicatorTintColor = self.otherDotColor
            pageControl?.isUserInteractionEnabled = false
            addSubview(pageControl!)
        }
    }
    
    fileprivate func setupPageControlFrame()
    {
        let pageW = bounds.width
        let pageH:CGFloat = 20
        let pageX = bounds.origin.x
        let pageY = bounds.height -  pageH
        self.pageControl?.frame = CGRect(x:pageX, y:pageY, width:pageW, height:pageH)
    }
}

//=======================================================
// MARK: - WRCycleCell 相关
//=======================================================
extension WRCycleScrollView: UICollectionViewDelegate,UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    fileprivate func setupCollectionView(_ otherFlow:Bool)
    {
        flowLayout = UICollectionViewFlowLayout()
        flowLayout?.itemSize = CGSize(width: frame.size.width, height: frame.size.height - bottomMargin)
        flowLayout?.minimumLineSpacing = 0
        flowLayout?.scrollDirection = .horizontal
        
        if otherFlow {
            if let otherFlowLayout = otherFlowLayout {
                
                collectionView = UICollectionView(frame: CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height - bottomMargin), collectionViewLayout: otherFlowLayout)
                collectionView?.backgroundColor = .white
                collectionView?.alwaysBounceVertical = false
                addSubview(collectionView!)
            }

            
     
        } else {
            collectionView = UICollectionView(frame: CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height - bottomMargin), collectionViewLayout: flowLayout!)
            collectionView?.isPagingEnabled = true
            addSubview(collectionView!)
        }

        collectionView?.register(BannerVideoCell.self, forCellWithReuseIdentifier: CellVideoID)
        collectionView?.register(WRCycleCell.self, forCellWithReuseIdentifier: CellImageID)
        collectionView?.register(CMSPageRankingBannerContentCell.self, forCellWithReuseIdentifier: CellSkuID)
        collectionView?.bounces = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return itemsInSection
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let curIndex = indexPath.item % imgsCount
        if let datas = self.datas {
            let data = datas[curIndex]
            
            var imageUrl: URL?
            if let image = data.imageUrl {
                imageUrl = ImageURLFactory.URLSize1000(image, category: data.dType == DataType.SKU ? .product : .banner)
            }
            
            let video = data.videoUrl
            if !video.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellVideoID, for: indexPath) as! BannerVideoCell
                cell.setImageURL(imageUrl?.absoluteString ?? "")
                cell.setDeeplink(data.link)
                cell.setVideoURL(video)
                cell.track_visitId = data.vid
                cell.track_media = video
                cell.shouldShowCoverImageWhenPause = self.isHeroBanner
                cell.bannerType = self.isHeroBanner ? .undefine : .topBanner
                cell.track_data(id: self.track_data_id(), type: self.track_data_type())
                return cell
            } else {
                if data.skuDatas.count > 0{
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellSkuID, for: indexPath) as! CMSPageRankingBannerContentCell
                    cell.data = data
                    if isCornerRadius{
                        cell.layer.cornerRadius = 4.0
                        cell.layer.masksToBounds = true
                    }
                    cell.track_visitId = data.vid
                    cell.track_media = ""
                    cell.track_data(id: self.track_data_id(), type: self.track_data_type())
                    return cell
                    
                }else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellImageID, for: indexPath) as! WRCycleCell
                    if let url = imageUrl {
                        cell.imgSource = ImgSource.SERVER(url: url)
                    } else {
                        cell.imgSource = ImgSource.LOCAL(name: "placeholder")
                    }
                    if isCornerRadius{
                        cell.layer.cornerRadius = 4.0
                        cell.layer.masksToBounds = true
                    }
                    if data.formPDP {
                        cell.imgView.contentMode = .scaleAspectFit
                    }
                    cell.track_visitId = data.vid
                    cell.track_media = ""
                    cell.track_data(id: self.track_data_id(), type: self.track_data_type())
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BannerVideoCell {
            VideoPlayManager.shared.focusVideoPlayer(delegate: cell as PlayVideoDelegate, shouldAutoStart: indexPath.row == firstItem)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? BannerVideoCell {
            VideoPlayManager.shared.unFocusVideoPlayer(delegate: cell as PlayVideoDelegate)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        //寻找响应位置
        let index = indexPath.row % imgsCount
        var headView: UIView?
        
        if let tapCell = collectionView.cellForItem(at: indexPath) as? WRCycleCell {
            let imageView = ProductListImageView(frame: tapCell.imgView.frame)
            imageView.image = tapCell.imgView.image
            headView = imageView
        }
        
        delegate?.cycleScrollViewDidSelect?(at: index, cycleScrollView: self, headView: headView)
    }
}


