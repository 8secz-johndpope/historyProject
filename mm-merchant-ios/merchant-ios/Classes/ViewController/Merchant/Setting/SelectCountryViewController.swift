//
//  SelectCountryViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class SelectCountryViewController : UITableViewController, UISearchBarDelegate{
    var countries : [Country] = []
    var filteredCountries : [Country] = []
    weak var delegate : SelectCountryDelegate?
    
    var mobileCodes : [MobileCode] = []
    var filteredMobileCodes : [MobileCode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.showLoading()
        self.setUpRefreshControl()
        loadCountries()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_COUNTRY_PICK")
        self.refreshControl!.attributedTitle = NSAttributedString(string: String.localize("LB_PULL_DOWN_REFRESH"))
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CountryCell")!
        if (self.filteredMobileCodes.count > indexPath.row) {
            cell.textLabel!.text = self.filteredMobileCodes[indexPath.row].mobileCodeName
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.detailTextLabel!.text = self.filteredMobileCodes[indexPath.row].mobileCodeNameInvariant
            cell.detailTextLabel!.numberOfLines = 0
            cell.detailTextLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            
            cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 99999)
            cell.contentView.bounds = cell.bounds
            cell.layoutIfNeeded()
            
            cell.textLabel!.preferredMaxLayoutWidth = cell.textLabel!.frame.width
            cell.detailTextLabel!.preferredMaxLayoutWidth = cell.detailTextLabel!.frame.width
        }
        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredMobileCodes.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let country = Country()
//        country.name = self.filteredCountries[indexPath.row].name
//        country.callingCodes = self.filteredCountries[indexPath.row].callingCodes
//        delegate?.selectCountry(country)
        delegate?.selectMobileCode(self.filteredMobileCodes[indexPath.row])
        self.navigationController!.popViewController(animated: true)
    }
    
    func setUpRefreshControl(){
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(SelectCountryViewController.refresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    @objc func refresh(_ sender : Any){
        loadCountries()
    }
    
    func loadCountries(){
//        CountryService.request(CountryService.Op.GetAllCountries){[weak self] (response) in
        CountryService.list {[weak self] (response) -> Void in
            if let strongSelf = self {
                strongSelf.stopLoading()
                if response.result.isSuccess {
//                    strongSelf.countries = Mapper<Country>().mapArray(JSONObject: response.result.value)!
                    if let resp : MobileCodeListResponse = Mapper<MobileCodeListResponse>().map(JSONObject: response.result.value) {
                        strongSelf.mobileCodes = resp.results
                        strongSelf.filteredMobileCodes = strongSelf.mobileCodes
                        strongSelf.refreshControl!.endRefreshing()
                        strongSelf.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: UISearchBarDelegate
    
    private func filter(_ text : String!) {
        self.filteredMobileCodes = self.mobileCodes.filter(){ $0.mobileCodeName.lowercased().range(of: text.lowercased()) != nil }
        self.tableView?.reloadData()
    }

    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        self.filteredCountries = self.countries.filter(){ $0.name.lowercased().range(of: searchBar.text!.lowercased()) != nil }
        self.filter(searchBar.text!)
        searchBar.resignFirstResponder()
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.length == 0 {
            self.filteredMobileCodes = self.mobileCodes
            self.tableView.reloadData()
        } else {
            self.filter(searchBar.text!)
        }
    }
}
