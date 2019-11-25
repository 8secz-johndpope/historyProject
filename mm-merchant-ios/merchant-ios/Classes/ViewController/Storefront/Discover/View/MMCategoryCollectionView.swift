 //
 //  MMCategoryCollectionView.swift
 //  storefront-ios
 //
 //  Created by Demon on 14/6/18.
 //  Copyright © 2018年 WWE & CO. All rights reserved.
 //
 
 import UIKit

 class MMCategoryCollectionHeaderView: UICollectionReusableView {

    public var selelctedAllBtnBlock:(() -> Void)?
    public var titleText: String = "" {
        didSet {
            titleLb.text = titleText
            setNeedsUpdateConstraints()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(titleLb)
        self.addSubview(selectedAllBtn)
        selectedAllBtn.addSubview(arrowImageView)
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        titleLb.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(20)
            make.right.equalTo(selectedAllBtn.snp.left).offset(-10)
        }
        selectedAllBtn.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right).offset(-15)
            make.centerY.equalTo(self.snp.centerY)
            make.height.equalTo(20)
            make.width.equalTo(70)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.right.equalTo(self.selectedAllBtn.snp.right)
            make.centerY.equalTo(self.selectedAllBtn.snp.centerY)
            make.size.equalTo(CGSize(width: 5, height: 8))
        }
        
        super.updateConstraints()
    }
    
    @objc private func selectedAllBtnClick() {
        if let block = self.selelctedAllBtnBlock {
            block()
        }
    }
    
    private lazy var titleLb: UILabel = {
        let titleLb = UILabel()
        titleLb.textAlignment = .left
        titleLb.font = UIFont.fontWithSize(14, isBold: true)
        titleLb.textColor = UIColor(hexString: "#333333")
        return titleLb
    }()

    public lazy var selectedAllBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.regularFontWithSize(size: 12)
        btn.setTitleColor(UIColor(hexString: "#999999"), for: .normal)
        btn.setTitle("查看全部", for: .normal)
        btn.addTarget(self, action: #selector(selectedAllBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "category_selected"))
        return v
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 }
 
 
 // MARK: -  左侧二级类目的cell
class MMCategoryTaleViewCell: UITableViewCell {
    
    public var isSelectedCell: Bool = false {
        didSet {
            contentView.backgroundColor = isSelectedCell ? UIColor.white : UIColor(hexString: "#F5F5F5")
            horiLine.isHidden = !isSelectedCell
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loadUI()
    }
    
    public func setupModel(cat:Cat) {
        titleLb.text = cat.categoryNameOrigin.insertSomeStr(element: "\n", at: 6)
    }
    
    private func loadUI() {
        contentView.addSubview(titleLb)
        contentView.addSubview(horiLine)
        contentView.addSubview(verLine)
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        titleLb.snp.makeConstraints { (make) in
            make.top.right.bottom.equalTo(contentView)
            make.left.equalTo(horiLine.snp.right).offset(5)
        }
        horiLine.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.top).offset(7)
            make.left.equalTo(contentView.snp.left)
            make.bottom.equalTo(contentView.snp.bottom).offset(-7)
            make.width.equalTo(3)
        }
        verLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalTo(contentView)
            make.height.equalTo(1)
        }
        super.updateConstraints()
    }
    
    private lazy var titleLb: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.secondary15()
        lb.numberOfLines = 2
        lb.font = UIFont.systemFont(ofSize: 12)
        lb.textAlignment = .center
        return lb
    }()
    
    private lazy var horiLine: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor(hexString: "#ED2247")
        return line
    }()
    
    private lazy var verLine: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor(hexString: "#ECECEC")
        return line
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 }
 
 // MARK: -  右侧 三级类目的cell
 class MMCategoryContentCollectionCell: UICollectionViewCell {

    public var option: Cat? {
        didSet {
            if let cat = option {
                categoryName.text = cat.categoryName.insertSomeStr(element: "\n", at: 6)
                categoryImageView.mm_setImageWithURL(ImageURLFactory.getRaw(cat.featuredImage, category: .category, width: Constants.DefaultImageWidth.Small), placeholderImage: UIImage(named: "brand_placeholder"), clipsToBounds: true, contentMode: .scaleAspectFit)
                setNeedsUpdateConstraints()
            } else {
                categoryName.text = ""
                categoryImageView.image = nil
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        contentView.addSubview(categoryImageView)
        contentView.addSubview(categoryName)
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        categoryImageView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.top)
            make.centerX.equalTo(contentView.snp.centerX)
            make.width.height.equalTo(54)
        }
        categoryName.snp.makeConstraints { (make) in
            make.top.equalTo(categoryImageView.snp.bottom).offset(5)
            make.left.right.equalTo(contentView)
            make.height.greaterThanOrEqualTo(14)
        }
        super.updateConstraints()
    }
    
    lazy var categoryImageView: UIImageView = {
        let imgv = UIImageView()
        return imgv
    }()
    
    lazy var categoryName: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.numberOfLines = 2
        lb.textColor = UIColor.secondary15()
        lb.font = UIFont.systemFont(ofSize: 12)
        return lb
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 }
 
 

