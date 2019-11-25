//
//  ProductListSortView.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/22.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class ProductListSortView: UIView,UITableViewDelegate,UITableViewDataSource{
    var selectIndex:Int = 0 {
        didSet {
            tableView.reloadData()
        }
    }
    var selectTap: ((Int,String) -> Void)?
    var isSelected:Bool = false{
        didSet {
            blackView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: self.frame.height)
            
            let tableViewHeight =  CGFloat(50 * sortMenu.count)
            
            
            if isSelected {
                tableView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: 0)
                UIView.animate(withDuration: 0.5) {
                    self.tableView.frame = CGRect.init(x: 0, y: 0 , width: ScreenWidth, height: tableViewHeight)
                }
                
            }else {
                tableView.frame = CGRect.init(x: 0, y: 0, width: ScreenWidth, height: tableViewHeight)
                UIView.animate(withDuration: 0.5) {
                    self.tableView.frame = CGRect.init(x: 0, y: 0 , width: ScreenWidth, height: 0)
//                    UIView.animate(withDuration: 0.5, animations: {
//                         self.removeFromSuperview()
//                    })
                }
                self.removeFromSuperview()
            }
            tableView.reloadData()
     
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortMenu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       if let cell = tableView.dequeueReusableCell(withIdentifier: "ProductListSortViewCell", for: indexPath) as? ProductListSortViewCell{
            
            cell.titleLabel.text = sortMenu[indexPath.row]
            if indexPath.row == selectIndex {
                cell.titleLabel.textColor = UIColor.primary1()
                cell.selectImageView.isHidden = false
            }else {
                cell.titleLabel.textColor = UIColor.secondary2()
                cell.selectImageView.isHidden = true
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    var sortMenu: [String] = [String.localize("LB_CA_SORT_OVERALL"),String.localize("LB_CA_SORT_DATE"),String.localize("LB_CA_SORT_HOT"),String.localize("LB_CA_SORT_PRICE_ASC"),String.localize("LB_CA_SORT_PRICE_DESC")]
    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.register(PickerCell.self, forCellWithReuseIdentifier: PickerCell.CellIdentifier)
//        self.delegate = self
//        self.dataSource = self
//    }
    
    lazy var tableView:UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.lightGray
        tableView.bounces = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.register(ProductListSortViewCell.self, forCellReuseIdentifier: "ProductListSortViewCell")
        return tableView
    }()
    
    lazy var blackView:UIView = {
        let blackView = UIView.init(frame: self.bounds)
        blackView.backgroundColor = .black
        blackView.alpha = 0.5
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchBlackView))
        blackView.addGestureRecognizer(tapGesture)
        return blackView
    }()
    

    
    @objc func touchBlackView()  {
        self.removeFromSuperview()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear

        self.addSubview(blackView)
        self.addSubview(tableView)
        
        
    
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectTap = selectTap {
            selectIndex = indexPath.row
            selectTap(indexPath.row,sortMenu[indexPath.row])
        }
    }
    
}

class ProductListSortViewCell: UITableViewCell {
    lazy var selectImageView:UIImageView = {
        let selectImageView = UIImageView()
        selectImageView.image = UIImage(named: "tick")
        selectImageView.sizeToFit()
        return selectImageView
    }()
    
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        return titleLabel
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.backgroundColor = UIColor(hexString: "#FAFAFA")
        
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(selectImageView)
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(20)
        }
        selectImageView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.contentView)
            make.right.equalTo(self.contentView).offset(-20)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

