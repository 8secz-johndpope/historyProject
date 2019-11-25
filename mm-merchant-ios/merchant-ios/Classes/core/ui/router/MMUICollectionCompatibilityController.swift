//
//  MMUICollectionCompatibilityController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/24.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMUICollectionCompatibilityController<T: MMCellModel>: MmViewController,MMCollectionViewDelegate,MMFetchsControllerDelegate {
    
    var layout:MMCollectionViewLayout { get {return _layout } }
    var table: UICollectionView { get {return _table } }
    var fetchs: MMFetchsController<T> { get {return _fetchs } }
    
    override func loadView() {
        self.view = UIView(frame:UIScreen.main.bounds)
        _layout = MMCollectionViewLayout(loadLayoutConfig())
        _table = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        _table.delegate = self
        _table.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        _table.backgroundColor = UIColor.white
        self.view.addSubview(_table)
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    ///  Derived class implements.
    public func loadLayoutConfig() -> MMLayoutConfig { return MMLayoutConfig() }
    public func loadFetchs() -> [MMFetch<T>] {
        /*
         /// realm fetch create
         let realm = try! Realm()
         let vs = realm.objects(Dog.self)
         let ff = vs.sorted(byKeyPath: "breed", ascending: true)
         let f = MMFetchRealm(result:ff,realm:realm)
         
         ///
         //let f = MMFetchList(list:initDataList())
         
         return [f]
         */
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _fetchs = MMFetchsController(fetchs: loadFetchs())
        _fetchs.defaultAnimated = false
        _fetchs.delegate = self
        _table.dataSource = _fetchs
        _table.performBatchUpdates({
            //nothing
        }, completion: nil)
        
    }
    
    deinit {
        _table?.dataSource = nil
        _table?.delegate = nil
    }
    
    // MARK:- UICollectionViewDelegate MMCollectionViewDelegate 代理
    @objc func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击了\(indexPath.row) section:\(indexPath.section)")
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    //可以漂浮停靠在界面顶部
    @objc func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool {
        guard let m = _fetchs.object(at: indexPath) else {
            return false
        }
        return m.ssn_canFloating()
    }
    
    //cell的行高,若scrollDirection == .horizontal则返回的是宽度
     @objc  func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat {
        if _layout.config.rowHeight > 0 {
            return layout.config.rowHeight
        }
        guard let m = _fetchs.object(at: indexPath) else {
            return 44
        }
        return m.ssn_cellHeight()
    }
    
   @objc func collectionView(_ collectionView: UICollectionView, insetsForCellAt indexPath: IndexPath) -> UIEdgeInsets {
        guard let m = _fetchs.object(at: indexPath) else {
            return UIEdgeInsets.zero
        }
        return m.ssn_cellInsets()
    }
    
    //cell是否SpanSize，返回值小于等于零时默认为1
    @objc func collectionView(_ collectionView: UICollectionView, spanSizeForCellAt indexPath: IndexPath) -> Int {
        guard let m = _fetchs.object(at: indexPath) else {
            return 1
        }
        if m.ssn_canFloating() || m.ssn_isExclusiveLine() {
            return _layout.config.columnCount
        }
        return m.ssn_cellGridSpanSize()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    /// MARK MMFetchsControllerDelegate
    func ssn_controller(_ controller: AnyObject, deletes: [IndexPath]?, inserts: [IndexPath]?, updates: [IndexPath]?) {
        //
    }
    
    public func ssn_controllerWillChangeContent(_ controller: AnyObject) {}
    
    public func ssn_controllerDidChangeContent(_ controller: AnyObject) {}
    
    private var _layout:MMCollectionViewLayout!
    private var _table : UICollectionView!
    private var _fetchs : MMFetchsController<T>!
    
}
