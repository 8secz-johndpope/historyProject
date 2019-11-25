//
//  ImagePreviewViewController.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
protocol ImagePreviewViewControllerDelegate: NSObjectProtocol{
    func didChooseImage(_ image : UIImage)
}
class ImagePreviewViewController: MmViewController {
    
    private var titleTextAttributes : [NSAttributedStringKey: Any]!
    private var navigationBGImage : UIImage!
    private var navigationShadowImage : UIImage!
    private var navigationTranslucent : Bool = false
    private var navigationBGColor : UIColor!
    weak var delegate: ImagePreviewViewControllerDelegate?
    var image: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.collectionView.backgroundColor = UIColor.black
        
        self.createBackButton(.whiteColor)
        self.createRightButton(String.localize("LB_OK"), action: #selector(ImagePreviewViewController.okButtonTapped))
        if let rightButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton{
            rightButton.setTitleColor(UIColor.white, for: UIControlState())
        }
        self.collectionView.register(DescCollectCell.self, forCellWithReuseIdentifier: "DescCollectCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = ""
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.backupNavigationBar()
        self.setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.revertNavigationBar()
    }
    
    //MARK: Collection View methods and delegates
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    //MARK: Draw Cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DescCollectCell", for: indexPath) as! DescCollectCell
        cell.backgroundColor = UIColor.clear
        cell.descImageView.image = self.image
        cell.descImageView.contentMode = .scaleAspectFit
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            if image != nil {
                return CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height - App.screenStatusBarHeight - self.navigationController!.navigationBar.frame.size.height)
            } else {
                return CGSize(width: self.view.frame.size.width,height: self.view.frame.size.width)
            }
    }
    
    //MARK: Navigation Bar methods
    func backupNavigationBar() {
        if let titleText = self.navigationController!.navigationBar.titleTextAttributes {
            titleTextAttributes = titleText
        }
        navigationBGImage = self.navigationController!.navigationBar.backgroundImage(for: UIBarMetrics.default)
        navigationShadowImage = self.navigationController!.navigationBar.shadowImage
        navigationTranslucent = self.navigationController!.navigationBar.isTranslucent
        navigationBGColor = self.navigationController!.view.backgroundColor
    }
    func revertNavigationBar() {
        self.navigationController!.navigationBar.titleTextAttributes = titleTextAttributes
        self.navigationController!.navigationBar.setBackgroundImage(navigationBGImage, for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = navigationShadowImage
        self.navigationController!.navigationBar.isTranslucent = navigationTranslucent
        self.navigationController!.view.backgroundColor = navigationBGColor
    }
    func setupNavigationBar() {
        self.navigationController!.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = true
        self.navigationController!.view.backgroundColor = UIColor.clear
        self.navigationItem.setHidesBackButton(false, animated:false);
    }
    @objc func okButtonTapped() {
        if parent != nil {
            parent?.dismiss(animated: true, completion: { () -> Void in
                if self.delegate != nil {
                    self.delegate?.didChooseImage(self.image!)
                }
            })
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
}
