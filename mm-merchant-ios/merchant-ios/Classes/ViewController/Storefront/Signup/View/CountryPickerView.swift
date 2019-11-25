//
//  CountryPickerView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol PickerViewDelegate : UIPickerViewDelegate{
    func didClickComplete()
}

class CountryPickerView: UIView {
    private var viewHeader = UIView()
    private var buttonComplete = UIButton()
    private final let ButtonCompleteWidth : CGFloat = 70
    private final let ButtonCompleteHeight : CGFloat = 30
    var countryPicker = UIPickerView()
    weak var delegate : PickerViewDelegate? {
        didSet {
            self.countryPicker.delegate = self.delegate
        }
    }
    weak var dataSource : UIPickerViewDataSource? {
        didSet {
            self.countryPicker.dataSource = self.dataSource
        }
    }
    override init(frame: CGRect) {
        var strongFrame = frame
        if strongFrame.height == 0 {
            strongFrame.size.width = ScreenWidth
            strongFrame.size.height = 246
        }
        super.init(frame: strongFrame)
        self.viewHeader.backgroundColor = UIColor.white
        self.buttonComplete.setTitle(String.localize("LB_DONE"), for: UIControlState())
        self.buttonComplete.titleLabel?.formatSmall()
        self.buttonComplete.setTitleColor(UIColor.primary1(), for: UIControlState())
        self.buttonComplete.addTarget(self, action: #selector(CountryPickerView.didClickCompleteButton), for: UIControlEvents.touchUpInside)
        self.viewHeader.addSubview(self.buttonComplete)
        self.addSubview(countryPicker)
        self.addSubview(self.viewHeader)
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.countryPicker.frame = CGRect(x: 0,y: ButtonCompleteHeight,width: frame.width,height: frame.height - ButtonCompleteHeight)
        self.bringSubview(toFront: self.buttonComplete)
        self.viewHeader.frame = CGRect (x: 0,y: 0,width: self.bounds.width,height: ButtonCompleteHeight)
        self.buttonComplete.frame = CGRect (x: self.viewHeader.frame.width - ButtonCompleteWidth,y: 0,width: ButtonCompleteWidth,height: ButtonCompleteHeight)
    }
    
    @objc func didClickCompleteButton(_ sender: UIButton) {
        self.delegate?.didClickComplete()
    }
    
    func reloadAllComponents() {
        self.countryPicker.reloadAllComponents()
    }
    
    func selectRow(_ row: Int, inComponent component: Int, animated: Bool) {
        self.countryPicker.selectRow(row, inComponent: 0, animated: animated)
    }
    
    @discardableResult
    func selectedRowInComponent(_ component: Int) -> Int {
        return self.countryPicker.selectedRow(inComponent: component)
    }
}
