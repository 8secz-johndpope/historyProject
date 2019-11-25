//
//  CMSPageTitleCell.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/27.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class CMSPageTitleCell: UICollectionViewCell {
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        return titleLabel
    }()
    lazy var tipSelectLabel:UILabel = {
        let tipSelectLabel = UILabel()
        tipSelectLabel.font = UIFont.boldSystemFont(ofSize: 22)
        tipSelectLabel.isHidden = true
        return tipSelectLabel
    }()
    lazy var tipCountLabel:UILabel = {
        let tipCountLabel = UILabel()
        tipCountLabel.font = UIFont.systemFont(ofSize: 12)
        tipCountLabel.textColor = UIColor.secondary16()
        tipCountLabel.isHidden = true
        return tipCountLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(tipSelectLabel)
        self.contentView.addSubview(tipCountLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(5)
            make.left.equalTo(self.contentView).offset(15)
        }
        tipCountLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-15)
            make.height.equalTo(self.contentView)
        }
        tipSelectLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(tipCountLabel).offset(-2)
            make.right.equalTo(tipCountLabel.snp.left).offset(-2)
            make.height.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: CMSPageTitleCellModel = model as? CMSPageTitleCellModel{
            titleLabel.text = cellModel.title
            
            if cellModel.tipSelect.count > 0 && cellModel.tipCount.count > 0 {
                tipCountLabel.text = cellModel.tipCount
                tipSelectLabel.text = cellModel.tipSelect
                tipSelectLabel.isHidden = false
                tipCountLabel.isHidden = false
            } else {
                tipSelectLabel.isHidden = true
                tipCountLabel.isHidden = true
            }
            
            if let color = cellModel.backgroundColor {
                self.backgroundColor = color
            }
            
        }
    }
}
