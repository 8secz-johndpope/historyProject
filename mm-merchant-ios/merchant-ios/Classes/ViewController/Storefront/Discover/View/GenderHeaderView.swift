//
//  GenderHeaderView.swift
//  merchant-ios
//
//  Created by Gam Bogo on 7/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

protocol GenderHeaderViewDelegate: NSObjectProtocol {
    func didSelectGender(_ genderType: GenderHeaderView.GenderType)
}

class GenderHeaderView : UICollectionReusableView {
    
    static let viewIdentifier: String = "GenderHeaderViewID"
    
    private var genderFemaleView: GenderView!
    private var genderMaleView: GenderView!
    private var selectedGenderView: GenderView!
    weak var delegate: GenderHeaderViewDelegate?
    
    enum GenderType: Int {
        case male = 1
        case female = 2
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupGenderViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGenderViews() {
        
        let tapFemaleGenderGesture = UITapGestureRecognizer(target: self, action: #selector(GenderHeaderView.genderPressed))
        genderFemaleView = GenderView(frame: CGRect(x: 0, y: 0, width: self.frame.sizeWidth / 2, height: self.frame.sizeHeight))
        genderFemaleView.genderLabel.text = String.localize("LB_CA_CAT_F")
        genderFemaleView.addGestureRecognizer(tapFemaleGenderGesture)
        genderFemaleView.tag = GenderType.female.rawValue
        self.addSubview(genderFemaleView)
        
        let tapMaleGenderGesture = UITapGestureRecognizer(target: self, action: #selector(GenderHeaderView.genderPressed))
        genderMaleView = GenderView(frame: CGRect(x: genderFemaleView.frame.maxX, y: 0, width: self.frame.sizeWidth / 2, height: self.frame.sizeHeight))
        genderMaleView.genderLabel.text = String.localize("LB_CA_CAT_M")
        genderMaleView.addGestureRecognizer(tapMaleGenderGesture)
        genderMaleView.tag = GenderType.male.rawValue
        self.addSubview(genderMaleView)
    }
    
    //MARK: - Gender
    func setSelectedGender(genderType: GenderType) {
        let isSelectedFemale = (genderType.rawValue == GenderType.female.rawValue)
        selectedGenderView = isSelectedFemale ? genderFemaleView : genderMaleView
        genderFemaleView.genderImageView.image = UIImage(named: isSelectedFemale ? "woman_selected" : "woman_not_selected")
        genderFemaleView.backgroundView.isHidden = !isSelectedFemale
        genderMaleView.genderImageView.image = UIImage(named: !isSelectedFemale ? "man_selected" : "man_not_selected")
        genderMaleView.backgroundView.isHidden = isSelectedFemale
    }
    
    @objc func genderPressed (_ sender: UITapGestureRecognizer?) {
        
        if let tapGesture = sender {
            if selectedGenderView == tapGesture.view {
                return
            }
            
            if let genderView = tapGesture.view as? GenderView {
                if let genderType = GenderType(rawValue: genderView.tag) {
                    setSelectedGender(genderType: genderType)
                    delegate?.didSelectGender(genderType)
                }
            }
        }
    }
    
}

class GenderView: UIView {
    
    var genderImageView: UIImageView!
    var genderLabel: UILabel!
    var backgroundView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let paddingImageView: CGFloat = 5
        genderImageView = UIImageView(frame: CGRect(x: paddingImageView, y: paddingImageView, width: frame.sizeWidth - 2 * paddingImageView, height: frame.sizeHeight - 2 * paddingImageView))
        genderImageView.contentMode = .scaleAspectFill
        genderImageView.clipsToBounds = true
        addSubview(genderImageView)
        
        backgroundView = UIView(frame: CGRect(x: 0, y: genderImageView.height - 28, width: 76, height: 28))
        addSubview(backgroundView)
        
        genderLabel = UILabel(frame: backgroundView.frame)
        genderLabel.formatSize(26)
        genderLabel.textAlignment = .center
        genderLabel.textColor = UIColor.white
        addSubview(genderLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
