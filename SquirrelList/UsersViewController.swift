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

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "reloadWithNewGroup", object: nil)
    }

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
            let controller = segue.destinationViewController as! FriendsViewController
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
        if segue.identifier == "NewUserScreens" {
            let controller = segue.destinationViewController as! TutorialViewController
            controller.typeOfContent = "user"
        }
    }
    
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //The optional currentGroup needs to be called here, because queryForTable() is called before viewDidLoad()
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        var query = PFUser.query()
        query!.whereKey("username", containedIn: currentGroup!["users"] as! [String])
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
        //Check to see if this is another day that they've consecutively checked this group
        if contains(alerts, "cumulativeDay") == true {
            let lastCheckedDateString = getUserInfo(currentGroup!["lastVisits"] as! [String], PFUser.currentUser()!.username!)
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let lastCheckedDate = formatter.dateFromString(lastCheckedDateString)
            let today = NSDate()
            let daysApart = dayDifferences(lastCheckedDate!, date2: today)
            //Then this is a cumulative day for the user
            var cumulativeDays = getUserInfo(currentGroup!["cumulativeDays"] as! [String], PFUser.currentUser()!.username!).toInt()
            cumulativeDays! += 1
            //var acorns = userGroupData!["acorns"] as! Int
            var acorns = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
            acorns! += 20
            //let squirrelScore = userGroupData!["squirrelSlots"] as! Int
            let squirrelSlots = getUserInfo(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
            let groupName = PFUser.currentUser()!["currentGroup"]!["name"] as! String
            var message = "Here's 20 acorns for visiting \(groupName) everyday!"
            //Reward them for having a full squirrel team
            if squirrelSlots == 0 {
                acorns! += 20
                message = "Here's 40 acorns for visiting \(groupName) daily and having a full squirrel team!"
            }
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                //Update and save userGroupData
                var newLastVisits = getNewArrayToSave(self.currentGroup!["lastVisits"] as! [String], PFUser.currentUser()!.username!, formatter.stringFromDate(today))
                self.currentGroup!["lastVisits"] = newLastVisits
                var newCumulativeVisits = getNewArrayToSave(self.currentGroup!["cumulativeDays"] as! [String], PFUser.currentUser()!.username!, String(cumulativeDays!))
                self.currentGroup!["cumulativeDays"] = newCumulativeVisits
                var newAcorns = getNewArrayToSave(self.currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!, String(acorns!))
                self.currentGroup!["acorns"] = newAcorns
                self.currentGroup!.save()
                self.alerts.removeAtIndex(0)
                //We recursively call showAlerts() until the alerts array is empty
                self.showAlerts()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        //Check to see if this is a lucky day for the user
        //"lucky" is only appended to this array if the user is visiting groups daily
        if contains(alerts, "lucky") == true {
            var message = "It's your lucky day! Here's 100 acorns!"
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                //Update and save userGroupData
                var acorns = getUserInfo(self.currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()
                //var acorns = self.userGroupData!["acorns"] as! Int
                acorns! += 100
                var newAcorns = getNewArrayToSave(self.currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!, String(acorns!))
                self.currentGroup!["acorns"] = newAcorns
                self.currentGroup!.save()
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
        
        //We check to see if the user has been recently given a strike for offensive content
        if PFUser.currentUser()!["recentStrike"] as! Bool == true {
            alerts.append("recentStrike")
        }

        //Check to see if this is another day that they've consecutively checked this group
        let lastCheckedDateString = getUserInfo(currentGroup!["lastVisits"] as! [String], PFUser.currentUser()!.username!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let lastCheckedDate = formatter.dateFromString(lastCheckedDateString)
        //let lastCheckedDate = userGroupData!["lastVisit"] as! NSDate
        let today = NSDate()
        let daysApart = dayDifferences(lastCheckedDate!, date2: today)
        if daysApart == 1 {
            alerts.append("cumulativeDay")
            //Check to see if we're going to randomly award the user because they are lucky today
            let randomLuckyNumber = Int(arc4random_uniform(100))
            if randomLuckyNumber <= 5 {
                alerts.append("lucky")
        }
        } else if daysApart != 0 {
            //They haven't visited this group in more than a day, and so we need to update their last visit
            let todayString = formatter.stringFromDate(today)
            let newLastVisits = getNewArrayToSave(currentGroup!["lastVisits"] as! [String], PFUser.currentUser()!.username!, todayString)
            currentGroup!["lastVisits"] = newLastVisits
            currentGroup!.save()
        }
        if alerts.count > 0 {
            showAlerts()
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //If we don't show Tutorial Screens from here we get a "Presenting view controllers on detached view controllers is discouraged" warning
        //Check to see if we need to show a new user tutorial screens first
        if PFUser.currentUser()!["newUserTab"] as! Bool == true {
            performSegueWithIdentifier("NewUserScreens", sender: self)
        }
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
    }
    

}

