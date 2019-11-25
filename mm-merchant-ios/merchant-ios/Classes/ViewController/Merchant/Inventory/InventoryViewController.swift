//
//  InventoryViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 20/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class InventoryViewController : UITableViewController, UISearchBarDelegate{
    var user : User?
    weak var delegate: ChangeInventoryLocationDelegate?
    var inventoryLocations : [InventoryLocation] = []
    var filteredInventoryLocations : [InventoryLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.showLoading()
        self.setUpRefreshControl()

        loadInventoryLocations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_INVENTORY_LOCATION")
        self.refreshControl?.attributedTitle = NSAttributedString(string: String.localize("LB_PULL_DOWN_REFRESH"))
    }
    
    func setUpRefreshControl(){
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(InventoryViewController.refresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    @objc func refresh(_ sender : Any){
        loadInventoryLocations()
    }
    
    func loadInventoryLocations(){
        InventoryService.list((self.user?.userKey)!){[weak self] (response) in
            if let strongSelf = self {
                strongSelf.stopLoading()
                if response.result.isSuccess {
                    if let locations = Mapper<InventoryLocation>().mapArray(JSONObject: response.result.value) {
                        strongSelf.inventoryLocations = locations
                        strongSelf.filteredInventoryLocations = strongSelf.inventoryLocations
                        strongSelf.refreshControl!.endRefreshing()
                        strongSelf.tableView.reloadData()
                    }
                }
            }
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "InventoryLocationCell")!
        if (self.filteredInventoryLocations.count > 0){
            cell.textLabel!.text = self.filteredInventoryLocations[indexPath.row].locationName
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            
            cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 99999)
            cell.contentView.bounds = cell.bounds
            cell.layoutIfNeeded()
            
            cell.textLabel!.preferredMaxLayoutWidth = cell.textLabel!.frame.width
            
            if self.filteredInventoryLocations[indexPath.row].inventoryLocationId == self.user?.inventoryLocationId{
                cell.accessoryView = UIImageView(image: UIImage(named: "tick"))
            }
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredInventoryLocations.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var inventoryLocation = InventoryLocation()
        inventoryLocation = self.filteredInventoryLocations[indexPath.row]
        delegate?.changeInventoryLocation(inventoryLocation)
        self.navigationController!.popViewController(animated: true)
    }
    
    // MARK: UISearchBarDelegate
    
    private func filter(_ text : String!) {
        self.filteredInventoryLocations = self.inventoryLocations.filter(){ $0.locationName.lowercased().range(of: text.lowercased()) != nil }
        self.tableView?.reloadData()
    }
    
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.filter(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.length == 0 {
            self.filteredInventoryLocations = self.inventoryLocations
            self.tableView.reloadData()
        } else {
            self.filter(searchBar.text!)
        }
    }

}
