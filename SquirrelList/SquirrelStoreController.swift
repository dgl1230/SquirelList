//
//  SquirrelStoreController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 7/17/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SquirrelStoreController: UITableViewController {

    //Variable for storing the individualGroupData instance
    //var individualGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
    //Variable for holding the user's currentGroup
    var currentGroup: PFObject?
    
    //Optional for storing whether the SquirrelStoreController should reload (when a user changes their current group)
    var shouldReload: Bool?

    @IBOutlet weak var acornsLabel: UILabel!
    @IBOutlet weak var buySquirrelSlotsButton: UIButton!
    @IBOutlet weak var buyReratingButton: UIButton!
    @IBOutlet weak var purchaseReratingLabel: UILabel!

    @IBAction func buySquirrelSlots(sender: AnyObject) {
        var acorns = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        acorns! -= 500
        var squirrelSlots = getUserInfo(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
        squirrelSlots! += 1
        let newAcornsArray = getNewArrayToSave(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!, String(acorns!))
        let newSquirrelSlots = getNewArrayToSave(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(squirrelSlots!))
        currentGroup!["acorns"] = newAcornsArray
        currentGroup!["squirrelSlots"] = newSquirrelSlots
        currentGroup!.save()
        //individualGroupData.save()
        acornsLabel.text = "\(acorns!)"
        if acorns < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        if acorns < 50 {
            buyReratingButton.enabled = false
        }
        
    }

    @IBAction func buyRerating(sender: AnyObject) {
        //var acorns = individualGroupData["acorns"] as! Int
        var acorns = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        acorns! -= 50
        var rerate = "1"
        let newAcornsArray = getNewArrayToSave(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!, String(acorns!))
        let newRerates = getNewArrayToSave(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!, rerate)
        currentGroup!["acorns"] = newAcornsArray
        currentGroup!["rerates"] = newRerates
        currentGroup!.save()
        acornsLabel.text = "\(acorns!)"
        //Users can only buy one rerate at a time
        buyReratingButton.enabled = false
        if acorns < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        purchaseReratingLabel.text = "Purchase Rerating (1/1)"
    }
    
    func reload() {
        shouldReload = true
    }


    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldReload == true {
            self.viewDidLoad()
            shouldReload = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: reloadNotificationKey, object: nil)
        //Set notification to "listen" for when the the user has used their Rerate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: "didUseRerate", object: nil)
        var acorns = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        acornsLabel.text = "\(acorns!)"
        var rerate = getUserInfo(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!).toInt()
        if rerate == 0 {
            purchaseReratingLabel.text = "Purchase Rerating (0/1)"
        } else {
            purchaseReratingLabel.text = "Purchase Rerating (1/1)"
        }
        
        if acorns < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        if (acorns < 50) || (rerate == 1) {
            buyReratingButton.enabled = false
        }
        let groupName = currentGroup!["name"] as! String
        self.title = "\(groupName) Squirrel Store"
        
    }
    

}
