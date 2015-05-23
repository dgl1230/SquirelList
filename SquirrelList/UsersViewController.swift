//
//  UsersViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

//Notification specific string
let reloadNotificationKey = "com.denis.reloadNotificationKey"

class UsersViewController: PFQueryTableViewController {

    var currentGroup: PFObject?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?


    @IBOutlet weak var addFriendToGroupButton: UIBarButtonItem?
    @IBOutlet weak var changeCurrentGroupButton: UIBarButtonItem?
    
    
    @IBAction func addFriendToGroup(sender: AnyObject) {
        self.performSegueWithIdentifier("AddFriendToGroup", sender: self)
    }
    

    @IBAction func changeCurrentGroup(sender: AnyObject) {
        self.performSegueWithIdentifier("ChangeCurrentGroup", sender: self)
    }
    
    
    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
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
        if segue.identifier == "AddFriendToGroup" {
            let controller = segue.destinationViewController as! SearchUsersViewController
            controller.addingToGroup = true
        }
        if segue.identifier == "ChangeCurrentGroup" {
            let controller = segue.destinationViewController as! ChangeCurrentGroupViewController
            //controller.delegate = self
        }
        if segue.identifier == "SingleUserSquirrels" {
            let controller = segue.destinationViewController as! SquirrelViewController
            controller.selectedUser = sender as? PFUser
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //The optional currentGroup needs to be called here, because queryForTable() is called before viewDidLoad()
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        
        var query = PFUser.query()
        query!.whereKey("username", containedIn: currentGroup!["userIDs"] as! [String])
        query!.orderByAscending("username")
        return query!
    }
    
     //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UsersCellTableViewCell
        //var username = cell.viewWithTag(1) as! UILabel
        if (objects![indexPath.row]["username"] as? String == PFUser.currentUser()!.username) {
             //username.text = "me"
             cell.usernameLabel.text = "me"
        }
        else {
            //username.text = objects![indexPath.row]["username"] as? String
            cell.usernameLabel.text = objects![indexPath.row]["username"] as? String
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("SingleUserSquirrels", sender: objects![indexPath.row])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        //Set the addFriendToGroupButton to 'fa-user-plus
        addFriendToGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        addFriendToGroupButton?.title = "\u{f234}"
        addFriendToGroupButton?.tintColor = UIColor.orangeColor()
        //Set the changeCurrentGroupButton to 'fa-bars'
        changeCurrentGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        changeCurrentGroupButton?.title = "\u{f0c9}"
        changeCurrentGroupButton?.tintColor = UIColor.orangeColor()

        //Not sure if I need this line
        //self.tableView.reloadData()
        self.title = currentGroup!["name"] as? String
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.orangeColor()]
        
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        //Register the UsersCellTableViewCell for use in the UserViewController tableView
        tableView.registerNib(UINib(nibName: "UsersCellTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")


    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    

}

