//
//  ProductListSearchConditionsCell.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListSearchConditionsCell: UICollectionReusableView {
    var searchTap: (() -> Void)?
    var sortTap: ((CGFloat) -> Void)?
    var cellModel: ProductListSearchConditionsCellModel?
    var categoryShort: ((_ filter: StyleFilter?) -> Void)?
    
    //MARK:- life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        
        self.addSubview(nameLabel)
        self.addSubview(synthesizeLabel)
        self.addSubview(searchLabel)
        self.addSubview(firstIconImageView)
        self.addSubview(secondIconImageView)
        self.addSubview(firstTapView)
        self.addSubview(secondTapView)
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(searchLabel)
            make.left.equalTo(10)
        }
        secondIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel)
            make.right.equalTo(self).offset(-10)
        }
        searchLabel.snp.makeConstraints { (make) in
            make.top.equalTo(14.5)
            make.right.equalTo(secondIconImageView.snp.left).offset(-10)
        }
        firstIconImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel)
            make.right.equalTo(searchLabel.snp.left).offset(-10)
        }
        synthesizeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(searchLabel)
            make.right.equalTo(firstIconImageView.snp.left).offset(-10)
        }
        firstTapView.snp.makeConstraints { (make) in
            make.right.equalTo(self)
            make.left.equalTo(searchLabel)
            make.top.equalTo(self)
            make.bottom.equalTo(searchLabel).offset(14.5)
        }
        secondTapView.snp.makeConstraints { (make) in
            make.left.equalTo(synthesizeLabel)
            make.right.equalTo(searchLabel.snp.left)
            make.top.equalTo(self)
            make.bottom.equalTo(firstTapView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - event response
    @objc func touchFirstTapView() {
        if let searchTap = searchTap {
            searchTap()
        }
    }
    
    @objc func touchSecondTapView() {
        if let sortTap = sortTap{
            let window = UIApplication.shared.keyWindow!
            let rect = self.convert(self.bounds, to: window)
            if let cellModel = cellModel{
                if cellModel.belongsToContainer{
                    sortTap(self.frame.size.height)
                }else {
                    sortTap(rect.origin.y + self.frame.size.height)
                }
            }
        }
    }
    
    //MARK: - private methods
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {
        if let cellModel: ProductListSearchConditionsCellModel = model as? ProductListSearchConditionsCellModel{
            self.cellModel = cellModel
            
            nameLabel.text = String.localize("LB_CA_OMS_TOTAL_PRODUCT").replacingOccurrences(of: "{0}", with: "\(cellModel.stylesTotal)")
            
            self.searchTap = {
                if let searchTap = cellModel.searchTap{
                    searchTap()
                }
            }
            self.sortTap = { maxY in
                if let sortTap = cellModel.sortTap{
                    sortTap(maxY)
                }
            }
            self.categoryShort = { filter in
                if let categoryShort = cellModel.categoryShort{
                    categoryShort(filter)
                }
            }
            
            if cellModel.sortMenu.length == 0{
                synthesizeLabel.text = String.localize("LB_CA_SORT_OVERALL")
            }else {
                synthesizeLabel.text = cellModel.sortMenu
            }
            if cellModel.selctCategoryShort {
                searchLabel.textColor = UIColor.primary1()
            }else {
                 searchLabel.textColor = UIColor.secondary3()
            }
        }
    }
    
    //MARK: - lazy
    lazy var nameLabel:UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.secondary3()
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        return nameLabel
    }()
    lazy var synthesizeLabel:UILabel = {
        let synthesizeLabel = UILabel()
        synthesizeLabel.textColor = UIColor.secondary3()
        synthesizeLabel.font = UIFont.systemFont(ofSize: 14)
        return synthesizeLabel
    }()
    lazy var searchLabel:UILabel = {
        let searchLabel = UILabel()
        searchLabel.textColor = UIColor.secondary3()
        searchLabel.font = UIFont.systemFont(ofSize: 14)
        searchLabel.text = String.localize("LB_CA_FILTER")
        return searchLabel
    }()
    lazy var firstIconImageView:UIImageView = {
        let firstIconImageView = UIImageView(image: UIImage(named: "sort_desc_grey"))
        firstIconImageView.sizeToFit()
        return firstIconImageView
    }()
    lazy var secondIconImageView:UIImageView = {
        let secondImageView = UIImageView(image: UIImage(named: "sort_desc_grey"))
        secondImageView.sizeToFit()
        return secondImageView
    }()
    lazy var firstTapView:UIView = {
        let firstTapView = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchFirstTapView))
        firstTapView.addGestureRecognizer(tapGesture)
        return firstTapView
    }()
    lazy var secondTapView:UIView = {
        let secondTapView = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchSecondTapView))
        secondTapView.addGestureRecognizer(tapGesture)
        return secondTapView
    }()
    lazy var backView:UIView = {
        let backView = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchFirstTapView))
        backView.addGestureRecognizer(tapGesture)
        return backView
    }()
}

