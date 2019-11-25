//
//  MyFollowersViewController.swift
//  merchant-ios
//
//  Created by Markus Chow on 11/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MyFollowersViewController: FollowViewController {

	var myFollowersListViewController = MyFollowersListViewController()
	var thisUser = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        myFollowersListViewController.thisUser = self.thisUser
        myFollowersListViewController.currentProfileType = currentProfileType
        self.delegate_ = myFollowersListViewController.self
		activeViewController = myFollowersListViewController

    }
	
    override func shouldHavePageViewController() -> Bool {
        return false
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		super.title = String.localize("LB_CA_FOLLOWER_LIST")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func createTopView() {
		super.createTopView()
        if self.segmentView != nil {
            self.segmentView.removeFromSuperview()
        }
        
        let yPos = navigationController?.navigationBar.frame.maxY ?? StartYPos
		searchBar.frame = CGRect(x: 0, y: yPos, width: self.view.bounds.width, height: 40)
	}
	
	override func createContentView() {
		super.createContentView()
		
	}

    
    override func getCurrentCollectionView() -> UICollectionView? {
        return myFollowersListViewController.collectionView
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    override func respondToSwipeGesture(_ gesture: UIGestureRecognizer) {
        return
    }
}
