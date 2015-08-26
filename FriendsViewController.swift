//
//  NewFriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 7/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FriendsViewController: UITableViewController {
    
    var friends: [String] = []
    //Variable for keeping track of the current group, if the user is inviting friends to a group
    var group: PFObject?
    //Variable for keep track of whether the user is inviting their friends to the group right now. It's passed as a parameter from UserViewController under performSegue
    var invitingToGroup = false
    //Array of users who have requested the logged in user but the logged in user hasn't accepted yet
    var pendingInviters: [String] = []
    var shouldReload: Bool?
    var users: [String] = []
    let userFriendsData = PFUser.currentUser()!["friendData"] as! PFObject
    
  
    //Button only occurs when user is in their 'Friends' main page under the 'More' tab
    @IBOutlet weak var findFriendsButton: UIBarButtonItem?
    
    @IBAction func findFriends(sender: AnyObject) {
        performSegueWithIdentifier("FindFriends", sender: self)
    }
    
    //Takes the tag of the button pressed in the tableViewCell and adds the user at the index of the objects array to the appropriate data model. Since this is in the FriendsViewController, we know that the logged in user is adding someone who already request them
    func addUser(sender:UIButton!) {
        let buttonRow = sender.tag
        let username = users[buttonRow]
        //We want to prevent the user from being able to quickly press the add friend button multiple times
        let indexPath = NSIndexPath(forRow: buttonRow, inSection: 0)
        var cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FindUserTableViewCell
        cell.addButton.enabled = false
        if invitingToGroup == true {
            createGroupInvite(username)
        } else {
            //The user is accepting a friend request
            //We need to query and get the other user's UserFriendsData
            let query = PFQuery(className: "UserFriendsData")
            query.whereKey("username", equalTo: username)
            //There is only one UserFriendsData instance per user
            //Update the other user's UserFriendsData instance by removing logged in user's username from "requestedUsers" field and adding it to "friends" field
            let otherUserFriendData = query.getFirstObject()
            otherUserFriendData!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingInvitees")
            otherUserFriendData!.addObject(PFUser.currentUser()!.username!, forKey: "friends")
            //Update the current user's UserFriendsData instance by removing username from "requestingUsers" field and adding it to "friends" field
            userFriendsData.removeObject(username, forKey: "pendingInviters")
            userFriendsData.addObject(username, forKey: "friends")
            
            //Updatee the "friendAdded" field to re-sort friends array when appropraite user goes to friends list
            userFriendsData["friendAdded"] = true
            otherUserFriendData!["friendAdded"] = true
        
            userFriendsData.save()
            otherUserFriendData!.save()
            
            //Alert the requester that their friend request has been accepted
            sendPushNotifications(1, "\(PFUser.currentUser()!.username!) has accepted your friend request", "friendRequest", [username])
        }
    }
    
    //Takes a username and checks if the user can invite them to the relevant group
    func canInvite(username: String) -> Bool {
        var users: [String] = []
        if invitingToGroup == true {
            //Check to see if the user is already in the group or has already been invited
            let groupUsers = group!["users"] as! [String]
            let pendingUsers = group!["pendingUsers"] as! [String]
            users = groupUsers + pendingUsers
            
        } else {
            //User is trying to invite them be to friends
            users = friends
        }
        if contains(users, username) {
            //Check to see if the user is already among the user's friends and pending friends or if the user is in the group or has already been invited to it
            return false
        }
        return true
    }
    
    
    //Creates a group invite notification for the invitee
    func createGroupInvite(inviteeUsername: String) {
        var invite = PFObject(className: "GroupInvite")
        invite["inviter"] = PFUser.currentUser()!.username
        invite["invitee"] = inviteeUsername
        invite["group"] = group!
        invite["groupName"] = group!["name"]
        invite.save()
        
        //We need to also add the user's usersname to the currentGroups pending friends, in order to make sure that duplicate invites can't be sent to them
        let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        currentGroup.addObject(inviteeUsername, forKey: "pendingUsers")
        currentGroup.save()
        
        
        //Alert the invited user that they have been invited to a group
        let groupName = group!["name"] as! String
        sendPushNotifications(1, "\(PFUser.currentUser()!.username!) has invited you to join \(groupName)", "groupInvite", [inviteeUsername])
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FindFriends" {
            let controller = segue.destinationViewController as! SearchUsersViewController
        }
    }

    
    //For rare times that a user's name occurs more than once throughout user's friends list, this returns a corrected friends array to be saved. The first element of the return set is a Bool indicating if there are duplicates, and the second element is the array containing no duplicates. 
    func removeDuplicates(array: [String]) -> (Bool, [String]) {
        var encountered = Set<String>()
        var result: [String] = []
        var containsDuplicates = false
        for value in array {
            if encountered.contains(value) {
            // Do not add a duplicate element.
            containsDuplicates = true
            } else {
                // Add value to the set.
                encountered.insert(value)
                // ... Append the value.
                result.append(value)
            }
        }
        return (containsDuplicates, result)
    }
    

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if invitingToGroup == true {
            //Users can't unfriend when they are on the invite to group screen
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        var username = users[indexPath.row]
        cell.nameLabel.text = username
        cell.addButton.tag = indexPath.row
        if canInvite(username){
            //The user variable has not already added to the currentGroup or to the user's friends
            //Setting the addFriendButton with the 'fa-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f096}", forState: .Normal)
            cell.addButton.addTarget(self, action: "addUser:", forControlEvents:  UIControlEvents.TouchUpInside)
            cell.addButton.enabled = true
            cell.addButton.hidden = false
        } else {
            //The user variable has been already invited or added to the currentGroup or to the user's friends
            //Ghetto method for now, need to make it so that the button isn't default
            cell.addButton.enabled = false
            cell.addButton.hidden = true
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let username = users[indexPath.row]
        var title = ""
        if contains(friends, username) {
            title = "Unfriend"
        } else {
            title = "Reject"
        }
        var deleteButton = UITableViewRowAction(style: .Default, title: title, handler: { (action, indexPath) in
            self.tableView.dataSource?.tableView?(
                self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath
            )
        })
        return [deleteButton]
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let username = users[indexPath.row]
            //We need to query and get the other user's UserFriendsData
            let query = PFQuery(className: "UserFriendsData")
            query.whereKey("username", equalTo: username)
            //There is only one UserFriendsData instance per user
            let otherUserFriendData = query.getFirstObject()
            if contains(friends, username) {
                //Then the logged in user is removing this user from their friends list
                userFriendsData.removeObject(username, forKey: "friends")
                //Need to remove the logged in user from the other user's friends list as well
                otherUserFriendData!.removeObject(PFUser.currentUser()!.username!, forKey: "friends")
            } else {
                //The logged in user is rejecting a pending friend request
                //Since we don't know who requested who, we merely remove both users from both potential requesting fields
                userFriendsData.removeObject(username, forKey: "pendingInviters")
                userFriendsData.removeObject(username, forKey: "pendingInvitees")
                //Need to remove the logged in user from the other user's requestedUsers list
                otherUserFriendData!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingInviters")
                otherUserFriendData!.removeObject(PFUser.currentUser()!.username!, forKey: "pendingInvitees")
            }
            userFriendsData.save()
            otherUserFriendData!.save()
            
            users.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
        }
    }
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userFriendsData.fetch()
        //If the logged in user has someone new added to their friends list, we need to re-alphabetize it and save it
        if userFriendsData["friendAdded"] as! Bool == true {
            let friends = userFriendsData["friends"] as! [String]
            let sortedFriends = friends.sorted { $0 < $1 }
            userFriendsData["friends"] = sortedFriends
            userFriendsData["friendAdded"] = false
            userFriendsData.save()
        }
        if invitingToGroup == true {
            //If they are inviting friends to groups, we don't show pending friends
            users = userFriendsData["friends"] as! [String]
            let groupName = group!["name"] as! String
            self.title = "Invite to \(groupName)"
        } else {
            //friends = (userFriendsData["friends"] as! [String]).sorted { $0 < $1 }
            friends = userFriendsData["friends"] as! [String]
            //We only want pending inviters because we don't want to show users that the logged in user has requested
            //pendingInviters = (userFriendsData["pendingInviters"] as! [String]).sorted { $0 < $1 }
            pendingInviters = userFriendsData["pendingInviters"] as! [String]
            users = pendingInviters + friends
            self.title = "Friends"
        }
        let (thereAreDuplicates, friendsArray) = removeDuplicates(friends)
        if thereAreDuplicates == true {
            //We want to save the array that contains no duplicates of friends as the logged in user's friends list
            userFriendsData["friends"] = friendsArray
            userFriendsData.save()
        }
       

        
        //Setting the find friend image, which is 'fa-user-plus'
        findFriendsButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        findFriendsButton?.title = "\u{f234}"
        findFriendsButton?.tintColor = UIColor.orangeColor()
        self.tableView.allowsSelection = false
        //Customize navigation controller back button to only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
    }





}
