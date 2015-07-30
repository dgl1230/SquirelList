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

class NewSearchUsersViewController: PFQueryTableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

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
        let user = objects![buttonRow] as! PFUser
        //We need to check and see if a friend request already exists
        //We need to query and get the other user's UserFriendsData
        let query = PFQuery(className: "UserFriendsData")
        query.whereKey("username", equalTo: user.username!)
        //There is only one UserFriendsData instance per user
        let otherUserFriendData = query.getFirstObject()
        otherUserFriendData!.addObject(PFUser.currentUser()!.username!, forKey: "pendingInviters")
        
        let currentUserFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
        currentUserFriendsData.addObject(user.username!, forKey: "pendingInvitees")
        
        currentUserFriendsData.save()
        otherUserFriendData!.save()
        
        //Alert the invited user that the logged in user has requested them as a friend
        let pushQuery = PFInstallation.query()
        pushQuery!.whereKey("userID", equalTo: user.username!)
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
        var query = PFUser.query()
        if searchedString == "" {
            //Then the user is searching users to add, but hasn't entered any text in the search field, so we don't query users yet
            query!.limit = 0
        } else {
            //We query for users that have a prefix that matches the text in the searchField
            //query?.whereKey("username", notEqualTo: PFUser.currentUser()!["username"]!)
            query?.whereKey("username", equalTo: searchedString)
            query?.orderByAscending("username")
        }
        //Look into seeing if the else if and else are both executed
        return query!
    }

    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var user: PFUser
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        user = objects![indexPath.row] as! PFUser
        cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        cell.nameLabel.text = user["username"] as? String
        cell.addButton.tag = indexPath.row
        if contains(users, user.username!) {
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
        }
        return cell
    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        //To prevent recently added users in FriendsViewController from still showing as pending and other similar problems
        let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
        userFriendsData.fetch()
        
        let friends = userFriendsData["friends"] as! [String]
        let pendingFriends = userFriendsData["pendingInviters"] as! [String]
        let requestedFriends = userFriendsData["pendingInvitees"] as! [String]
        users = friends + pendingFriends + requestedFriends

        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
    }
    
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchedString = searchBar.text
        viewDidLoad()
        searchController.setActive(false, animated: true)
    }

    

}
