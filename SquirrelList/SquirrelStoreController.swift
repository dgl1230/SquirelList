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
    var individualGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
    
    //Optional for storing whether the SquirrelStoreController should reload (when a user changes their current group)
    var shouldReload: Bool?

    @IBOutlet weak var acornsLabel: UILabel!
    @IBOutlet weak var buySquirrelSlotsButton: UIButton!
    @IBOutlet weak var buyReratingButton: UIButton!

    @IBAction func buySquirrelSlots(sender: AnyObject) {
        var acorns = individualGroupData["acorns"] as! Int
        acorns -= 500
        var squirrelSlots = individualGroupData["squirrelSlots"] as! Int
        squirrelSlots += 1
        individualGroupData["acorns"] = acorns
        individualGroupData["squirrelSlots"] = squirrelSlots
        individualGroupData.save()
        acornsLabel.text = "Acorns: \(acorns)"
        
    }

    @IBAction func buyRerating(sender: AnyObject) {
        var acorns = individualGroupData["acorns"] as! Int
        acorns -= 50
        individualGroupData["acorns"] = acorns
        individualGroupData["canRerate"] = true
        individualGroupData.save()
        acornsLabel.text = "Acorns: \(acorns)"
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
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: reloadNotificationKey, object: nil)
        //Update the UserGroupData instance, the individualGroupData variable refers to an old instance if the user changes their currentGroup
        individualGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
        individualGroupData.fetch()
        let acorns = individualGroupData["acorns"] as! Int
        acornsLabel.text = "Acorns: \(acorns)"
        let canRerate = individualGroupData["canRerate"] as! Bool
        if acorns < 500 {
            buySquirrelSlotsButton.enabled = false
        }
        if (acorns < 50) || (canRerate == true) {
            buyReratingButton.enabled = false
        }
    }
    

}
