//
//  FindFriendsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/27/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

/*
Lets users search public groups and join them
*/



import UIKit

class SearchGroupsViewController: PFQueryTableViewController, UISearchBarDelegate, UISearchDisplayDelegate {


    @IBOutlet var searchController: UISearchController!

    
    //Variable for seeing what to search groups for, updates everytime user presses the search button
    var searchedString = ""
    //Variable for keeping track of whether the user has searched yet (for determining whether to show a no results image, but we don't want to do this at first because technically when this view controller loads, we run a query with no results)
    var hasSearched = false

    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        // Configure the PFQueryTableView
        self.parseClassName = "Group"
        self.textKey = "name"
        self.pullToRefreshEnabled = false
        self.paginationEnabled = false
    }

    
    //Takes the tag of the button pressed in the tableViewCell and adds the user to that group's users field
    func joinGroup(sender:UIButton!) {
        let buttonRow = sender.tag
        let group = objects![buttonRow] as! PFObject
        //So that if a user joins before another user has pressed the join group button, they still get the appropriate amount of acorns
        //group.fetch()
        //We want to prevent the user from being able to quickly press the join group button multiple times
        let indexPath = NSIndexPath(forRow: buttonRow, inSection: 0)
        let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! FindUserTableViewCell
        cell.addButton.enabled = false
        
        /*
        PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
        //We add one to take into consideration the logged in user who is accepting
        let numOfUsers = (group["users"] as! [String]).count + 1
        let squirrelSlots = numOfUsers + 2
        group.addObject(PFUser.currentUser()!.username!, forKey: "users")
        group.addObject("\(PFUser.currentUser()!.username!):750", forKey: "acorns")
        group.addObject("\(PFUser.currentUser()!.username!):\(squirrelSlots)", forKey: "squirrelSlots")
        group.addObject("\(PFUser.currentUser()!.username!):1", forKey: "cumulativeDays")
        group.addObject("\(PFUser.currentUser()!.username!):\(numOfUsers)", forKey: "usersOnLastVisit")
        group.addObject("\(PFUser.currentUser()!.username!):0", forKey: "rerates")
        let today = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.stringFromDate(today)
        group.addObject("\(PFUser.currentUser()!.username!):\(todayString)", forKey: "lastVisits")
        group.save()
        */
        if PFUser.currentUser()!["currentGroup"] == nil {
            //This is the user's first group, so we now need to give them access to all tabs after saving this group as their current group - this also means we need to calculate some things syncronously
            PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
            //We add one to take into consideration the logged in user who is accepting
            let numOfUsers = (group["users"] as! [String]).count + 1
            let squirrelSlots = numOfUsers + 2
            group.addObject(PFUser.currentUser()!.username!, forKey: "users")
            group.addObject("\(PFUser.currentUser()!.username!):750", forKey: "acorns")
            group.addObject("\(PFUser.currentUser()!.username!):\(squirrelSlots)", forKey: "squirrelSlots")
            group.addObject("\(PFUser.currentUser()!.username!):1", forKey: "cumulativeDays")
            group.addObject("\(PFUser.currentUser()!.username!):\(numOfUsers)", forKey: "usersOnLastVisit")
            group.addObject("\(PFUser.currentUser()!.username!):0", forKey: "rerates")
            let today = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.stringFromDate(today)
            group.addObject("\(PFUser.currentUser()!.username!):\(todayString)", forKey: "lastVisits")
            group.save()
            PFUser.currentUser()!["currentGroup"] = group
            PFUser.currentUser()!.save()
            //The user can now access all tabs, since they have a current group
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window!.rootViewController = HomeTabViewController()
            appDelegate.window!.makeKeyAndVisible()
        } else {
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                PFUser.currentUser()!.addObject(group.objectId!, forKey: "groups")
                //We add one to take into consideration the logged in user who is accepting
                let numOfUsers = (group["users"] as! [String]).count + 1
                let squirrelSlots = numOfUsers + 2
                group.addObject(PFUser.currentUser()!.username!, forKey: "users")
                group.addObject("\(PFUser.currentUser()!.username!):750", forKey: "acorns")
                group.addObject("\(PFUser.currentUser()!.username!):\(squirrelSlots)", forKey: "squirrelSlots")
                group.addObject("\(PFUser.currentUser()!.username!):1", forKey: "cumulativeDays")
                group.addObject("\(PFUser.currentUser()!.username!):\(numOfUsers)", forKey: "usersOnLastVisit")
                group.addObject("\(PFUser.currentUser()!.username!):0", forKey: "rerates")
                let today = NSDate()
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let todayString = formatter.stringFromDate(today)
                group.addObject("\(PFUser.currentUser()!.username!):\(todayString)", forKey: "lastVisits")
                group.save()
                PFUser.currentUser()!.save()
            }
            //Setting the joinGroupButton with the 'fa-plus-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f196}", forState: .Normal)
        }
        
    }
    
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        let query = PFQuery(className: "Group")
        if searchedString == "" || searchedString.characters.count < 3 {
            //Then the user is searching groups to add, but hasn't entered any text (or not enough characters) in the search field, so we don't query users yet
            query.limit = 0
        } else {
            //We query for groups that are public and that have a prefix that matches the text in the searchField
            query.whereKey("isPublic", equalTo: true)
            query.whereKey("lowercaseName", hasPrefix: searchedString)
        }
        //Look into seeing if the else if and else are both executed
        return query
    }
    
    //For when the user enters in a new text in the search bar
    func reload () {
        self.queryForTable()
        self.loadObjects()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! FindUserTableViewCell
        let group = objects![indexPath.row] as! PFObject
        cell.addButton.addTarget(self, action: "joinGroup:", forControlEvents:  UIControlEvents.TouchUpInside)
        cell.nameLabel.text = group["name"] as? String
        cell.addButton.tag = indexPath.row
        //We use the searched users friends data instead of the logged in friends data for checking their current friend status because this has the highest chance of being up to date, since we just queried this data
        let users = group["users"] as! [String]
        if users.contains(PFUser.currentUser()!.username!) {
            //The user is already a member of this group
            //Setting the joinGroupButton with the 'fa-plus-square-o' button
            cell.addButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 20)
            cell.addButton.setTitle("\u{f196}", forState: .Normal)
            cell.addButton.enabled = false
        } else {
            //The user is not a member of the group
            //Setting the joinGroupButton with the 'fa-square-o' button
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
                emptyLabel.text = "That group doesn't exist"
            }
            emptyLabel.font = UIFont(name: "BebasNeue-Thin", size: 40)
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.textAlignment = .Center
            emptyLabel.adjustsFontSizeToFitWidth = true
            let emptyImageView = UIImageView(frame: CGRectMake(20, 85, 256, 256))
            emptyImageView.center.x = self.tableView.center.x
            emptyImageView.image = UIImage(named: "strawberry")
            //We set tags to make it easy to potentially remove these subviews if the user searches a new group that does have a result
            emptyLabel.tag = 69
            emptyImageView.tag = 70
            self.view.addSubview(emptyLabel)
            self.view.addSubview(emptyImageView)
            self.tableView.addSubview(emptyImageView)
            //Using sepatorStyle doesn't get the separator lines to disappear if there's no objects, so we do this instead
            self.tableView.separatorColor = UIColor.clearColor()
            return 0
        }
        //If the user has searched already and had no results for the last search, since there are results this time, we want to remove the imageview and label we previously created for no results
        for subview in self.tableView.subviews {
            if subview.tag == 69 || subview.tag == 70 {
                subview.removeFromSuperview()
            }
        }
        return objects!.count
    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = false
        tableView.registerNib(UINib(nibName: "FindUserTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
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
