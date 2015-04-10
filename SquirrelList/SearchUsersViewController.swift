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

    var filteredUsers = [PFUser]()
    
    //Optional for determining if User is adding a friend to the group. If they are, then we don't want to be querying all users, only their friends
    var addingToGroup: Bool?
    
    //Optional for if the user is being added to a group 
    var group: PFObject?
    
    //Optional for determining if the user has started searching - this optional is used for seeing if the user is adding someone to a group, whether we should be pulling from filteredUsers or objects
    var hasNotFiltered = true
    
    

    // Initialise the PFQueryTable tableview
    override init!(style: UITableViewStyle, className: String!) {
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
        if addingToGroup? == true {
            //We need to add the user at the objects index to the logged in user's current group
            let user = filteredUsers[buttonRow]
            //group?.addObject(user.objectId as String, forKey: "userIDs")
            //group?.save()
            createGroupInvite(user.objectId)
        } else {
            //We need to add the user to the logged in user's friends
            let user = filteredUsers[buttonRow]
            PFUser.currentUser().addObject(user.objectId, forKey: "friends")
            PFUser.currentUser().save()
        }
    }
    
    //Weird workout function for adding a user if the logged in user hasn't started searching through users yet
    func addUserNoFilter(sender:UIButton!) {
        //We assume the addingToGroup optional is true because a user searching to add friends will not see any users initially 
        let buttonRow = sender.tag
        let user = objects[buttonRow] as PFUser
        //group?.addObject(user.objectId as String, forKey: "userIDs")
        //group?.save()
        createGroupInvite(user.objectId)
    }
    
    //Creates a group invite notification for the invitee
    func createGroupInvite(invitee: String) {
        var invite = PFObject(className: "GroupInvite")
        invite["inviter"] = PFUser.currentUser().username
        invite["invitee"] = invitee
        invite["group"] = group!
        invite["groupName"] = group!["name"]
        
        invite.save()
        
    }
    
    func filterContentForSearchText(searchText: String) {
        //Filter the array using the filter method
        hasNotFiltered = false
        self.filteredUsers = (self.objects as [PFUser]).filter() {( user: PFUser) -> Bool in
            let stringMatch = (user["username"] as String).rangeOfString(searchText)
            return stringMatch != nil
        }
    }
    
    //Takes a userID and checks if it is in relevant group
    func isAdded(userID: String) -> Bool {
        var users: [String] = []
        if addingToGroup? == true {
            //Check to see if an invite has already been sent to the user
            var query = PFQuery(className: "GroupInvite")
            query.whereKey("group", equalTo: group)
            query.whereKey("invitee", equalTo: userID)
            var results = query.countObjects()
            if results > 0 {
                return true
            }
            //We're checking to see if a user's friend is in their current group
            users = group!["userIDs"] as [String]
        } else {
            //We're checking if a user is friends with someone
            users = PFUser.currentUser()["friends"] as [String]
        }
        if contains(users, userID) {
            return true
        }
        return false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFUser.query()
        if addingToGroup? == true {
            //We want to just query the logged in user's friends
            query.whereKey("objectId", containedIn: PFUser.currentUser()["friends"] as [String])
        } else {
            //We need to query all users, for logged in user to add some as friends
            query.whereKey("username", notEqualTo: PFUser.currentUser()["username"])
        }
        query.orderByAscending("username")
        return query
    }
    
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
            self.filterContentForSearchText(searchString)
            return true
    }
 
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var user: PFUser
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as FindUserTableViewCell
        if tableView == self.searchDisplayController!.searchResultsTableView {
            //If the user is typing in the search bar, we only display users in the filteredUsers array
            user = filteredUsers[indexPath.row]
            cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        } else {
            //Else we display all users in the objects array
            user = objects[indexPath.row] as PFUser
            //We need a function that accesses the objects array if we're adding users before a search is performed
            cell.addButton.addTarget(self, action: "addUserNoFilter:", forControlEvents: UIControlEvents.TouchUpInside)
        }
        cell.nameLabel.text = user["username"] as? String
        cell.addButton.tag = indexPath.row
        if isAdded(user.objectId) {
            //The user variable has been already added to the relevant group
            //Setting the addFriendButton with the 'fa-plus-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f196}", forState: .Normal)
            cell.addButton.enabled = false
        } else {
            //The user variable has not already added to the relevant group
            //Setting the addFriendButton with the 'fa-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f096}", forState: .Normal)
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredUsers.count
        } else if addingToGroup? == true {
            //If the user is inviting friends to a group, we want to show all of their friends immediately on the screen
            return self.objects.count
        } else {
            //Else they are searching for friends, so the tableView shouldn't be populated with every user
            return 0
        }
        
    }
    
    
    
     override func viewDidLoad() {
        super.viewDidLoad()
        if addingToGroup? == true {
            //Get the current group and fetch it to have the most current data
            group = PFUser.currentUser()["currentGroup"] as? PFObject
            group?.fetch()
            //Configure the title to have the user's current group in it
            var currentGroup = PFUser.currentUser()["current_group"] as String
            self.title = "Invite friends to \(currentGroup)"
        }
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
    }

    

}
