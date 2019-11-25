//
//  ContainerView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 6/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
class ContainerView : UIView{
    func hide(){
        UIView.animate(withDuration: 0.5, animations: {self.backgroundColor = UIColor.black.withAlphaComponent(0.0)}, completion: {(finished : Bool) -> Void in self.isHidden = true})
        
    }
    
    func show(){
        self.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {self.backgroundColor = UIColor.black.withAlphaComponent(0.6)}, completion: nil)
        
    }

}
