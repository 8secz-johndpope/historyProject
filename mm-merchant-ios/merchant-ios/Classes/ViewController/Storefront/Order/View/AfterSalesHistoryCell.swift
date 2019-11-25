//
//  AfterSalesHistoryCell.swift
//  merchant-ios
//
//  Created by Gambogo on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesHistoryCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    static let CellIdentifier = "AfterSalesHistoryCellID"
    
    static let ContainerHorizontalPadding: CGFloat = 15
    static let ContentHorizontalPadding: CGFloat = 10
    static let SubjectLabelTopPadding: CGFloat = 15
    static let SubjectLabelBottomLineTopPadding: CGFloat = 10
    static let DetailLabelTopPadding: CGFloat = 10
    static let LabelHeight: CGFloat = 20
    static let FontSize = 14
    
    private final let PaddingContainerBottom: CGFloat = 15
    
    private var containerView = UIView()
    private var subjectLabel = UILabel()
    private var subjectLabelBottomLine = UIView()
    private var detailLabel = UILabel()
    private var historyStatusLabel = UILabel()
    
    //Collection
    private var collectionHeight: CGFloat = 0
    private var collectionView: UICollectionView!
    private var headerView = UIView()
    private var headerButton = UIButton()
    
    
    var data: AfterSalesHistoryData? {
        didSet {
            if let data = self.data {
                subjectLabel.text = data.historySubject
                detailLabel.text = data.historyDetails
                historyStatusLabel.text = data.historyStatus
                
                if data.photoList.count > 0 {
                    self.collectionView.reloadData()
                }
                
                updateViews()
                //should only updateBackgroundColor after updateViews to avoid layout issue
                updateBackgroundColor()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subjectLabel.formatSize(AfterSalesHistoryCell.FontSize)
        subjectLabel.textColor = UIColor.grayTextColor()
        subjectLabel.numberOfLines = 1
        containerView.addSubview(subjectLabel)
        
        subjectLabelBottomLine.backgroundColor = UIColor.secondary3()
        containerView.addSubview(subjectLabelBottomLine)
        
        detailLabel.formatSize(AfterSalesHistoryCell.FontSize)
        detailLabel.textColor = UIColor.grayTextColor()
        detailLabel.numberOfLines = 0
        containerView.addSubview(detailLabel)
        
        historyStatusLabel.formatSize(12)
        historyStatusLabel.textColor = UIColor.secondary2()
        historyStatusLabel.adjustsFontSizeToFitWidth = true
        historyStatusLabel.minimumScaleFactor = 0.5
        historyStatusLabel.numberOfLines = 1
        containerView.addSubview(historyStatusLabel)

        containerView.layer.backgroundColor = UIColor.white.cgColor
        contentView.addSubview(containerView)
        
        //Set up collection view for photo list
        setupCollectionView()
        containerView.addSubview(collectionView)
        
        //Prepare layout before set data - Remove this line will make the cell can't show content
        containerView.frame = CGRect(x: AfterSalesHistoryCell.ContainerHorizontalPadding, y: 0, width: frame.width - (AfterSalesHistoryCell.ContainerHorizontalPadding * 2), height: frame.height - PaddingContainerBottom)
    }
    
    //MARK: - Set up
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets.zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: collectionHeight)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: HorizontalImageCell.getHeaderViewHeight(), width: frame.width, height: collectionHeight), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HorizontalImageCell.self, forCellWithReuseIdentifier: HorizontalImageCell.CellIdentifier)
    }
    
    //MARK: - Views
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func updateBackgroundColor() {
        if let data = self.data {
            switch data.notificationEventId {
            case .orderConsumerRequestCancel, .returnRequested, .disputeSubmitted:
                containerView.layer.backgroundColor = UIColor(hexString: "#FFDCE2").cgColor
                containerView.roundCorners([.topLeft , .bottomLeft, .bottomRight], radius: 10)
            default:
                containerView.layer.backgroundColor = UIColor.white.cgColor
                containerView.roundCorners([.bottomLeft, .topRight, .bottomRight], radius: 10)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
    func updateViews() {
        containerView.frame = CGRect(x: AfterSalesHistoryCell.ContainerHorizontalPadding, y: 0, width: frame.width - (AfterSalesHistoryCell.ContainerHorizontalPadding * 2), height: frame.height - PaddingContainerBottom)
        
        subjectLabel.frame = CGRect(x: AfterSalesHistoryCell.ContentHorizontalPadding, y: AfterSalesHistoryCell.SubjectLabelTopPadding, width: containerView.width - (AfterSalesHistoryCell.ContentHorizontalPadding * 2), height: AfterSalesHistoryCell.LabelHeight)
        subjectLabelBottomLine.frame = CGRect(x: AfterSalesHistoryCell.ContentHorizontalPadding, y: subjectLabel.frame.maxY + AfterSalesHistoryCell.SubjectLabelBottomLineTopPadding, width: containerView.width - (AfterSalesHistoryCell.ContentHorizontalPadding * 2), height: 1)
        
        if let afterSalesHistoryData = self.data {
            let orderDetailLabelSize = AfterSalesHistoryCell.getSizeDetailLabel(afterSalesHistoryData, cellWidth: frame.width)
            detailLabel.frame = CGRect(x: AfterSalesHistoryCell.ContentHorizontalPadding, y: subjectLabelBottomLine.frame.maxY + AfterSalesHistoryCell.DetailLabelTopPadding, width: orderDetailLabelSize.width, height: orderDetailLabelSize.height)
            
            if afterSalesHistoryData.photoList.count > 0 {
                collectionHeight = AfterSalesHistoryCell.getHeightPhotoListView(cellWidth: frame.width)
                collectionView.isHidden = false
            } else {
                collectionHeight = 0
                collectionView.isHidden = true
            }
            
            collectionView.frame = CGRect(x: 0, y: detailLabel.frame.maxY, width: containerView.width, height: collectionHeight)
        } else { //Force hide if don't have data
            collectionHeight = 0
            collectionView.isHidden = true
            collectionView.frame = CGRect(x: 0, y: detailLabel.frame.maxY - 10, width: containerView.width, height: collectionHeight)
        }
        
        historyStatusLabel.frame = CGRect(x: AfterSalesHistoryCell.ContentHorizontalPadding, y: detailLabel.frame.maxY + collectionHeight, width: containerView.width - (AfterSalesHistoryCell.ContentHorizontalPadding * 2), height: AfterSalesHistoryCell.LabelHeight)
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HorizontalImageCell.CellIdentifier, for: indexPath) as! HorizontalImageCell
        cell.hideHeaderView = true
        cell.backgroundColor = UIColor.clear
        cell.collectionViewBackgroundColor = UIColor.clear
        cell.lineSpacingItems = 6.0
        
        cell.dataSource = []
        if let data = self.data {
            for imageKey in data.photoList{
                let imageBucket = ImageBucket(imageKey: imageKey, category: ImageCategory.orderReturnImage)
                cell.dataSource?.append(imageBucket)
            }
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        cell.disableScrollToTop()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: containerView.frame.sizeWidth, height: collectionView.bounds.sizeHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: - Size
    
    class func getHeightPhotoListView(cellWidth: CGFloat) -> CGFloat{
        return cellWidth / 4.25
    }
    
    class func getSizeDetailLabel(_ afterSalesHistoryData: AfterSalesHistoryData, cellWidth: CGFloat) -> CGSize {
        let labelWidth = cellWidth - ((ContainerHorizontalPadding + ContentHorizontalPadding) * 2)
        let dummyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
        dummyLabel.formatSize(FontSize)
        dummyLabel.numberOfLines = 0
        if let font = UIFont(name: Constants.Font.Normal, size: CGFloat(FontSize)){
            dummyLabel.font = font
        }
        dummyLabel.text = afterSalesHistoryData.historyDetails
        dummyLabel.sizeToFit()
        
        return dummyLabel.frame.size
    }
    
    class func getSizeAfterSalesHistoryCell(_ afterSalesHistoryData: AfterSalesHistoryData, cellWidth: CGFloat) -> CGSize {
        let cellBasicHeight = SubjectLabelTopPadding + SubjectLabelBottomLineTopPadding + DetailLabelTopPadding + (LabelHeight * 2)
        let sizeDetailLabel = getSizeDetailLabel(afterSalesHistoryData, cellWidth: cellWidth)
        let paddingBottomContent: CGFloat = 5 //more space at the bottom of cell
        var moreHeightForBottomStatus: CGFloat = 0
        var moreHeightForPhotoList: CGFloat = 0
        
        if !afterSalesHistoryData.historyStatus.isEmpty {
            moreHeightForBottomStatus = LabelHeight
        }
        
        if afterSalesHistoryData.photoList.count > 0 {
            moreHeightForPhotoList = AfterSalesHistoryCell.getHeightPhotoListView(cellWidth: cellWidth)
        }
        
        return CGSize(width: cellWidth, height: sizeDetailLabel.height + cellBasicHeight + moreHeightForBottomStatus + moreHeightForPhotoList + paddingBottomContent)
    }
}
