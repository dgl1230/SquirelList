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
    
    //Variable for seeing what to search usernames for, updates everytime user changes the text in the search field
    var searchParameters = ""
    
    //Optional for determining if User is adding a friend to the group. If they are, then we don't want to be querying all users, only their friends
    var addingToGroup: Bool?
    
    //Optional for if the user is being added to a group 
    var group: PFObject?
    
    //Optional for determining if the user has started searching - this optional is used for seeing if the user is adding someone to a group, whether we should be pulling from filteredUsers or objects
    var hasNotFiltered = true
    
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    
    

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
        if addingToGroup == true {
            //We need to add the user at the objects index to the logged in user's current group
            let user = filteredUsers[buttonRow]
            createGroupInvite(user.objectId!)
        } else {
            //We need to check and see if a friend request already exists
            let user = filteredUsers[buttonRow]

            var query1 = PFQuery(className: "FriendRequest")
            query1.whereKey("RequestTo", equalTo: PFUser.currentUser()!)
            query1.whereKey("RequestFrom", equalTo: user)
        
            var query2 = PFQuery(className: "FriendRequest")
            query2.whereKey("RequestTo", equalTo: user)
            query2.whereKey("RequestFrom", equalTo: PFUser.currentUser()!)
            
            var query = PFQuery.orQueryWithSubqueries([query1, query2])
            query.findObjectsInBackgroundWithBlock({ (results: [AnyObject]?, error: NSError?) -> Void in
                    if error == nil {
                        if results?.count > 0 {
                            //Then there was already a friend request and there should only be one request
                            var request = results![0] as! PFObject
                            request["status"] = "accepted"
                            PFUser.currentUser()!.addObject(user.objectId!, forKey: "friends")
                            PFUser.currentUser()!.removeObject(user.objectId!, forKey: "pendingFriends")
                            PFUser.currentUser()!.save()
                            request.save()
                        }
                        else {
                            //We need to create a friend request
                            var request = PFObject(className: "FriendRequest")
                            request["RequestFrom"] = PFUser.currentUser()!
                            request["requestFromUsername"] = PFUser.currentUser()!.username
                            request["RequestTo"] = user
                            request["requestToUsername"] = user.username
                            request["status"] = "pending"
                            request["requestToUserId"] = user.objectId
                            request["requestFromUserId"] = PFUser.currentUser()!.objectId
                            PFUser.currentUser()!.addObject(user.objectId!, forKey: "pendingFriends")
                            PFUser.currentUser()!.save()
                            request.save()
                        }
                    }
            })
        }
    }
    
    
    //Weird workout function for adding a user if the logged in user hasn't started searching through users yet
    func addUserNoFilter(sender:UIButton!) {
        //We assume the addingToGroup optional is true because a user searching to add friends will not see any users initially 
        let buttonRow = sender.tag
        let user = objects![buttonRow] as! PFUser
        createGroupInvite(user.objectId!)
    }
    
    //Creates a group invite notification for the invitee
    func createGroupInvite(invitee: String) {
        var invite = PFObject(className: "GroupInvite")
        invite["inviter"] = PFUser.currentUser()!.username
        invite["invitee"] = invitee
        invite["group"] = group!
        invite["groupName"] = group!["name"]
        
        invite.save()
        
    }
    
    func filterContentForSearchText(searchText: String) {
        //Filter the array using the filter method
        hasNotFiltered = false
        self.filteredUsers = (self.objects as! [PFUser]).filter() {( user: PFUser) -> Bool in
            let stringMatch = (user["lowerUsername"] as! String).rangeOfString(searchText)
            return stringMatch != nil
        }
    }
    
    //Takes a userID and checks if it is in relevant group
    func isAdded(username: String) -> Bool {
        var users: [String] = []
        group = PFUser.currentUser()!["currentGroup"] as? PFObject
        if addingToGroup == true {
            //Check to see if an invite has already been sent to the user
            var query = PFQuery(className: "GroupInvite")
            query.whereKey("group", equalTo: group!)
            query.whereKey("invitee", equalTo: username)
            var results = query.countObjects()
            if results > 0 {
                return true
            }
            //We're checking to see if a user's friend is in their current group
            users = group!["userIDs"] as! [String]
        } else {
            //We're checking if a user is friends with someone
            var friends = PFUser.currentUser()!["friends"] as! [String]
            var pendingFriends = PFUser.currentUser()!["pendingFriends"] as! [String]
            users = friends + pendingFriends
        }
        if contains(users, username) {
            //Check to see if the user is already in the group's users or among the user's friends and pending friends
            return true
        }
        return false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        var query = PFUser.query()
        if addingToGroup == true {
            //The user has friends and we should list them to be invited to a group
            if PFUser.currentUser()!["friends"] != nil {
                query!.whereKey("objectId", containedIn: PFUser.currentUser()!["friends"] as! [String])
            }
        } else if searchParameters == "" {
            println("search paramters empty old chap")
            //Then the user is searching users to add, but hasn't entered any text in the search field, so we don't query users yet
        } else {
            println("search paramters not empty old chap")
            println("the search paramters are: \(searchParameters)")
            //We query for users that have a prefix that matches the text in the searchField
            query?.whereKey("username", notEqualTo: PFUser.currentUser()!["username"]!)
            //query?.whereKey("username", hasPrefix: searchParameters)
            query?.orderByAscending("username")
        }
        //Look into seeing if the else if and else are both executed
        return query!
    }
    
     //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
            self.filterContentForSearchText(searchString.lowercaseString)
            //println("shouldReloadForSearchString")
            //searchParameters = searchString
            //queryForTable()
            //loadObjects()
        
            
            //println("the number of objects now is \(objects!.count)")
            return true
    }
    
    /*
    override func objectsDidLoad(error: NSError?) {
        super.objectsDidLoad(error)
        self.tableView.numberOfRowsInSection(objects!.count)
        self.tableView.reloadData()
    }
    */
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        println("cellForRowAtIndexPath")
        var user: PFUser
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        if tableView == self.searchDisplayController!.searchResultsTableView {
            //If the user is typing in the search bar, we only display users in the filteredUsers array
            user = filteredUsers[indexPath.row]
            cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
        } else {
            //Else we display all users in the objects array
            user = objects![indexPath.row] as! PFUser
            //We need a function that accesses the objects array if we're adding users before a search is performed
            cell.addButton.addTarget(self, action: "addUserNoFilter:", forControlEvents: UIControlEvents.TouchUpInside)
        }
        cell.nameLabel.text = user["username"] as? String
        cell.addButton.tag = indexPath.row
        if isAdded(user.username!) {
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
        println("the number of rows in the section are: \(section)")
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredUsers.count
        } else if addingToGroup == true {
            //If the user is inviting friends to a group, we want to show all of their friends immediately on the screen
            return self.objects!.count
        } else {
            println("going to else")
            //Else they are searching for friends, so the tableView shouldn't be populated with every user
            //return objects!.count
            return 0
        }
    }
    
    
     override func viewDidLoad() {
        super.viewDidLoad()
        //To prevent recently added users in FriendsViewController from still showing as pending and other similar problems 
        PFUser.currentUser()?.fetch()
        if addingToGroup == true {
            //Configure the title to have the user's current group in it
            var currentGroup = PFUser.currentUser()!["currentGroup"]!["name"]! as! String
            self.title = "Invite to \(currentGroup)"
        }
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
    }
    
    
     override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }

    

}
