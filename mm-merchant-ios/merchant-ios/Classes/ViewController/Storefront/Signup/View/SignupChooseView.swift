//
//  SignupChooseView.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/16.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class SignupChooseView: UIView,UITableViewDelegate,UITableViewDataSource {
    var selectIndex:Int = 0
    
    lazy var backgroundImageView:UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.image = UIImage(named: "area_box")
        return backgroundImageView
    }()
    
    lazy var tableView:UITableView = {
        let tableView = UITableView.init(frame: self.frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 32
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.clear
        tableView.bounces = false
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.register(ChooseMobileTableViewCell.self, forCellReuseIdentifier: "ChooseMobileTableViewCell")
        return tableView
    }()
    
    var tapHandler: ((String,Int) -> Void)?
    let _data = ["中国+86","香港+852"]
    
    lazy var erroImageView:UIView = {
        let erroImageView = UIView.init(frame: self.frame)
        erroImageView.backgroundColor = UIColor.white
        
        return erroImageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(backgroundImageView)
        self.addSubview(tableView)
        
        backgroundImageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        tableView.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(5)
            make.right.equalTo(self).offset(-5)
            make.top.equalTo(self).offset(17)
            make.bottom.equalTo(self).offset(-13)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseMobileTableViewCell", for: indexPath) as? ChooseMobileTableViewCell {
            if indexPath.row == selectIndex{
                cell.iconImageView.isHidden = false
            } else {
                cell.iconImageView.isHidden = true
            }
            
            cell.label.text = _data[indexPath.row]
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectIndex = indexPath.row
        tableView.reloadData()
        
        if let callback = tapHandler{
            callback(_data[indexPath.row],indexPath.row)
        }
    }
}

class ChooseMobileTableViewCell: UITableViewCell {
    lazy var label:UILabel = {
        let label = UILabel()
        label.text = "中国+86"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    lazy var iconImageView:UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "tick_red")
        iconImageView.sizeToFit()
        return iconImageView
    }()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.addSubview(label)
        self.contentView.addSubview(iconImageView)
        
        label.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView).offset(10)
            make.centerY.equalTo(self.contentView)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(label.snp.right).offset(14)
            make.centerY.equalTo(self.contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
