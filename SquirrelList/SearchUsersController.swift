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

    /*
    deinit {
        NSNotification.removeObserver(self, forKeyPath: reloadNotificationKey)
    }
    */

    @IBOutlet var searchController: UISearchController!

    
    //Variable for seeing what to search usernames for, updates everytime user presses the search button
    var searchedString = ""
    
    //Variable for storing all of the users' usernames that the logged in user is already friends with, has friended, or has friended them
    var users: [String] = []
    //Variable for keeping track of whether the user has searched yet (for determining whether to show a no results image, but we don't want to do this at first because technically when this view controller loads, we run a query with no results)
    var hasSearched = false
    

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
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
        let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FindUserTableViewCell
        cell.addButton.enabled = false
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        //We update the userFriendsData objects in the background
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            otherUserFriendData.addObject(PFUser.currentUser()!.username!, forKey: "pendingInviters")
            
            let currentUserFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
            currentUserFriendsData.addObject(username, forKey: "pendingInvitees")
        
            currentUserFriendsData.save()
            otherUserFriendData.save()
        
            //Alert the invited user that the logged in user has requested them as a friend
            let nonLoweredUsername = otherUserFriendData["username"] as! String
            sendPushNotifications(1, message: "\(PFUser.currentUser()!.username!) wants to be friends!", type: "friendRequest", users: [nonLoweredUsername])
        }
        //Check to see whether we should prompt the user to enable push notifications
        let hasFriended = PFUser.currentUser()!["hasFriended"] as! Bool
        let hasBeenAskedForPush = PFUser.currentUser()!["hasBeenAskedForPush"] as! Bool
        if  (hasBeenAskedForPush == false) && (hasFriended == false) {
            //This is the first type that the user has friended someone and they haven't enabled push notification, so we can prompt them
            let title = "Let Squirrel List Access Notifications?"
            let message = "You'll be alerted when \(username) has accepted your request. "
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Not Now", style: .Default, handler: { (action: UIAlertAction) -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
                PFUser.currentUser()!["hasFriended"] = true
                PFUser.currentUser()!.save()
            }))
            alert.addAction(UIAlertAction(title: "Give Access", style: .Default, handler: { (action: UIAlertAction) -> Void in
                //We ask the user for push notification permission in chat because it's easier to explain why they might need it
                alert.dismissViewControllerAnimated(true, completion: nil)
                let notificationTypes: UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
                let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
                UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                PFUser.currentUser()!["hasFriended"] = true
                PFUser.currentUser()!["hasBeenAskedForPush"] = true
                PFUser.currentUser()!.save()
            }))
        self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //We query via UserFriendsData instead of the User model because then it is one less query when a user requests
        let query = PFQuery(className: "UserFriendsData")
        if searchedString == "" || searchedString.characters.count < 3 {
            //Then the user is searching users to add, but hasn't entered any text (or not enough characters) in the search field, so we don't query users yet
            query.limit = 0
        } else {
            //We query for users that have a prefix that matches the text in the searchField
            //We want to search users regardless of capitalization
            query.whereKey("lowerUsername", hasPrefix: searchedString)
        }
        //Look into seeing if the else if and else are both executed
        return query
    }
    
    func reload () {
        self.queryForTable()
        self.loadObjects()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        let friendsData = objects![indexPath.row] as! PFObject
        cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        cell.nameLabel.text = friendsData["lowerUsername"] as? String
        cell.addButton.tag = indexPath.row
        //Users can't add themselves
        if friendsData["lowerUsername"] as! String == PFUser.currentUser()!["lowerUsername"] as! String {
            cell.addButton.enabled = false
            cell.addButton.hidden = true
            cell.nameLabel.text = "Me"
        }
        //We use the searched users friends data instead of the logged in friends data for checking their current friend status because this has the highest chance of being up to date, since we just queried this data
        let friends = friendsData["friends"] as! [String]
        let pendingFriends = friendsData["pendingInviters"] as! [String]
        let requestedFriends = friendsData["pendingInvitees"] as! [String]
        let users = friends + pendingFriends + requestedFriends
        if users.contains(PFUser.currentUser()!.username!) {
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //If the user has searched already and had no results for the last search, we want to remove the imageview and label we previously created for no results. We do this for-loop at the top, to remove the label (if we are changing the text from "that user doesn't exist" to "please enter more characters" we don't want the label to pile on top of each other
        for subview in self.tableView.subviews {
            if subview.tag == 69 || subview.tag == 70 {
                subview.removeFromSuperview()
            }
        }
        //Check to see if there are no results, and thus we should display an image and text instead of an empty table view
        if objects!.count == 0 && hasSearched == true {
            let emptyLabel = UILabel(frame: CGRectMake(0, 50, self.view.bounds.size.width, 40))
            if searchedString.characters.count < 3 {
                emptyLabel.text = "Please enter at least three characters"
            } else {
                emptyLabel.text = "That user doesn't exist"
            }
            emptyLabel.font = UIFont(name: "BebasNeue-Thin", size: 40)
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.textAlignment = .Center
            emptyLabel.adjustsFontSizeToFitWidth = true
            let emptyImageView = UIImageView(frame: CGRectMake(20, 85, 256, 256))
            emptyImageView.center.x = self.tableView.center.x
            emptyImageView.image = UIImage(named: "watermelon")
            //We set tags to make it easy to potentialyl remove these subviews if the user searches a new group that does have a result
            emptyLabel.tag = 69
            emptyImageView.tag = 70
            self.view.addSubview(emptyLabel)
            self.view.addSubview(emptyImageView)
            self.tableView.addSubview(emptyImageView)
            //Using sepatorStyle doesn't get the separator lines to disappear if there's no objects, so we do this instead
            self.tableView.separatorColor = UIColor.clearColor()
            return 0
        }
        return objects!.count
    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = false
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
    }


    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //If there are no results, we want to display an image, so we upate our variable for determining whether we should display a no results image
        hasSearched = true
        //We want to search users regardless of capitalization
        searchedString = searchBar.text!.lowercaseString
        reload()
        searchController.active = false
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if searchBar.text!.characters.count >= 3 {
            searchBar.enablesReturnKeyAutomatically = true
        } else {
            searchBar.enablesReturnKeyAutomatically = false
        }
        return true
    }
    

    

}
