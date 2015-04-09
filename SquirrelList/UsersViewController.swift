//
//  UsersViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class UsersViewController: PFQueryTableViewController {

    var currentGroup: PFObject?


    @IBOutlet weak var addFriendToGroupButton: UIBarButtonItem?


    @IBAction func addFriendToGroup(sender: AnyObject) {
        self.performSegueWithIdentifier("AddFriendToGroup", sender: self)
    }
    

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
        if segue.identifier == "AddFriendToGroup" {
            let controller = segue.destinationViewController as SearchUsersViewController
            controller.addingToGroup = true
        }

    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        //The optional currentGroup needs to be called here, because queryForTable() is called before viewDidLoad()
        currentGroup = PFUser.currentUser()["currentGroup"] as? PFObject
        currentGroup!.fetch()
        
        var query = PFUser.query()
        query.whereKey("objectId", containedIn: currentGroup!["userIDs"] as [String])
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
        //Set the addFriendToGroupButton to 'fa-user-plus
        addFriendToGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        addFriendToGroupButton?.title = "\u{f234}"
        addFriendToGroupButton?.tintColor = UIColor.whiteColor()

        self.tableView.reloadData()
        self.title = currentGroup!["name"] as? String
    }
   
}
