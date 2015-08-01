//
//  UsersViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//Controller for the User's Tab 

import UIKit

//Notification specific string
let reloadNotificationKey = "com.denis.reloadNotificationKey"
//Notification string for reloading individualGroupData
let reloadIndividualGroupData = "com.denis.reloadIndividualGroupData"


class UsersViewController: PFQueryTableViewController {

    var currentGroup: PFObject?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    //Variable for storing potential alerts for the user - values it can hold are: "recentStrike", "newUsers", and "cumulativeDay"
    var alerts: [String] = []

    @IBOutlet weak var addFriendToGroupButton: UIBarButtonItem?
    @IBOutlet weak var changeCurrentGroupButton: UIBarButtonItem?
    
    
    @IBAction func addFriendToGroup(sender: AnyObject) {
        self.performSegueWithIdentifier("AddFriendToGroup", sender: self)
    }
    

    @IBAction func changeCurrentGroup(sender: AnyObject) {
        self.performSegueWithIdentifier("ChangeCurrentGroup", sender: self)
    }
    
    
    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
    
    //Takes two dates and returns the number of days between them. Does not account for hours
    func dayDifferences(date1: NSDate, date2: NSDate) -> Int {
        let calendar = NSCalendar.currentCalendar()
        //let flags = NSCalendarUnit.DayCalendarUnit
        let unit: NSCalendarUnit = NSCalendarUnit.CalendarUnitDay
        //We want to only be comparing days, not hours
        let d1 = calendar.startOfDayForDate(date1)
        let d2 = calendar.startOfDayForDate(date2)
        let components = calendar.components(unit, fromDate: d1, toDate: d2, options: nil)
        return components.day
    }
	
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "User"
        self.textKey = "username"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddFriendToGroup" {
            let controller = segue.destinationViewController as! NewFriendsViewController
            controller.invitingToGroup = true
            controller.group = PFUser.currentUser()!["currentGroup"] as? PFObject
        }
        if segue.identifier == "ChangeCurrentGroup" {
            let controller = segue.destinationViewController as! ChangeCurrentGroupViewController
            //controller.delegate = self
        }
        if segue.identifier == "SingleUserSquirrels" {
            let controller = segue.destinationViewController as! SquirrelViewController
            controller.selectedUser = sender as? PFUser
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //The optional currentGroup needs to be called here, because queryForTable() is called before viewDidLoad()
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        /*
        PFUser.currentUser()!.removeObjectForKey("currentGroup")
        PFUser.currentUser()!.removeObjectForKey("currentGroupData")
        PFUser.currentUser()!.save()
        */
        
        var query = PFUser.query()
        query!.whereKey("username", containedIn: currentGroup!["userIDs"] as! [String])
        query!.orderByAscending("username")
        return query!
    }
    
     //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    //Recursively shows the prompts to the user, depending upon the data in the alerts array
    func showAlerts() {
        if alerts.count == 0 {
            return
        }
         //We check to see if the user has been recently given a strike for offensive content
        if contains(alerts, "recentStrike") == true {
            let query  = PFQuery(className: "Report")
            query.whereKey("offendingUsername", equalTo: PFUser.currentUser()!.username!)
            let report = query.getFirstObject()
            let warning = report!["warningToOffender"] as! String
            var alert = UIAlertController(title: "This is a warning for posting offensive material", message: warning, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                PFUser.currentUser()!["recentStrike"] = false
                PFUser.currentUser()!.save()
                self.alerts.removeAtIndex(0)
                //We recursively call showAlerts() until the alerts array is empty
                self.showAlerts()
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        //It's already been fetched by this point in viewDidLoad, so we don't need to again
        let userGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
        //Check to see if we should alert them that their are new members in their group (and thus they have more Squirrel Slots)
        if contains(alerts, "newUSers") {
            let numOfUsers = (currentGroup!["userIDs"] as! [String]).count
            let oldNumOfUsers = userGroupData["numOfGroupUsers"] as! Int
            //Then new users have joined the group
            let numOFNewUsers = numOfUsers - oldNumOfUsers
            var squirrelSlots = userGroupData["squirrelSlots"] as! Int
            squirrelSlots += numOFNewUsers
            //Show popup
            var message = ""
            if numOFNewUsers == 1 {
                message = "One new user has joined, so enjoy one more Squirrel Slot!"
            } else {
                message = "\(numOFNewUsers) have joined, so enjoy \(numOFNewUsers) squirrel slots!"
            }
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                userGroupData["numOfGroupUsers"] = numOfUsers
                userGroupData["squirrelSlots"] = squirrelSlots
                userGroupData.save()
                self.alerts.removeAtIndex(0)
                //We recursively call showAlerts() until the alerts array is empty
                self.showAlerts()
                }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        //Check to see if this is another day that they've consecutively checked this group
        if contains(alerts, "cumulativeDay") == true {
            let lastCheckedDate = userGroupData["lastVisit"] as! NSDate
            let today = NSDate()
            let daysApart = dayDifferences(lastCheckedDate, date2: today)
            //Then this is a cumulative day for the user
            var cumulativeDays = userGroupData["cumulativeDaysVisited"] as! Int
            cumulativeDays += 1
            var acorns = userGroupData["acorns"] as! Int
            acorns += 25
            let squirrelScore = userGroupData["squirrelSlots"] as! Int
            let groupName = PFUser.currentUser()!["currentGroup"]!["name"] as! String
            var message = "Here's 25 acorns for visiting \(groupName) everyday!"
            //Reward them for having a full squirrel team
            if squirrelScore == 0 {
                acorns += 25
                message = "Here's 50 acorns for visiting \(groupName) daily and having a full squirrel team!"
            }
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                //Update and save userGroupData
                userGroupData["lastVisit"] = today
                userGroupData["cumulitveDaysVisited"] = cumulativeDays
                userGroupData["acorns"] = acorns
                userGroupData.save()
                self.alerts.removeAtIndex(0)
                //We recursively call showAlerts() until the alerts array is empty
                self.showAlerts()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UsersCellTableViewCell
        let name = objects![indexPath.row]["name"] as? String
        //It looks strange to have the row highlighted in gray
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        if (objects![indexPath.row]["username"] as? String == PFUser.currentUser()!.username) {
             cell.usernameLabel.text = "me"
        }
        else if name != nil {
            cell.usernameLabel.text = objects![indexPath.row]["name"] as? String
        } else {
            cell.usernameLabel.text = objects![indexPath.row]["username"] as? String
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        self.performSegueWithIdentifier("SingleUserSquirrels", sender: objects![indexPath.row])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if PFUser.currentUser()!["friendData"] == nil {
            let q = PFQuery(className: "UserFriendsData")
            q.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            let friendData = q.getFirstObject()
            PFUser.currentUser()!["friendData"] = friendData
            PFUser.currentUser()!.save()
            PFUser.currentUser()!.fetch()
        }
        currentGroup = PFUser.currentUser()!["currentGroup"]! as? PFObject
        currentGroup!.fetch()
        //Set the addFriendToGroupButton to 'fa-user-plus
        addFriendToGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        addFriendToGroupButton?.title = "\u{f234}"
        addFriendToGroupButton?.tintColor = UIColor.orangeColor()
        //Set the changeCurrentGroupButton to 'fa-bars'
        changeCurrentGroupButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        changeCurrentGroupButton?.title = "\u{f0c9}"
        changeCurrentGroupButton?.tintColor = UIColor.orangeColor()
        
        self.title = currentGroup!["name"] as? String
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        //Register the UsersCellTableViewCell for use in the UserViewController tableView
        tableView.registerNib(UINib(nibName: "UsersCellTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        //Check to see if we need to show a new user tutorial screens first
        if PFUser.currentUser()!["newUserTab"] as! Bool == true {
            //If new user, show them the tutorial screens
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let tutorialTestStoryBoard = UIStoryboard(name: "Tutorial", bundle: nil)
            let contentController = tutorialTestStoryBoard.instantiateViewControllerWithIdentifier("ContentViewController") as! TutorialViewController
            contentController.typeOfContent = "user"
            appDelegate.window!.rootViewController = contentController
            appDelegate.window!.makeKeyAndVisible()
        }
        //We check to see if the user has been recently given a strike for offensive content
        if PFUser.currentUser()!["recentStrike"] as! Bool == true {
            alerts.append("recentStrike")
        }
        //Check to see if we should alert them that their are new members in their group (and thus they have more Squirrel Slots)
        let numOfUsers = (currentGroup!["userIDs"] as! [String]).count
        let userGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
        userGroupData.fetch()
        let oldNumOfUsers = userGroupData["numOfGroupUsers"] as! Int
        if numOfUsers > oldNumOfUsers {
           alerts.append("newUSers")
        }
        //Check to see if this is another day that they've consecutively checked this group
        let lastCheckedDate = userGroupData["lastVisit"] as! NSDate
        let today = NSDate()
        let daysApart = dayDifferences(lastCheckedDate, date2: today)
        if daysApart == 1 {
            alerts.append("cumulativeDay")
        } else if daysApart != 0 {
            //They haven't visited this group in more than a day, and so we need to update their last visit
            userGroupData["lastVisit"] = today
            userGroupData["cumulitveDaysVisited"] = 0
            userGroupData.save()
        }
        if alerts.count > 0 {
            showAlerts()
        }
        
        
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    

}

