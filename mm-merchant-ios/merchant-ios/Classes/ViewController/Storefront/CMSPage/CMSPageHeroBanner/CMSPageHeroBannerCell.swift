//
//  CMSPageHeroBannerCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/26.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageHeroBannerCell: UICollectionViewCell,WRCycleScrollViewDelegate {
    var _datas = [CMSPageDataModel]()
    var indexPath:IndexPath?
    
    lazy var cycleScrollView:WRCycleScrollView = {
        let flowLayout = CarouselFlowLayout()
        flowLayout.sideItemScale = 0.9
        flowLayout.sideItemAlpha = 1.0
        flowLayout.spacingMode = .fixed(spacing: 10)
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: self.bounds.width - 120, height: self.bounds.height )
        let cycleView = WRCycleScrollView(frame: self.bounds, type: .SERVER,flowLayout:flowLayout,cornerRadius:true)
        cycleView.isAutoScroll = false
        cycleView.showPageControl = false
        cycleView.delegate = self
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
        let dataModel = _datas[index]
        Navigator.shared.dopen(dataModel.link)
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
        
        //hero cell不会有更新操作，可以简单优化下
        if reused {//表示重用
            return
        }
        
        if let cellModel: CMSPageHeroBannerCellModel = model as? CMSPageHeroBannerCellModel {
            if let data = cellModel.data {
                cycleScrollView.datas = data
                _datas = data
            }
        }
    }
    
}


