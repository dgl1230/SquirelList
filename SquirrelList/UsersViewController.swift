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
        let name = objects![indexPath.row]["name"] as? String
        //It looks strange to have the row highlighted in gray
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        if (objects![indexPath.row]["username"] as? String == PFUser.currentUser()!.username) {
             cell.usernameLabel.text = "me"
        }
        else if name != nil {
            cell.usernameLabel.text = objects![indexPath.row]["name"] as? String
        } else {
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
        //We check to see if the user has been recently given a strike for offensive content
        if PFUser.currentUser()!["recentStrike"] as! Bool == true {
            let query  = PFQuery(className: "Report")
            query.whereKey("offendingUsername", equalTo: PFUser.currentUser()!.username!)
            let report = query.getFirstObject()
            let warning = report!["warningToOffender"] as! String
            var alert = UIAlertController(title: "This is a warning for posting offensive material", message: warning, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            PFUser.currentUser()!["recentStrike"] = false
            PFUser.currentUser()!.save()
        }
        //Check to see if we need to show a new user tutorial screens first
        if PFUser.currentUser()!["newUserTab"] as! Bool == true {
            println("should be showing user screens")
            //If new user, show them the tutorial screens
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let tutorialTestStoryBoard = UIStoryboard(name: "Tutorial", bundle: nil)
            let contentController = tutorialTestStoryBoard.instantiateViewControllerWithIdentifier("ContentViewController") as! TutorialViewController
            contentController.typeOfContent = "user"
            appDelegate.window!.rootViewController = contentController
            appDelegate.window!.makeKeyAndVisible()
        
        }

        
        //Set the addFriendToGroupButton to 'fa-user-plus
        addFriendToGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        addFriendToGroupButton?.title = "\u{f234}"
        addFriendToGroupButton?.tintColor = UIColor.orangeColor()
        //Set the changeCurrentGroupButton to 'fa-bars'
        changeCurrentGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        changeCurrentGroupButton?.title = "\u{f0c9}"
        changeCurrentGroupButton?.tintColor = UIColor.orangeColor()
        
        self.title = currentGroup!["name"] as? String
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        
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

