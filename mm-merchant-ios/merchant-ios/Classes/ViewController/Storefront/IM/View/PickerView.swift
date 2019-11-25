//
//  PickerView.swift
//  merchant-ios
//
//  Created by HungPM on 5/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class PickerView: UIView, UIPickerViewDelegate, UIPickerViewDataSource {

    private final var title: String!
    private final var doneButonText: String!
    var dataSource: [String]!
    private final var titleLabel: UILabel!

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    
    var doneButtonHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel = UILabel(frame:CGRect(x: 0, y: 0, width: Constants.ScreenSize.SCREEN_WIDTH, height: toolbar.frame.height))
        titleLabel.formatSize(14)
        titleLabel.textAlignment = .center
        titleLabel.text = title ?? ""
        toolbar.addSubview(titleLabel)
        
        confirmButton.title = doneButonText ?? ""
        
        let separatorView  = UIView(frame:CGRect(x: 0, y: toolbar.frame.height - 1, width: Constants.ScreenSize.SCREEN_WIDTH, height: 1))
        separatorView.backgroundColor = UIColor.secondary1()
        toolbar.addSubview(separatorView)
    }
    
    func configPickerViewWithTitle(_ title: String, doneButonText: String, dataSource: [String]) {
        self.title = title
        self.doneButonText = doneButonText
        self.dataSource = dataSource
        
        titleLabel.text = title
        confirmButton.title = doneButonText 
        
        picker.reloadAllComponents()
    }
    
    //MARK: UIPickerView DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource.count
    }
    
    //MARK: UIPickerView Delegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return dataSource[row]
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        doneButtonHandler?()
    }
}
