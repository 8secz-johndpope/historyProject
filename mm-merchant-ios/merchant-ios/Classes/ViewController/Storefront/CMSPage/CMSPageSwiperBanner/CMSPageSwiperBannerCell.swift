//
//  CMSPageSwiperBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/25.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageSwiperBannerCell: UICollectionViewCell,WRCycleScrollViewDelegate  {
    var _datas = [CMSPageDataModel]()
    
    lazy var cycleScrollView:WRCycleScrollView = {
        let cycleView = WRCycleScrollView(frame: self.bounds, type: .SERVER,margin:20, arcRandom:true)
        cycleView.isAutoScroll = false
        cycleView.currentDotColor = UIColor.black
        cycleView.otherDotColor = UIColor.lightGray
        cycleView.backgroundColor = UIColor.white
        return cycleView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.white
        
        self.contentView.addSubview(cycleScrollView)
        cycleScrollView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cycleScrollViewDidSelect(at index: Int, cycleScrollView: WRCycleScrollView, headView: UIView?) {
        // must be image tap in here
        let dataModel = _datas[index]
        Navigator.shared.sopen(dataModel.link, headView: headView)
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageSwiperBannerCellModel = model as? CMSPageSwiperBannerCellModel{
            if let data = cellModel.data {
                var isVideo = false
                for model in data {
                    if model.videoUrl.length > 1 {
                        isVideo = true
                        break
                    }
                }
               
                if cellModel.isLocationZeroBanner {
                    if !isVideo { // 没有视频的时候 自动轮播 不随机
                        cycleScrollView.isAutoScroll = true
                    }
                    cycleScrollView.isArcRandom = false
                    cellModel.isLocationZeroBanner = false
                } else {
                    if !isVideo { // 没有视频的时候 自动轮播 不随机
                        cycleScrollView.isAutoScroll = true
                    } else {
                        cycleScrollView.isArcRandom = true
                    }
                }
                
                _datas = data
                cycleScrollView.datas = data
            } else {
                _datas = []
                cycleScrollView.datas = []
            }
        }
    }
}
