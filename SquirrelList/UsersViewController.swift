//
//  FirstViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class UsersViewController: UITableViewController {

    var users = [PFUser]()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SingleUserSquirrels" {
            let controller = segue.destinationViewController as SquirrelViewController
            controller.selectedUser = sender as? PFUser
        }

    }
    
    //Reloads the tableview data and then ends the pull to refresh loading animation when complete
    func refresh(sender:AnyObject) {
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        if (users[indexPath.row]["username"] as? String == PFUser.currentUser().username) {
             cell.textLabel?.text = "me"
        }
        else {
            cell.textLabel?.text = users[indexPath.row]["username"] as? String
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("SingleUserSquirrels", sender: users[indexPath.row])
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //For allowing pull to refresh 
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)
        
        //First we need to get the appropriate group 
        var currentGroupQuery = PFQuery(className: "Group")
        PFUser.currentUser().fetch()
        currentGroupQuery.whereKey("name", equalTo: PFUser.currentUser()["current_group"])
        var currentGroup = currentGroupQuery.getFirstObject()
        
        var userIDs = currentGroup!["userIDs"] as [String]
        
        var query = PFUser.query()
        //Need to refine this to take into account new users
        //Need to update currentGroup in registerpage
        //query.whereKey("objectId", containedIn: userIDs)
        
        query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError!) -> Void in
            self.users.removeAll(keepCapacity: true)
            for object in objects {
                var user:PFUser = object as PFUser
                self.users.append(user)
                
            }
            self.tableView.reloadData()
            self.title = currentGroup!["name"] as? String
            
        })
        
    }



}

