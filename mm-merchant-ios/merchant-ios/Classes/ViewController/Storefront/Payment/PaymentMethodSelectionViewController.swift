//  PaymentMethodSelectionViewController.swift
//  merchant-ios
//
//  Created by HungPM on 2/25/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

class PaymentMethod {
    var image: UIImage
    var title: String
    var selected: Bool
    
    init(image: UIImage, title: String, selected: Bool = false) {
        self.image = image
        self.title = title
        self.selected = selected
    }
}

protocol PaymentMethodSelectionViewControllerDelegate: class {
    func didSelectPayment(_ paymentIndex: Int, paymentName: String)
}

class PaymentMethodSelectionViewController : MmViewController {
    
    private final let PaymentSelectionCellID = "PaymentSelectionCellID"
    private final let DefaultCellID = "DefaultCellID"
    
    private final let TopGapViewHeight = CGFloat(11)
    private final let ButtonViewHeight = CGFloat(64)
    
    var order : ParentOrder?
    var timer : Timer?
    
    var rowSelected = 0
    var retryCount = 0
    
    private var dataSource:[PaymentMethod]?
    
    private var buttonConfirm : UIButton!
    var isSwipeToPay = false
    weak var delegate : PaymentMethodSelectionViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.isNavigationBarHidden = false
        
        self.view.backgroundColor = UIColor.backgroundGray()
        self.title = String.localize("LB_CA_ORDER_CONFIRMATION")
        
        dataSource = [
            PaymentMethod(image: UIImage(named: "alipay_icon")!, title: String.localize("LB_CA_PAY_VIA_ALIPAY"), selected: true),
            //PaymentMethod(image: UIImage(named: "cod_icon")!, title: "货到付款", selected: false)
        ]
        if let dataSource = self.dataSource {
            dataSource[rowSelected].selected = true
        }
        setupNavigationBar()
        
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: self.DefaultCellID)
        
        self.collectionView!.register(PaymentSelectionCell.self, forCellWithReuseIdentifier: self.PaymentSelectionCellID)
        self.collectionView.backgroundColor = UIColor.clear
        
        let buttonView = { () -> UIView in
            
            let frame = CGRect(x: 0, y: self.collectionView.frame.maxY, width: self.collectionView.frame.width, height: ButtonViewHeight)
            
            let view = UIView(frame: frame)
            view.backgroundColor = UIColor.white
            
            let confirmButton = { () -> UIButton in
                
                let marginTop = CGFloat(12)
                let marginRight = CGFloat(15)
                let buttonSize = CGSize(width: 96, height: 41)
                
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: frame.width - marginRight - buttonSize.width, y: marginTop, width: buttonSize.width, height: buttonSize.height)
                button.setTitle(String.localize("LB_CA_CONFIRM_PAYMENT"), for: UIControlState())
                button.addTarget(self, action: #selector(PaymentMethodSelectionViewController.confirmButtonTapped), for: .touchUpInside)
                button.layer.cornerRadius = 3.0
                button.formatPrimary()
                return button
            } ()
            view.addSubview(confirmButton)
            self.buttonConfirm = confirmButton
            
            let labelPrice = { () -> UILabel in
                let marginLeft = CGFloat(22)
                
                let label = UILabel(frame: CGRect(x: marginLeft, y: 0, width: confirmButton.frame.minX - marginLeft, height: frame.height))
                
                let priceText = NSMutableAttributedString()
                
                let textFont = UIFont.systemFont(ofSize: 14)
                let valueFont = UIFont.systemFont(ofSize: 15)
                
                let text = NSAttributedString(
                    string: String.localize("LB_CA_TOTAL") + "：",
                    attributes: [
                        NSAttributedStringKey.foregroundColor: UIColor(hexString: "#8e8e8e"),
                        NSAttributedStringKey.font: textFont
                    ]
                )
                priceText.append(text)
                if let order = self.order {
                    let value = NSAttributedString(
                        string: order.grandTotal.formatPrice() ?? "",
                        attributes: [
                            NSAttributedStringKey.foregroundColor: UIColor.secondary2(),
                            NSAttributedStringKey.font: valueFont,
                            NSAttributedStringKey.baselineOffset: (textFont.capHeight - valueFont.capHeight) / 2
                        ]
                    )
                    priceText.append(value)
                }
                
                label.attributedText = priceText
                
                return label
            } ()
            view.addSubview(labelPrice)
            
            return view
        } ()
        
        self.view.addSubview(buttonView)
    }
    
    func setupNavigationBar() {
        self.createBackButton()
    }
    
    //MARK: Actions
    @objc func confirmButtonTapped() {
        buttonConfirm.isUserInteractionEnabled = false
        
        if let delegate = self.delegate {
            if let dataSource = self.dataSource {
                delegate.didSelectPayment(rowSelected, paymentName: dataSource[rowSelected].title)
            }
            self.navigationController?.popViewController(animated: true)
            
        } else {
            switch rowSelected {
            case 0:
                if let order = self.order {
                    AliPayManager.pay(self, parentOrder: order, callback: {success, error in
                        if success{
                            self.timer = Timer.scheduledTimer(timeInterval: Constants.Duration.AliPay, target: self, selector: #selector(PaymentMethodSelectionViewController.pollOrderStatus), userInfo: nil, repeats: true)
                            self.retryCount = 0
                            self.showLoading()
                        } else {
                            Alert.alert(self, title: error, message: error)
                            self.buttonConfirm.isUserInteractionEnabled = true
                        }
                    })
                    
                }
                break
            case 1:
                confirmOrder()
            default:
                break
                
            }}
    }
    
    func confirmOrder(){
        if let order = self.order {
            
            firstly {
                return confirmOrderStatus(order)
                }.then { _ -> Void in
                    self.showThankYou()
            }
            
        }
    }
    
    @objc func pollOrderStatus(){
        retryCount += 1
        if retryCount > 30 {
            retryCount = 0
            self.stopLoading()
            if let timer = self.timer {
                timer.invalidate()
            }
        }
        if let order = self.order {
            
            firstly {
                return getOrderStatus(order)
                }.then { _ -> Void in
                    if order.parentOrderStatusId == 2 {
                        if let timer = self.timer {
                            timer.invalidate()
                            self.timer = nil
                            self.showThankYou()
                        }
                    }
                    
            }
        }
        
    }
    
    func getOrderStatus(_ order : ParentOrder) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.viewMeta(order.parentOrderKey) {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                                strongSelf.order = order
                            }
                            
                            fulfill("OK")
                        }
                        else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    }
                    else{
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    func confirmOrderStatus(_ order : ParentOrder) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.confirmOrder(order.parentOrderKey) { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        fulfill("OK")
                    }
                    else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                }
                else{
                    reject(response.result.error!)
                }
            }
        }
    }
    
    func showThankYou(){
        let thankYouViewController = ThankYouViewController()
        thankYouViewController.fromViewController = self
        thankYouViewController.parentOrder = self.order
        let navigationController = MmNavigationController(rootViewController: thankYouViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        thankYouViewController.handleDismiss = {
            self.navigationController?.popToRootViewController(animated: true)
        }
        self.present(navigationController, animated: false, completion: nil)
        self.stopLoading()
        
    }
    
    //MARK: CollectionView
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
            
        case self.collectionView!:
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PaymentSelectionCellID, for: indexPath)
            
            if type(of: cell) == PaymentSelectionCell.self {
                let itemCell = cell as! PaymentSelectionCell
                if let dataSource = self.dataSource {
                    itemCell.paymentMethod = dataSource[indexPath.row]

                } else {
                    itemCell.paymentMethod = nil
                    itemCell.selectHandler = nil
                }
            }
            
            return cell
            
        default:
            return self.defaultCell(collectionView, cellForItemAt: indexPath)
        }
        
    }
    
    func defaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case self.collectionView!:
            return CGSize(width: self.view.frame.size.width, height: PaymentCellHeight)
        default:
            return CGSize.zero
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        rowSelected = indexPath.row
        if let dataSource = self.dataSource {
            for data in dataSource {
                data.selected = false
            }
            dataSource[rowSelected].selected = true
        }
        collectionView.reloadData()
    }
    
    //MARK: View Config
    // config tab bar

    override func collectionViewBottomPadding() -> CGFloat {
        return ButtonViewHeight
    }
    
    override func collectionViewTopPadding() -> CGFloat {
        return TopGapViewHeight
    }
}
