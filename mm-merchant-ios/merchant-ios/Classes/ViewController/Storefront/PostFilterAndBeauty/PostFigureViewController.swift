//
//  AliImageReshapeController.swift
//  ImageDemo
//
//  Created by Leslie Zhang on 2017/10/17.
//  Copyright © 2017年 Leslie Zhang. All rights reserved.
//

import UIKit
import SnapKit

// 裁切类型
enum FigrueStyleType:Int {
    case DEFAULT = 0
    case LCD = 1
    case HD = 2
}

class PostFigureViewController: UIViewController,UIScrollViewDelegate {
    
    var sourceImage:UIImage?
    var selectImage: ((UIImage,CGRect) -> ())?
    var selectImageRect: ((CGRect) -> ())?
    var showImageView:UIImageView?
    var showScrollView:UIScrollView = UIScrollView()
    var showFrameView:UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configUI(style: .DEFAULT)
    }
    
    func configUI(style:FigrueStyleType) {
        self.automaticallyAdjustsScrollViewInsets = false
        
        view.backgroundColor = UIColor.black
        
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.maximumZoomScale = 2.0
        scrollView.minimumZoomScale = 1.0
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        scrollView.delegate = self
        
        let frameView = UIImageView()
        frameView.layer.borderWidth = 2.0
        frameView.layer.borderColor = UIColor.white.cgColor
        frameView.backgroundColor = UIColor.clear
        if style == .DEFAULT {
            frameView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenWidth)
            frameView.center.x = view.center.x
            frameView.center.y = (ScreenHeight - 142)/2
        }else if style == .LCD{
            frameView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: ScreenWidth / 4 * 3)
            frameView.center.x = view.center.x
            frameView.center.y = (ScreenHeight - 142)/2
        }else if style == .HD{
            frameView.frame = CGRect()
            frameView.frame = CGRect(x: 0, y: 0, width:(ScreenHeight - 142) / 16 * 9 , height: ScreenHeight - 142)
            frameView.center.x = view.center.x
            frameView.center.y = (ScreenHeight - 142)/2
        }
        view.addSubview(frameView)
        
        let shapeView = ALiImageShapeView()
        shapeView.backgroundColor = UIColor.clear
        shapeView.isUserInteractionEnabled = false
        shapeView.frame = view.bounds
        view.addSubview(shapeView)
        
        if let sourceImage = sourceImage {
            let imageView = UIImageView()
            imageView.contentMode = UIViewContentMode.scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.image = sourceImage
            imageView.frame = CGRect(x: 0, y: 0, width: sourceImage.size.width, height: sourceImage.size.height)
            let imageSize = sourceImage.size
            scrollView.frame = view.bounds
            scrollView.contentSize = imageSize
            scrollView.addSubview(imageView)
            
            showImageView = imageView
            var scale:CGFloat = 0.0
            
            let cropBoxSize = frameView.bounds.size
            
            if cropBoxSize.width/imageSize.width > cropBoxSize.height/imageSize.height{
                scale = cropBoxSize.width/imageSize.width
            }else{
                scale = cropBoxSize.height/imageSize.height
                
            }
            
            let scaledSize = CGSize(width: floor(imageSize.width * scale), height: floor(imageSize.height * scale))
            
            scrollView.minimumZoomScale = scale
            scrollView.maximumZoomScale = 5.0
            
            scrollView.zoomScale = scrollView.minimumZoomScale
            scrollView.contentSize = scaledSize
            
            let cropBoxFrame:CGRect = frameView.frame
            
            if (cropBoxFrame.size.width < scaledSize.width - CGFloat(Float.ulpOfOne) ||
                cropBoxFrame.size.height < scaledSize.height - CGFloat(Float.ulpOfOne)) {
                
                var offset = CGPoint.zero
                offset.x = -floor((scrollView.frame.width - scaledSize.width) * 0.5)
                offset.y = -floor((scrollView.frame.height - scaledSize.height) * 0.5)
                scrollView.contentOffset = offset
            }
            scrollView.contentInset = UIEdgeInsets(top: cropBoxFrame.minY, left: cropBoxFrame.minX, bottom: view.bounds.maxY - cropBoxFrame.maxY, right: view.bounds.maxX - cropBoxFrame.maxX)
            
            showFrameView =  frameView
            showScrollView = scrollView
        }
        
        shapeView.shapePath = UIBezierPath(rect: frameView.frame)
        shapeView.coverColor = UIColor(white: 0, alpha: 0.7)
        shapeView.setNeedsDisplay()
        
        let whiteView = UIView(frame: CGRect(x: 0, y: ScreenHeight - 142 - ScreenBottom, width: ScreenWidth, height: 142 + ScreenBottom))
        whiteView.backgroundColor = UIColor.white
        
        let cancelButton = UIButton()
        cancelButton.setImage(UIImage(named: "close_ic"), for: UIControlState.normal)
        cancelButton.addTarget(self, action: #selector(cancelDidClick), for:UIControlEvents.touchUpInside)
        cancelButton.sizeToFit()
        
        let doneButton = UIButton()
        doneButton.setImage(UIImage(named: "right_ic"), for: UIControlState.normal)
        doneButton.addTarget(self, action: #selector(selectDidClick), for:UIControlEvents.touchUpInside)
        doneButton.sizeToFit()
        
        let titleLabel = UILabel()
        titleLabel.text = "裁切"
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        
        let defaultRatioButton = UIButton()
        defaultRatioButton.setImage(UIImage(named: "11_grey"), for: UIControlState.normal)
        defaultRatioButton.setImage(UIImage(named: "11_black"), for: UIControlState.selected)
        defaultRatioButton.setTitle("1:1", for: UIControlState.normal)
        defaultRatioButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        defaultRatioButton.titleLabel?.textAlignment = .center
        defaultRatioButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        defaultRatioButton.setTitleColor(UIColor.black, for: UIControlState.selected)
        defaultRatioButton.sizeToFit()
        defaultRatioButton.setIconInTopWithSpacing(6)
        defaultRatioButton.addTarget(self, action:  #selector(touchDefaultRatioButton), for: UIControlEvents.touchUpInside)
        
        let lcdRatioButton = UIButton()
        lcdRatioButton.setImage(UIImage(named: "34_grey"), for: UIControlState.normal)
        lcdRatioButton.setImage(UIImage(named: "34_black"), for: UIControlState.selected)
        lcdRatioButton.setTitle("3:4", for: UIControlState.normal)
        lcdRatioButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        lcdRatioButton.titleLabel?.textAlignment = .center
        lcdRatioButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        lcdRatioButton.setTitleColor(UIColor.black, for: UIControlState.selected)
        lcdRatioButton.sizeToFit()
        lcdRatioButton.setIconInTopWithSpacing(6)
        lcdRatioButton.addTarget(self, action:  #selector(touchLcdRatioButton), for: UIControlEvents.touchUpInside)
        
        let hdRatioButton = UIButton()
        hdRatioButton.setImage(UIImage(named: "169_grey"), for: UIControlState.normal)
        hdRatioButton.setImage(UIImage(named: "169_black"), for: UIControlState.selected)
        hdRatioButton.setTitle("16:9 ", for: UIControlState.normal)
        hdRatioButton.contentMode = .left
        hdRatioButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        hdRatioButton.titleLabel?.textAlignment = .center
        hdRatioButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        hdRatioButton.setTitleColor(UIColor.black, for: UIControlState.selected)
        hdRatioButton.sizeToFit()
        hdRatioButton.setIconInTopWithSpacing(6)
        hdRatioButton.addTarget(self, action:  #selector(touchHdRatioButton), for: UIControlEvents.touchUpInside)
        
        if style == .DEFAULT {
            defaultRatioButton.isSelected = true
            defaultRatioButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        }else if style == .LCD{
            lcdRatioButton.isSelected = true
            lcdRatioButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        }else if style == .HD{
            hdRatioButton.isSelected = true
            hdRatioButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        }
        
        view.addSubview(whiteView)
        whiteView.addSubview(cancelButton)
        whiteView.addSubview(doneButton)
        whiteView.addSubview(titleLabel)
        whiteView.addSubview(defaultRatioButton)
        whiteView.addSubview(lcdRatioButton)
        whiteView.addSubview(hdRatioButton)
        
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalTo(whiteView).offset(10)
            make.bottom.equalTo(whiteView).offset(-4 - ScreenBottom)
            make.width.height.equalTo(50)
        }
        
        doneButton.snp.makeConstraints { (make) in
            make.right.equalTo(whiteView).offset(-10)
            make.width.height.bottom.equalTo(cancelButton)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView)
            make.bottom.equalTo(whiteView).offset(-18 - ScreenBottom)
        }
        
        defaultRatioButton.snp.makeConstraints { (make) in
            make.top.equalTo(whiteView).offset(26)
            make.centerX.equalTo(whiteView).offset(-ScreenWidth/4)
            make.width.height.equalTo(50)
        }
        lcdRatioButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView)
            make.centerY.equalTo(defaultRatioButton)
            make.width.height.equalTo(50)
        }
        hdRatioButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(defaultRatioButton)
            make.centerX.equalTo(whiteView).offset(ScreenWidth/4)
            make.width.equalTo(50)
            make.height.equalTo(70)
        }
    }
    
    
    func imageCropFrame() -> CGRect{
        let imageSize = showImageView!.image?.size
        let contentSize = showScrollView.contentSize
        let cropBoxFrame = showFrameView.frame
        let contentOffset = showScrollView.contentOffset
        let edgeInsets = showScrollView.contentInset
        
        var frame = CGRect.zero
        
        frame.origin.x = floor(contentOffset.x + edgeInsets.left) * (imageSize!.width / contentSize.width);
        frame.origin.x = max(0, frame.origin.x);
        frame.origin.y = floor((contentOffset.y + edgeInsets.top) * (imageSize!.height / contentSize.height));
        frame.origin.y = max(0, frame.origin.y);
        frame.size.width = ceil(cropBoxFrame.size.width * (imageSize!.width / contentSize.width));
        frame.size.width = min(imageSize!.width, frame.size.width);
        frame.size.height = ceil(cropBoxFrame.size.height * (imageSize!.height / contentSize.height));
        frame.size.height = min(imageSize!.height, frame.size.height);
        
        return frame
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
         return showImageView!
    }
    
    @objc func shapeImage() -> UIImage {
        return (showImageView!.image?.crop(bounds: imageCropFrame()))!
    }
    
    //    func scale() -> CGFloat {
    //        return 1
    //    }
    
    @objc func touchDefaultRatioButton()  {
        for v in view.subviews {
            v.removeFromSuperview()
        }
        
        configUI(style: .DEFAULT)
    }
    
    @objc func touchLcdRatioButton()  {
        for v in view.subviews {
            v.removeFromSuperview()
        }
        
        configUI(style: .LCD)
    }
    
    @objc func touchHdRatioButton()  {
        for v in view.subviews {
            v.removeFromSuperview()
        }
        configUI(style: .HD)
    }
    
    @objc func cancelDidClick(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func selectDidClick()  {
        
        if let selectImage = selectImage {
            selectImage(shapeImage(),imageCropFrame())
            self.dismiss(animated: true, completion: nil)
        }
    }
}
