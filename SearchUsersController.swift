//
//  FindFriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
Lets users search and find other users via their usernames
*/



import UIKit

class SearchUsersViewController: PFQueryTableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    @IBOutlet var searchController: UISearchDisplayController!

    
    //Variable for seeing what to search usernames for, updates everytime user presses the search button
    var searchedString = ""
    
    //Variable for storing all of the users' usernames that the logged in user is already friends with, has friended, or has friended them
    var users: [String] = []
    

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "User"
        self.textKey = "username"
        self.pullToRefreshEnabled = false
        self.paginationEnabled = false
    }

    
    //Takes the tag of the button pressed in the tableViewCell and adds the user at the index of the objects array to the appropriate data model
    func addUser(sender:UIButton!) {
        let buttonRow = sender.tag
        let otherUserFriendData = objects![buttonRow] as! PFObject
        let username = otherUserFriendData["lowerUsername"] as! String
        //We want to prevent the user from being able to quickly press the add friend button multiple times
        let indexPath = NSIndexPath(forRow: buttonRow, inSection: 0)
        var cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FindUserTableViewCell
        cell.addButton.enabled = false
        //Check to see whether we should prompt the user to enable push notifications
        let hasFriended = PFUser.currentUser()!["hasFriended"] as! Bool
        let hasBeenAskedForPush = PFUser.currentUser()!["hasBeenAskedForPush"] as! Bool
        if  (hasBeenAskedForPush == false) && (hasFriended == false) {
            //This is the first type that the user has friended someone and they haven't enabled push notification, so we can prompt them
            let title = "Let Squirrel List Access Notifications?"
            let message = "You'll be alerted when \(username) has accepted your request. "
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Not Now", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
                PFUser.currentUser()!["hasFriended"] = true
                PFUser.currentUser()!.save()
            }))
            alert.addAction(UIAlertAction(title: "Give Access", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                //We ask the user for push notification permission in chat because it's easier to explain why they might need it
                alert.dismissViewControllerAnimated(true, completion: nil)
                let notificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
                let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
                UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                PFUser.currentUser()!["hasFriended"] = true
                PFUser.currentUser()!["hasBeenAskedForPush"] = true
                PFUser.currentUser()!.save()
            }))
        self.presentViewController(alert, animated: true, completion: nil)
        }

        otherUserFriendData.addObject(PFUser.currentUser()!.username!, forKey: "pendingInviters")
        
        let currentUserFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
        currentUserFriendsData.addObject(username, forKey: "pendingInvitees")
        
        currentUserFriendsData.save()
        otherUserFriendData.save()
        
        
        //Alert the invited user that the logged in user has requested them as a friend
        let pushQuery = PFInstallation.query()
        //The installation field "username" is case sensitive
        let nonLoweredUsername = otherUserFriendData["username"] as! String
        pushQuery!.whereKey("username", equalTo: nonLoweredUsername)
        let push = PFPush()
        push.setQuery(pushQuery)
        let message = "\(PFUser.currentUser()!.username!) wants to be friends!"
        let inviteMessage = message as NSString
        let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
        push.setData(pushDict)
        push.sendPushInBackgroundWithBlock(nil)
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //We query via UserFriendsData instead of the User model because then it is one less query when a user requests
        var query = PFQuery(className: "UserFriendsData")
        if searchedString == "" {
            //Then the user is searching users to add, but hasn't entered any text in the search field, so we don't query users yet
            query.limit = 0
        } else {
            //We query for users that have a prefix that matches the text in the searchField
            //We want to search users regardless of capitalization
            query.whereKey("lowerUsername", hasPrefix: searchedString)
        }
        //Look into seeing if the else if and else are both executed
        return query
    }



    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        var friendsData = objects![indexPath.row] as! PFObject
        cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        cell.nameLabel.text = friendsData["lowerUsername"] as? String
        cell.addButton.tag = indexPath.row
        //Users can't add themselves
        if friendsData["lowerUsername"] as! String == PFUser.currentUser()!["lowerUsername"] as! String {
            cell.addButton.enabled = false
            cell.addButton.hidden = true
            cell.nameLabel.text = "Me"
        }
        if contains(users, friendsData["lowerUsername"] as! String) {
            //The user is already friends with the logged in user or the logged in user has already requested them or the other user has already requested the logged in user
            //Setting the addFriendButton with the 'fa-plus-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f196}", forState: .Normal)
            cell.addButton.enabled = false
        } else {
            //The users have not requested or friended each other
            //Setting the addFriendButton with the 'fa-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f096}", forState: .Normal)
            cell.addButton.enabled = true
        }
        return cell
    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        //To prevent recently added users in FriendsViewController from still showing as pending and other similar problems
        let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
        userFriendsData.fetch()
        self.tableView.allowsSelection = false
        
        let friends = userFriendsData["friends"] as! [String]
        let pendingFriends = userFriendsData["pendingInviters"] as! [String]
        let requestedFriends = userFriendsData["pendingInvitees"] as! [String]
        users = friends + pendingFriends + requestedFriends

        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
    }

    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //We want to search users regardless of capitalization
        searchedString = searchBar.text.lowercaseString
        viewDidLoad()
        searchController.setActive(false, animated: true)
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if count(searchBar.text) >= 3 {
            searchBar.enablesReturnKeyAutomatically = true
        } else {
            searchBar.enablesReturnKeyAutomatically = false
        }
        return true
    }
    

    

}
