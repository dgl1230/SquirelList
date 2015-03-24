//
//  UsersViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class UsersViewController: PFQueryTableViewController {

    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "User"
        self.textKey = "username"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SingleUserSquirrels" {
            let controller = segue.destinationViewController as SquirrelViewController
            controller.selectedUser = sender as? PFUser
        }

    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFUser.query()
        query.orderByAscending("username")
        return query
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if (objects[indexPath.row]["username"] as? String == PFUser.currentUser().username) {
             cell.textLabel?.text = "me"
        }
        else {
            cell.textLabel?.text = objects[indexPath.row]["username"] as? String
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("SingleUserSquirrels", sender: objects[indexPath.row])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //We need to get the appropriate group 
        var currentGroupQuery = PFQuery(className: "Group")
        PFUser.currentUser().fetch()
        currentGroupQuery.whereKey("name", equalTo: PFUser.currentUser()["current_group"])
        var currentGroup = currentGroupQuery.getFirstObject()
        
        self.tableView.reloadData()
        self.title = currentGroup!["name"] as? String
    }
   
}
