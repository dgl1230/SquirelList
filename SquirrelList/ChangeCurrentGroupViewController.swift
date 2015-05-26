//
//  ChangeCurrentGroupViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 4/11/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


import UIKit

class ChangeCurrentGroupViewController: PFQueryTableViewController {
    
    //Optional for holding which cell should have a checkmark
    var checkMarkedCellIndex: NSIndexPath?
    
    //this variable is for checking to see when the user presses done, if they have stayed on the same current group. If they have, then we don't want to send notifications to reload everything
    var currentGroup = PFUser.currentUser()!["currentGroup"]! as! PFObject
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    
    @IBAction func done(sender: AnyObject) {
        if currentGroup != PFUser.currentUser()!["currentGroup"] as! PFObject {
            //We only want to reload everything if the user hasn't selected their same currentGroup
            PFUser.currentUser()!["currentGroup"] = currentGroup
            PFUser.currentUser()!.save()
            //UsersViewController, SquirrelViewController, MessagesViewController, SearchUsersViewController(for adding friends to group, and NotificationsViewController(for trade proposals) all new to be reloaded when their views appear 
            NSNotificationCenter.defaultCenter().postNotificationName(reloadNotificationKey, object: self)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Group"
        self.textKey = "name"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        var query = PFQuery(className: "Group")
        query.whereKey("objectId", containedIn: PFUser.currentUser()!["groups"]! as! [String])
        query.orderByDescending("name")
        return query
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UsersCellTableViewCell
        //var name = cell.viewWithTag(1) as! UILabel
        cell.usernameLabel.text = objects![indexPath.row]["name"] as? String
        cell.usernameLabel.font = UIFont(name: "BebasNeue-Thin", size: 30)
        if objects![indexPath.row].objectId == PFUser.currentUser()!["currentGroup"]!.objectId {
            cell.accessoryType = .Checkmark
            checkMarkedCellIndex = indexPath
        }
        return cell
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        //Remove checkmark from old cell
        let oldCheckMarkedCell = tableView.cellForRowAtIndexPath(checkMarkedCellIndex!)
        oldCheckMarkedCell?.accessoryType = .None
        //Update checkMarkedCellIndex
        checkMarkedCellIndex = indexPath
        //Update the current group variable
        currentGroup = objects![indexPath.row] as! PFObject
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting the doneButton with the 'fa-check-circle' button
        doneButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        doneButton.setTitle("\u{f058}", forState: .Normal)
        //Register the UsersCellTableViewCell for use in the UserViewController tableView
        tableView.registerNib(UINib(nibName: "UsersCellTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }


   
}
