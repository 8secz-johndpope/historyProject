//
//  LanguageViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class LanguageViewController: UITableViewController{
    var user : User?
    weak var delegate: ChangeLanguageDelegate?
    var languages : [Language] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_LANGUAGE")
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.showLoading()
        self.setUpRefreshControl()
        loadLanguages()
    }
    
    func setUpRefreshControl(){
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: String.localize("LB_PULL_DOWN_REFRESH"))
        self.refreshControl!.addTarget(self, action: #selector(LanguageViewController.refresh), for: .valueChanged)
        self.tableView.addSubview(refreshControl!)
    }
    
    @objc func refresh(sender : Any){
        loadLanguages()
    }
    
    func loadLanguages(){
        ReferenceService.changeLanguage(){response in
            self.stopLoading()
            if response.result.isSuccess{
                let languageResponse = Mapper<LanguageResponse>().map(JSONObject: response.result.value)!
                self.languages = languageResponse.languageList
                self.refreshControl!.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("LanguageCell")!
        if (self.languages.count > 0){
            cell.textLabel!.text = self.languages[indexPath.row].languageName
            cell.textLabel!.numberOfLines = 0
            cell.textLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
            
            cell.bounds = CGRect(x: 0, y: 0, width: CGRectGetWidth(tableView.bounds), height: 99999)
            cell.contentView.bounds = cell.bounds
            cell.layoutIfNeeded()
            
            cell.textLabel!.preferredMaxLayoutWidth = CGRectGetWidth(cell.textLabel!.frame)
            
            if self.languages[indexPath.row].languageId == self.user?.languageId{
                cell.accessoryView = UIImageView(image: UIImage(named: "tick"))
            }
        }
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.languages.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.changeLanguage(self.languages[indexPath.row])
        self.navigationController!.popViewController(animated:true)
    }
}
