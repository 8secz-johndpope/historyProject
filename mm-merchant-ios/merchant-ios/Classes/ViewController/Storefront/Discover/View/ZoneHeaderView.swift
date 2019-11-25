//
//  ZoneHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong on 12/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class ZoneHeaderView: UIView {
    
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var sortLabel: UILabel!
    @IBOutlet weak var productCountLabel: UILabel!
    @IBOutlet weak var categoryShortcutView: CategoryShortcutView!
    
    @IBAction func filterTapGestureAction(_ sender: Any) {
        didSelectFilter?(self)
    }
    
    @IBAction func sortTapGestureAction(_ sender: Any) {
        didSelectSort?(self)
    }
    
    var didSelectFilter: ((ZoneHeaderView) -> ())?
    var didSelectSort: ((ZoneHeaderView) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        filterLabel.text = ""
        filterLabel.font = UIFont.fontWithSize(Int(14), isBold: false)
        filterLabel.textColor = UIColor.secondary3()
        
        sortLabel.text = ""
        sortLabel.font = UIFont.fontWithSize(Int(14), isBold: false)
        sortLabel.textColor = UIColor.secondary3()
        
        productCountLabel.text = ""
        productCountLabel.font = UIFont.fontWithSize(Int(14), isBold: false)
        productCountLabel.textColor = UIColor.secondary3()
    }
}
