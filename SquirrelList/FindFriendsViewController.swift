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

protocol FindFriendsViewControllerDelegate: class {
    func findFriendsViewController(controller: FindFriendsViewController)
}

import UIKit

class FindFriendsViewController: PFQueryTableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    var filteredUsers = [PFUser]()
    
    var delegate: FindFriendsViewControllerDelegate?
    

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
    
    func addFriend (sender:UIButton!) {
        let buttonRow = sender.tag
        //The user that the logged in user is requesting to be friends with
        let friend = filteredUsers[buttonRow]
        PFUser.currentUser().addObject(friend.objectId, forKey: "friends")
        PFUser.currentUser().save()
        delegate?.findFriendsViewController(self)
    }
    
    func filterContentForSearchText(searchText: String) {
        //Filter the array using the filter method
        self.filteredUsers = (self.objects as [PFUser]).filter() {( user: PFUser) -> Bool in
            let stringMatch = (user["username"] as String).rangeOfString(searchText)
            return stringMatch != nil
        }
    }
    
    func isFriend(userID: String) -> Bool {
        if contains(PFUser.currentUser()["friends"] as [String], userID) {
            return true
        }
        return false
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery! {
        var query = PFUser.query()
        query.whereKey("username", notEqualTo: PFUser.currentUser()["username"])
        query.orderByAscending("username")
        return query
    }
    
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
            self.filterContentForSearchText(searchString)
            return true
    }
 
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var user = filteredUsers[indexPath.row]
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as FindFriendsTableViewCell
        cell.nameLabel.text = user["username"] as? String
        if isFriend(user.objectId) {
            //Setting the addFriendButton with the 'fa-plus-square-o' button
            cell.addFriendButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addFriendButton.setTitle("\u{f196}", forState: .Normal)
            cell.addFriendButton.enabled = false
        } else {
            //Setting the addFriendButton with the 'fa-square-o' button
            cell.addFriendButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addFriendButton.setTitle("\u{f096}", forState: .Normal)
        }
        cell.addFriendButton.tag = indexPath.row
        cell.addFriendButton.addTarget(self, action: "addFriend:", forControlEvents:  UIControlEvents.TouchUpInside)
        return cell
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.filteredUsers.count
        } else {
            return 0
        }
    }
    
    
    
     override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "FindFriendsTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
    }

    

}
