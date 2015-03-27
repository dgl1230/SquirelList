//
//  UserSquirrelsNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


import UIKit

class UserSquirrelsViewController: PFQueryTableViewController {

    var squirrels: [PFObject]?

    //Squirrel that the logged in user wants in return for one of their squirrels
    var desiredSquirrel: PFObject?
    //The owner of the squirrel that the logged in user wants
    var desiredSquirrelOwner: PFUser?
    
    
    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "last_name"
        self.pullToRefreshEnabled = false
        self.paginationEnabled = false
    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFO
        query.orderByAscending("username")
        return query
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var squirrelQuery = PFQuery(className: "Squirrel")
        squirrelQuery.whereKey("owner", equalTo: PFUser.currentUser()["username"])
        squirrelQuery.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
                if error == nil {
                    self.squirrels = objects as? [PFObject]
                } else {
                    // Log details of the failure
                    println("Error: \(error) \(error.userInfo!)")
                }
        }
        
    
    }

    
    
}
