//
//  FriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/30/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/* ViewController that displays all of the logged in user's friends
*/

import UIKit

class FriendsViewController: PFQueryTableViewController {


    var shouldReload: Bool?
  
    //Button only occurs when user is in their 'Friends' main page under the 'More' tab
    @IBOutlet weak var findFriendsButton: UIBarButtonItem?
    
    @IBAction func findFriends(sender: AnyObject) {
        performSegueWithIdentifier("FindFriends", sender: self)
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
    
    
    //Takes the tag of the button pressed in the tableViewCell and adds the user at the index of the objects array to the appropriate data model
    func addUser(sender:UIButton!) {
        let buttonRow = sender.tag
        let request = objects![buttonRow] as! PFObject
        request["status"] = "accepted"
        //Need to add the user to logged in user's friends and remove them from pendingFriends
        let user1 = request["RequestFromUsername"] as! String
        //user1.fetch()
        let user2 = request["RequestToUsername"] as! String
        //user2.fetch()
        if user1 != PFUser.currentUser()?.username {
            PFUser.currentUser()!.addObject(user1, forKey: "friends")
            PFUser.currentUser()!.removeObject(user1, forKey: "pendingFriends")
        } else {
            PFUser.currentUser()!.addObject(user2, forKey: "friends")
            PFUser.currentUser()!.removeObject(user2, forKey: "pendingFriends")
        }
        PFUser.currentUser()!.save()
        request.save()
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FindFriends" {
            let controller = segue.destinationViewController as! SearchUsersViewController
        }
    }
    
    override func objectsDidLoad(error: NSError?) {
        super.objectsDidLoad(error)
        //This way we have an up to date friends and pendingFriends list
        PFUser.currentUser()!.fetch()
        //Bools to keep track of whether we need to save the current's users friends and pendingFriends (if users have been added to either one)
        //var shouldSaveFriends = false
        //var shouldSavePendingFriends = false
        
        //Everytime the objects load, we need to update the user's friends and pendingFriends
        //Ghetto and bad way of initializing, should be changed
        var friends: [String] = []
        if PFUser.currentUser()!["friends"] != nil {
            friends = PFUser.currentUser()!["friends"] as! [String]
        }
        
        var pendingFriends: [String] = []
        if PFUser.currentUser()!["pendingFriends"] != nil {
            pendingFriends = PFUser.currentUser()!["pendingFriends"] as! [String]
        }

        for request in objects! {
            var user1 = request["RequestFrom"] as! PFUser
            var user2 = request["RequestTo"] as! PFUser
            var status = request["status"] as! String
            if status == "accepted" {
                if (user1.objectId != PFUser.currentUser()!.objectId) && (find(friends, user1.username!) == nil){
                    friends.append(user1.username!)
                    //If they're currently in pending friends, we need to remove them
                    var index = find(pendingFriends, user1.username!)
                    if index != nil {
                        pendingFriends.removeAtIndex(index!)
                    }
                } else if (user2.objectId != PFUser.currentUser()!.objectId) && (find(friends, user2.username!) == nil) {
                    //We know at this point that user2 is not the logged in user, so we just need to check if they're already friends
                    friends.append(user2.username!)
                    //If they're currently in pending friends, we need to remove them
                    var index = find(pendingFriends, user2.username!)
                    if index != nil {
                        pendingFriends.removeAtIndex(index!)
                    }
                }
            } else if status == "pending" {
                if user1.objectId != PFUser.currentUser()!.objectId && (find(pendingFriends, user1.username!) == nil) {
                    pendingFriends.append(user1.username!)
                } else if user2.objectId != PFUser.currentUser()!.objectId && (find(pendingFriends, user2.username!) == nil) {
                    pendingFriends.append(user2.username!)
                }
            }
        }
        PFUser.currentUser()!["friends"] = friends
        PFUser.currentUser()!["pendingFriends"] = pendingFriends
        PFUser.currentUser()!.save()
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        var query1 = PFQuery(className: "FriendRequest")
        query1.whereKey("RequestTo", equalTo: PFUser.currentUser()!)
        query1.whereKey("status", notEqualTo: "rejected")
        
        var query2 = PFQuery(className: "FriendRequest")
        query2.whereKey("RequestFrom", equalTo: PFUser.currentUser()!)
        query2.whereKey("status", equalTo: "accepted")
        
        var query = PFQuery.orQueryWithSubqueries([query1, query2])
        return query
    }
    

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        //Really ghetto way to avoid Xcode thinking that user variable doesn't exist (since it's created in the if/else) needs to be less ghetto soon
        var user = ""
        var user1 = objects![indexPath.row]["requestFromUsername"] as! String
        if user1 != PFUser.currentUser()!.username {
            user = user1
        } else {
            user = objects![indexPath.row]["requestToUsername"] as! String
        }
        cell.nameLabel.text = user 
        cell.addButton.tag = indexPath.row
        if objects![indexPath.row]["status"] as! String == "accepted" {
            //The user variable has been already added to the relevant group
            //Ghetto method for now, need to make it so that the button isn't default
            cell.addButton.enabled = false
            cell.addButton.hidden = true
        } else if objects![indexPath.row]["status"] as! String == "pending" {
            //The user variable has not already added to the relevant group
            //Setting the addFriendButton with the 'fa-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f096}", forState: .Normal)
            cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            var request = objects![indexPath.row] as! PFObject
            request["status"] = "rejected"
            request.save()
            self.loadObjects()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        //Setting the find friend image, which is 'fa-user-plus'
        findFriendsButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        findFriendsButton?.title = "\u{f234}"
        findFriendsButton?.tintColor = UIColor.orangeColor()
        self.tableView.allowsSelection = false
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }
   
}
