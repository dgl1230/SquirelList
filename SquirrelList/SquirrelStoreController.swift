//
//  SquirrelStoreController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 7/17/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SquirrelStoreController: UITableViewController {

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: reloadNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "didUseRerate", object: nil)
    }
    //Optional for storing whether the SquirrelStoreController should reload (when a user changes their current group)
    var shouldReload: Bool?

    @IBOutlet weak var acornsLabel: UILabel!
    @IBOutlet weak var buySquirrelSlotsButton: UIButton!
    @IBOutlet weak var buyReratingButton: UIButton!
    @IBOutlet weak var purchaseReratingLabel: UILabel!

    @IBAction func buySquirrelSlots(sender: AnyObject) {
        let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        currentGroup.fetch()
        var acorns = getUserInfo(currentGroup["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        if acorns! < 500 {
            displayAlert(self, "Ooops", "You don't have that many acorns anymore! Perhaps a trade was just accepted?")
            return
        }
        LOGGED_IN_USER_ACORNS = acorns!
        LOGGED_IN_USER_ACORNS -= 500
        var squirrelSlots = getUserInfo(currentGroup["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
        LOGGED_IN_USER_SQUIRREL_SLOTS += 1
        let newAcornsArray = getNewArrayToSave(currentGroup["acorns"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_ACORNS))
        let newSquirrelSlots = getNewArrayToSave(currentGroup["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_SQUIRREL_SLOTS))
        currentGroup["acorns"] = newAcornsArray
        currentGroup["squirrelSlots"] = newSquirrelSlots
        currentGroup.save()
        acornsLabel.text = "\(LOGGED_IN_USER_ACORNS)"
        if LOGGED_IN_USER_ACORNS < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        if LOGGED_IN_USER_ACORNS < 50 {
            buyReratingButton.enabled = false
        }
        
    }

    @IBAction func buyRerating(sender: AnyObject) {
        let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        currentGroup.fetch()
        var acorns = getUserInfo(currentGroup["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        if acorns! < 50 {
            displayAlert(self, "Ooops", "You don't have that many acorns anymore! Perhaps a trade was just accepted?")
            return
        }
        LOGGED_IN_USER_ACORNS = acorns!
        LOGGED_IN_USER_ACORNS -= 50
        LOGGED_IN_USER_RERATES = 1
        let newAcornsArray = getNewArrayToSave(currentGroup["acorns"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_ACORNS))
        let newRerates = getNewArrayToSave(currentGroup["rerates"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_RERATES))
        currentGroup["acorns"] = newAcornsArray
        currentGroup["rerates"] = newRerates
        currentGroup.save()
        acornsLabel.text = "\(LOGGED_IN_USER_ACORNS)"
        //Users can only buy one rerate at a time
        buyReratingButton.enabled = false
        if LOGGED_IN_USER_ACORNS < 500 {
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
    
    
    func update() {
        let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        LOGGED_IN_USER_ACORNS = getUserInfo(currentGroup["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()!
        LOGGED_IN_USER_SQUIRREL_SLOTS = getUserInfo(currentGroup["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()!
        LOGGED_IN_USER_RERATES = getUserInfo(currentGroup["rerates"] as! [String], PFUser.currentUser()!.username!).toInt()!
        LOGGED_IN_USER_GROUP_NAME = currentGroup["name"] as! String
        //var acorns = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
        acornsLabel.text = "\(LOGGED_IN_USER_ACORNS)"
        //var rerate = getUserInfo(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!).toInt()
        if LOGGED_IN_USER_RERATES == 0 {
            purchaseReratingLabel.text = "Purchase Rerating (0/1)"
        } else {
            purchaseReratingLabel.text = "Purchase Rerating (1/1)"
        }
        
        if LOGGED_IN_USER_ACORNS < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        if (LOGGED_IN_USER_ACORNS < 50) || (LOGGED_IN_USER_RERATES == 1) {
            buyReratingButton.enabled = false
        }
        //let groupName = currentGroup!["name"] as! String
        self.title = "\(LOGGED_IN_USER_GROUP_NAME) Squirrel Store"
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldReload == true {
            update()
            shouldReload = false
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: reloadNotificationKey, object: nil)
        //Set notification to "listen" for when the the user has used their Rerate
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: "didUseRerate", object: nil)
    }
    

}
