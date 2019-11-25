//
//  AddressSelectionViewController.swift
//  merchant-ios
//
//  Created by hungvo on 2/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class AddressSelectionViewController: MmViewController {
    
    private final let AddressSelectionCellID = "AddressSelectionCellID"
    private final let AddressHeaderViewID = "AddressHeaderViewID"
    private final let DefaultCellID = "DefaultCellID"
    
    private var headerView: UIView?
    
    private var selectionAddreses = [Address] (){
        didSet{
            layoutSubViews()
        }
    }
    
    var selectedAddress: Address?
    var continueCheckoutProcess = false
    var didSelectAddress: ((Address) -> ())?
    
    //To know current view mode of view
    //If viewMode == Profile it means user can DELETE/ADD/EDIT/SELECT Default Addresses
    var viewMode: SignupMode = .normal
    
    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray
        return view
    } ()
    
    private var isNavigatedToAddressAdditionViewController: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.isNavigationBarHidden = false
        
        setupNavigationBar()
        setupHeaderView()
        setupCollectionViews()
        
		self.createBottomButton(String.localize("LB_CA_ADD_ADDR"), customAction: #selector(AddressSelectionViewController.addNewAddress))
        self.navigationController?.isNavigationBarHidden = false
        
        var title = ""
        if viewMode != .profile {
            title = String.localize("LB_CA_MY_ADDRESS")
            self.initAnalyticLog()
        }
        else{
            title = String.localize("LB_CA_MANAGE_SHIPPING_ADDR")
        }
        self.title = title
        
        view.addSubview(lineView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        self.loadListAddresses()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutSubViews()
    }
    
    override func backButtonClicked(_ button: UIButton) {
        self.popViewController()
    }
    
    override func collectionViewBottomPadding() -> CGFloat {
        return Constants.BottomButtonContainer.Height
    }
    
    func layoutSubViews(){
        let navigationBarHeight: CGFloat = self.navigationController?.navigationBar.height ?? 0
        let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        let headerHeight = (self.viewMode == .profile && selectionAddreses.count > 0) ? CGFloat(30) : CGFloat(0)
        
        headerView?.frame = CGRect(x: 0, y: navigationBarHeight + statusBarHeight, width: view.width, height: headerHeight)
    
        collectionView?.frame = CGRect(
            x: 0,
            y: headerView?.frame.maxY ?? 0,
            width: view.width,
            height: view.height - (self.headerView?.frame.maxY ?? 0) - Constants.BottomButtonContainer.Height - ScreenBottom
        )
        
        lineView.frame = CGRect(x: 0, y: collectionView?.frame.maxY ?? 0 , width: view.width, height: 0.5)
    }
    
    //MARK: - Data Processing
    
    func listAddressItem(completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise { fulfill, reject in
            AddressService.list({ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            if let addreses: Array<Address> = Mapper<Address>().mapArray(JSONObject: response.result.value) {
                                strongSelf.selectionAddreses = addreses
                                if let address = addreses.filter({$0.userAddressKey == strongSelf.selectedAddress?.userAddressKey}).first{
                                    strongSelf.selectedAddress = address
                                }
                            } else {
                                strongSelf.selectionAddreses = [Address]() 
                            }
                            
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    func loadListAddresses() {
        self.showLoading()
        
        firstly {
            return self.loadDefaultAddress()
        }.then { address -> Promise<Any> in
            if self.viewMode == .profile {
                self.selectedAddress = address
            }
            return self.listAddressItem()
        }.then { _ -> Void in
//            self.moveDefaultAddressToTop()
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
            
            if self.selectedAddress == nil && !self.isNavigatedToAddressAdditionViewController {
                self.navigateToAddressAdditionViewController()
            }
        }.catch { error -> Void in
            Log.error("error")
            self.selectedAddress = Address()
            self.selectionAddreses = [Address]()
            self.collectionView.reloadData()
        }
    }
    
    func moveDefaultAddressToTop() {
        if let selectedAddress = self.selectedAddress {
            for address in selectionAddreses {
                if address.userAddressKey == selectedAddress.userAddressKey {
                    selectionAddreses.remove(address)
                    selectionAddreses.insert(address, at: 0)
                    break
                }
            }
        }
    }
    
    func loadDefaultAddress() -> Promise<Address?> {
        return Promise { fulfill, reject in
            AddressService.viewDefault({ [weak self] (response) in
                if let _ = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                                fulfill(address)
                            } else {
                                fulfill(nil)
                            }
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    func saveDefaultAddress(_ userAddressKey :String, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise { fulfill, reject in
            AddressService.saveDefault(userAddressKey) { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    func deleteAddress(_ userAddressKey :String) -> Promise<Any> {
        return Promise { fulfill, reject in
            AddressService.delete(userAddressKey) { (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord( viewDisplayName: "UserAddress-Select",  viewLocation: "UserAddress-Select", viewType: "Checkout")
    }
    
    //MARK: - Views
    
    func createRightMenuItems(indexPath: IndexPath) -> [SwipeActionMenuCellData]? {
        if viewMode == .profile {
            let listItems = [
                SwipeActionMenuCellData(
                    text: String.localize("LB_CA_EDIT"),
                    icon: UIImage(named: "icon_swipe_edit"),
                    backgroundColor: UIColor(hexString: "#E86763"),
                    action: {  [weak self, indexPath] () -> Void in
                        if let strongSelf = self {
                            let currentAddress: Address =  strongSelf.selectionAddreses[indexPath.row]
                            strongSelf.editAddressTapped(address: currentAddress)
                            
                        }
                    }
                ),
                SwipeActionMenuCellData(
                    text: String.localize("LB_CA_DELETE"),
                    icon: UIImage(named: "icon_swipe_delete"),
                    backgroundColor: UIColor(hexString: "#7A848C"),
                    defaultAction: true,
                    action: { [weak self, indexPath] () -> Void in
                        if let strongSelf = self {
                            let currentAddress: Address =  strongSelf.selectionAddreses[indexPath.row]
                                strongSelf.deleteAddressTapped(address: currentAddress)
                        }
                    }
                )
            ]
            
            return listItems
        }
        
        return nil
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
        return cell
    }

    func setupNavigationBar() {
        self.createBackButton()
        if self.viewMode != .profile {
            self.createRightButton(String.localize("LB_CA_MANAGE"), action: #selector(AddressSelectionViewController.didTouchOnRightButton))
        }
    }
    
    @objc func didTouchOnRightButton(_ sender : Any) {
        let addressListViewController = AddressSelectionViewController()
        addressListViewController.viewMode = .profile
        self.navigationController?.push(addressListViewController, animated: true)
    }
    
    func setupHeaderView(){
        let headerHeight = (self.viewMode == .profile && selectionAddreses.count > 0) ? CGFloat(30) : CGFloat(0)
        let headerView = AddressFooterView()
        headerView.backgroundColor = UIColor.backgroundGray()
        headerView.titleLabel.text = String.localize("LB_CA_DEF_SHIP_ADD")
        headerView.frame = CGRect(x: 0, y: 0, width: view.width, height: headerHeight)
        self.headerView = headerView
        view.addSubview(headerView)
    }
    
    func setupCollectionViews() {
        self.collectionView!.backgroundColor = UIColor.white
        if viewMode == .profile {
            self.collectionView!.register(MyAccountAddressSelectionCell.self, forCellWithReuseIdentifier: AddressSelectionCellID)
        }else {
            self.collectionView!.register(CheckoutAddressSelectionCell.self, forCellWithReuseIdentifier: AddressSelectionCellID)
        }
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        self.collectionView!.register(AddressFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: AddressHeaderViewID)
    }
    
    // MARK: - Action Handler
    
    @objc func addNewAddress(_ button: UIButton) {
        navigateToAddressAdditionViewController()
    }
    
    func navigateToAddressAdditionViewController() {
        let addressAdditionViewController = AddressAdditionViewController()
        addressAdditionViewController.signupMode = viewMode
        addressAdditionViewController.continueCheckoutProcess = continueCheckoutProcess
        
        addressAdditionViewController.didAddAddress = { (address) -> Void in
            if let didSelectAddress = self.didSelectAddress {
                didSelectAddress(address)
            }
        }
        
        isNavigatedToAddressAdditionViewController = true
        
        self.navigationController?.push(addressAdditionViewController, animated: true)
    }
    
    private func popViewController() {
        if let didSelectAddress = self.didSelectAddress, let selectedAddress = self.selectedAddress {
            didSelectAddress(selectedAddress)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func editAddressTapped(address:Address) {
        let addressAdditionViewController = AddressAdditionViewController()
        addressAdditionViewController.currentAddressAdditionMode = .change
        addressAdditionViewController.address = address
        
        self.navigationController?.push(addressAdditionViewController, animated: true)
    }
    
    func deleteAddressTapped(address:Address) {
        let okActionTapped = { () -> Void in
            self.showLoading()
            
            //In case default address deleted by user, we will automatically select first index of the list
            var shouldSelectFirstAddress = false
            
            if let selectedAddress = self.selectedAddress {
                if selectedAddress.userAddressKey == address.userAddressKey && self.selectionAddreses.count > 1{
                    shouldSelectFirstAddress = true
                }
            }
            
            firstly {
                return self.deleteAddress(address.userAddressKey)
            }.then { _ -> Promise<Any> in
                return self.listAddressItem()
            }.then { _ -> Void in
                if shouldSelectFirstAddress && self.selectionAddreses.count > 0 {
                     let firstAddress: Address = self.selectionAddreses[0]
                        firstly{
                            return self.saveDefaultAddress(firstAddress.userAddressKey)
                        }.then { _ -> Void in
                            self.selectedAddress = firstAddress
                            self.collectionView.reloadData()
                            self.stopLoading()
                        }.catch { _ -> Void in
                            Log.error("error")
                        }
                   
                } else {
                    self.collectionView.reloadData()
                    self.stopLoading()
                }
            }.catch { _ -> Void in
                Log.error("error")
            }
        }
        
        Alert.alert(self, title: "", message: String.localize("MSG_CA_CONFIRM_REMOVE_ADDR"), okActionComplete: { () -> Void in
            okActionTapped()
        }, cancelActionComplete: nil)
    }
    
    func setDefaultAddress(_ itemIndex: Int) {
        let selectedAddress = self.selectionAddreses[itemIndex]
        
        self.saveDefaultAddress(selectedAddress)
    }
    
    func saveDefaultAddress(_ address: Address, popViewController: Bool = false) {
        firstly {
            return self.saveDefaultAddress(address.userAddressKey)
        }.then { _ -> Void in
            self.selectedAddress = address
            
            if popViewController {
                self.popViewController()
            } else {
                self.showSuccessPopupWithText(String.localize("MSG_CA_DEFAULT_ADDR_CHANGE_SUC"))
                self.collectionView.reloadData()
            }
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    // MARK: - CollectionView Data Source, Delegate Method
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectionAddreses.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let heightOfFooterView = CGFloat(0)
        return CGSize(width: self.view.bounds.width, height: heightOfFooterView)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddressSelectionCellID, for: indexPath) as! AddressSelectionCell
        
        cell.data = selectionAddreses[indexPath.row]
        
        cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        
        if let selectedAddress = self.selectedAddress {
            cell.setDefaultAddress(selectedAddress.userAddressKey == selectionAddreses[indexPath.row].userAddressKey)
        }
        
        if self.viewMode == .profile {
            cell.setDefaultAddressHandler = { [weak self] in
                if let strongSelf = self {
                    strongSelf.setDefaultAddress(indexPath.row)
                }
            }
        } else {
            cell.checkboxButton.isUserInteractionEnabled = false
        }
        
        cell.editAddressHandler = { [weak self] (data) in
            if let strongSelf = self {
                strongSelf.editAddressTapped(address: data)
                if strongSelf.viewMode != .profile {
                    strongSelf.view.recordAction(.Tap, sourceRef: data.userAddressKey, sourceType: .ShippingAddress, targetRef: "UserAddress-Edit", targetType: .View)
                }
            }
        }
        
        cell.leftMenuItems = nil
        cell.rightMenuItems = self.createRightMenuItems(indexPath: indexPath)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var cellHeight = 3*AddressSelectionCell.LabelHeight + 2*AddressSelectionCell.TopPadding + 2*AddressSelectionCell.VerticalPadding
        let address = selectionAddreses[indexPath.row]
        
        var labelWidth = view.frame.width - AddressSelectionCell.DisclosureIndicatorXPosition - Constants.Checkbox.Size.width
        if viewMode == .profile {
            let width = StringHelper.getTextWidth(String.localize("LB_CA_DEFAULT"), height: AddressSelectionCell.LabelHeight, font: UIFont.systemFont(ofSize: CGFloat(AddressSelectionCell.FontSize)))
            labelWidth = labelWidth - width - 3*AddressSelectionCell.TopPadding
        }else {
            if address.isDefault{
                cellHeight += AddressSelectionCell.DefaultBottomViewHeight + AddressSelectionCell.VerticalPadding
            }
        }

        return CGSize(width: view.width, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedAddress = selectionAddreses[indexPath.row]
        
        if self.viewMode == .profile {
            if let selectedAddress = selectedAddress {
                saveDefaultAddress(selectedAddress, popViewController: (viewMode == .checkout || viewMode == .checkoutSwipeToPay))
            }
        }else {
            self.popViewController()
            self.view.recordAction(.Tap, sourceRef: selectionAddreses[indexPath.row].userAddressKey, sourceType: .ShippingAddress, targetRef: "Checkout", targetType: .View)

        }
    }
}
