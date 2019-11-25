//
//  CMSPageRankingBannerCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/6/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CMSPageRankingBannerCell: UICollectionViewCell,WRCycleScrollViewDelegate {
    var _datas = [CMSPageDataModel]()
    var indexPath:IndexPath?
    
    lazy var cycleScrollView:WRCycleScrollView = {
        let flowLayout = CarouselFlowLayout()
        flowLayout.sideItemScale = 0.9
        flowLayout.sideItemAlpha = 1.0
        flowLayout.spacingMode = .fixed(spacing: 10)
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: self.bounds.width - 80, height: self.bounds.height  )
        let cycleView = WRCycleScrollView(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height ), type: .SERVER,flowLayout:flowLayout,cornerRadius:true)
        cycleView.isAutoScroll = false
        cycleView.showPageControl = false
        cycleView.backgroundColor = UIColor.white
        cycleView.delegate = self
        return cycleView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        self.contentView.addSubview(cycleScrollView)
        
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cycleScrollViewDidScroll(to index: Int, cycleScrollView: WRCycleScrollView) {
        if let fetch = self.ssn_fetchs as? MMFetchsController<MMCellModel> {
            if let indexpath = self.indexPath,let cellModel = fetch.fetch[indexpath.row - 1] as? CMSPageTitleCellModel {
                cellModel.tipSelect = "\(index + 1)"
                fetch.update(at: IndexPath.init(row: indexpath.row - 1, section: 0))
            }
        }
    }

    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        
        self.indexPath = indexPath
        
        if reused {
            return
        }
        
        if let cellModel: CMSPageRankingBannerCellModel = model as? CMSPageRankingBannerCellModel{

            if let data = cellModel.data {
                _datas.removeAll()
                
                var index = 0
                var list = [CMSPageDataModel]()
                for dateModel:CMSPageDataModel in data {
                    if dateModel.dType == DataType.BANNER{
                        list.append(dateModel)
                        _datas.append(dateModel)
                        index = index + 1
                    }else if dateModel.dType == DataType.SKU{
                        if index <= _datas.count && index >= 1{
                            let bannerModel = _datas[index - 1]
                            bannerModel.skuDatas.append(dateModel)
                            _datas[index - 1] = bannerModel
                        }
                        
                    }
                }
                cycleScrollView.datas = _datas
                
            }
            
            //tracking 需要
            cycleScrollView.track_data(id: cellModel.compId, type: cellModel.compType)
            cycleScrollView.track_consoleTitle = cellModel.compName
        }
    }
}
