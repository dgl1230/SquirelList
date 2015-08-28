//
//  SquirrelTabViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 8/26/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit


class SquirrelTabViewController: PFQueryTableViewController, NewSquirrelDetailslViewControllerDelegate, AddSquirrelViewControllerDelegate {

    deinit {
        //We remove the observers for reloading the controller
        NSNotificationCenter.defaultCenter().removeObserver(self, name: reloadSquirrels, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: reloadNotificationKey, object: nil)
    }

    //Optional for storing the logged in user's current group
    var currentGroup: PFObject?
    //Variable for keeping track of whether the SquirrelTabViewController should reload
    var shouldReload = false

    @IBOutlet weak var acornsLabel: UILabel!
    @IBOutlet weak var squirrelSlotsLabel: UILabel!
    @IBOutlet weak var addSquirrelButton: UIBarButtonItem!
    @IBOutlet weak var tradeOfferButton: UIBarButtonItem!
    
    
    @IBAction func addSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("AddSquirrel", sender: self)
        // So that user can't quickly press the button and have multiple addSquirrel screens
        addSquirrelButton!.enabled = false
    }


    @IBAction func viewTradeOffers(sender: AnyObject) {
        self.performSegueWithIdentifier("TradeOffers", sender: self)
        // So that the user can't quickly press the trade button again and have multiple screens
        tradeOfferButton.enabled = false
    }
    
    
    // Initialise the PFQueryTable tableview
    override init(style: UITableViewStyle, className: String!) {
        super.init(style: style, className: className)
    }
	
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
  
        // Configure the PFQueryTableView
        self.parseClassName = "Squirrel"
        self.textKey = "first_name"
        self.pullToRefreshEnabled = true
        self.paginationEnabled = false
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSquirrel" {
            let controller = segue.destinationViewController as! AddSquirrelViewController
            //we need to transer the array of names so that we can make sure the user isn't creating a duplicate squirrel
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as! NewSquirrelDetailsViewController
            controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            var squirrelSlots = getUserInfo(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
            controller.squirrelSlots = squirrelSlots
            let userRerates = getUserInfo(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!).toInt()
            if userRerates == 1 {
                controller.canRerate = true
            } else {
                controller.canRerate = false
            }
            let owner = sender!["owner"] as? PFObject
            if owner != nil {
                var user = sender!["owner"] as? PFUser
                controller.squirrelOwner = user
            }
        }
        if segue.identifier == "TradeOffers" {
            let controller = segue.destinationViewController as! NotificationsViewController
        }
        if segue.identifier == "NewUserScreens" {
            let controller = segue.destinationViewController as! TutorialViewController
            controller.typeOfContent = "squirrel"
        }
    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        //We set the currentGroup optional here, since this is the first place where it needs to be used
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        var query = PFQuery(className: "Squirrel")
        //query.cachePolicy = .CacheElseNetwork
        query.whereKey("objectId", containedIn: currentGroup!["squirrels"] as! [String])
        query.orderByDescending("avg_rating")
        return query
    }
    
    //Reload the objects and checks if there are new users and updates all labels
    func reload() {
        self.loadObjects()
        updateLables()
        updateSquirrelSlots()
    }
    
    
    func prepareForReload() {
        if self.view.window == nil {
            //The user is not currently on the screen, so we just make a note to refresh later
            shouldReload = true
        } else {
            //Else the user is on the Squirrels tab right now, and we should reload
            reload()
        }
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {
            var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PFTableViewCell
            //It looks strange to have the row highlighted in gray 
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            var openLabel = cell.viewWithTag(6) as? UILabel
            var first = cell.viewWithTag(1) as! UILabel
            first.text = object!["first_name"]!.capitalizedString
            //For some reason 2 is already being used as another tag
            var last = cell.viewWithTag(5) as! UILabel
            last.text = object!["last_name"]!.capitalizedString
            var ratingLabel = cell.viewWithTag(3) as! UILabel
            var avgRating = object!["avg_rating"] as! Double
            var squirrel = objects![indexPath.row] as! PFObject
            var owner = squirrel["owner"] as? PFUser
            if owner == nil {
                openLabel?.hidden = false
            } else {
                openLabel?.hidden = true
            }
        
            if avgRating != 0 && avgRating >= 9 {
                ratingLabel.text = "\(avgRating)"
                cell.backgroundColor = UIColor.redColor()
            } else if avgRating != 0 && avgRating >= 8 {
                ratingLabel.text = "\(avgRating)"
                cell.backgroundColor = UIColor.orangeColor()
            }else {
                //For some reason not setting unrated squirrels color to black, leads to them sometimes being other colors, despite 
                ratingLabel.text = ""
                cell.backgroundColor = UIColor.yellowColor()
            }
            return cell
    }
    
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let squirrel = objects![indexPath.row] as! PFObject
            var message = ""
            var owner = squirrel["ownerUsername"] as? String
            //Users need to drop their own squirrels before they delete them
            if owner == PFUser.currentUser()!.username! {
                message = "Whoa there! If you want to delete your squirrel, drop them from your team first"
                displayAlert(self, "", message)
                return
            }
            //Users can't delete squirrels with an owner
            if squirrel["ownerUsername"] != nil  {
                message = "Only squirrels that are ownerless can be deleted! This is someone's beloved squirrel. What's wrong with you?"
                displayAlert(self, "", message)
                return
            }
            //Check to see if the user already voted to drop the Squirrel
            let droppers = squirrel["droppers"] as! [String]
            if find(droppers, PFUser.currentUser()!.username!) != nil {
                message = "You already voted to delete this squirrel! Just leave it alone."
                displayAlert(self, "My Bad", message)
                return
            }
            let firstName = (squirrel["first_name"] as! String).lowercaseString
            let lastName = (squirrel["last_name"] as! String).lowercaseString
            let fullName = "\(firstName) \(lastName)"
            let group = PFUser.currentUser()!["currentGroup"] as! PFObject
            let numOfUsers = (group["users"] as! [String]).count
            //We get half of the users to see if this user will be the deciding vote to drop the squirrel (dropping a squirrel is done by simple majority)
            let halfOfUsers = (numOfUsers/2)
            //The user can delete the squirrel if no one has rated it yet, or if a majority of users vote to delete it
            if squirrel["avg_rating"] as! Int == 0 || squirrel["dropVotes"] as! Int == halfOfUsers {
                //Find the appropriate message to display, since both of these alerts give the user the option to immediately delete the squirrel
                if squirrel["avg_rating"] as! Int == 0 {
                    message = "Are you sure you want to do this? Since no one has rated this squirrel, your vote will delete it from the group."
                } else {
                    message = "Are you sure you want to do this? With your vote, enough users will have voted to drop this squirrel. Your vote will delete it from the group."
                }
                var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler:  { (action: UIAlertAction!) in
                     //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
                    let viewsArray = displayLoadingAnimator(self.view)
                    let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
                    let container = viewsArray[1] as! UIView
                    let loadingView = viewsArray[2] as! UIView
            
                    dispatch_async(dispatch_get_main_queue()) {
                        group.removeObject(squirrel.objectId!, forKey: "squirrels")
                        group.removeObject(fullName, forKey: "squirrelFullNames")
                        squirrel.deleteInBackgroundWithBlock({ (didWork: Bool, error: NSError?) -> Void in
                            if error == nil {
                                group.save()
                                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                                self.loadObjects()
                            } else {
                                println(error)
                            }
                            //Global function that stops the loading animation and dismisses the views it is attached to
                            resumeInteractionEvents(activityIndicatorView, container, loadingView)
                        })
                    }
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            //Else user is casting their vote to delete the squirrel, but a majority of the users haven't voted for this option yet
            message = "Are you sure you want to vote to delete this squirrel?"
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Vote to Delete", style: .Default, handler:  { (action: UIAlertAction!) in
                    let oldVotes = squirrel["dropVotes"] as! Int
                    let newVotes = oldVotes + 1
                    squirrel["dropVotes"] = newVotes
                    squirrel.addObject(PFUser.currentUser()!.username!, forKey: "droppers")
                    squirrel.save()
                    self.loadObjects()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("SquirrelDetails", sender: objects![indexPath.row])
    }
    
    
    //Customize the delete button on swipe left
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var title = "Delete"
        var deleteButton = UITableViewRowAction(style: .Default, title: title, handler: { (action, indexPath) in
            self.tableView.dataSource?.tableView?(
                self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath
            )
        })
        return [deleteButton]
    }
    
    //Updates all of the Squirrel Tab's label
    func updateLables() {
        let groupName = PFUser.currentUser()!["currentGroup"]!["name"] as! String
        //Setting self.title here for some reason change's the squirrel tab's title as well
        self.navigationItem.title = "\(groupName) Squirrels"
        //Set the number of rerates
        LOGGED_IN_USER_ACORNS = getUserInfo(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!).toInt()!
        LOGGED_IN_USER_SQUIRREL_SLOTS = getUserInfo(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()!
        LOGGED_IN_USER_RERATES = getUserInfo(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!).toInt()!
        var groupUsers = currentGroup!["users"] as! [String]
        var numOfUsers = groupUsers.count

        acornsLabel!.text = "\(LOGGED_IN_USER_ACORNS)"
        squirrelSlotsLabel!.text = "Squirrel Slots: \(LOGGED_IN_USER_SQUIRREL_SLOTS)"
        if numOfUsers == 1 {
            squirrelSlotsLabel!.text = "You need another member!"
            addSquirrelButton!.enabled = false
        } else if LOGGED_IN_USER_SQUIRREL_SLOTS > 0 {
            //We enable the add squirrel button, since we disable it after pressing it. This way it is re-enabled when users press the back button from addSquirrelViewController
            addSquirrelButton!.enabled = true
        } else {
            addSquirrelButton!.enabled = false
        }
        //We re-enable the trade button for the same reason
        tradeOfferButton.enabled = true
    
    }
    
    
    //Checks if new users have joined the currentGroup and pdates the user's squirrel slots if there are new users
    func updateSquirrelSlots() {
        println("UPDATING SQUIRREL SLOTS")
        let numOfUsers = (currentGroup!["users"] as! [String]).count
        println("\(numOfUsers)")
        let oldNumOfUsers = getUserInfo(currentGroup!["usersOnLastVisit"] as! [String], PFUser.currentUser()!.username!).toInt()
        println("\(oldNumOfUsers)")
        if numOfUsers == oldNumOfUsers {
            //No new users have joined the group, so we return
            return
        }
        //Then new users have joined the group
        let numOFNewUsers = numOfUsers - oldNumOfUsers!
        //Show popup
        var message = ""
        if numOFNewUsers == 1 {
            message = "One new user has joined, so enjoy one more Squirrel Slot!"
        } else {
            message = "\(numOFNewUsers) users have joined, so enjoy \(numOFNewUsers) squirrel slots!"
        }
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
            LOGGED_IN_USER_SQUIRREL_SLOTS += numOFNewUsers
            self.squirrelSlotsLabel!.text = "Squirrel Slots: \(LOGGED_IN_USER_SQUIRREL_SLOTS)"
            let newSquirrelSlots = getNewArrayToSave(self.currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_SQUIRREL_SLOTS))
            let newUsersOnLastVisit = getNewArrayToSave(self.currentGroup!["usersOnLastVisit"] as! [String], PFUser.currentUser()!.username!, String(numOfUsers))
            self.currentGroup!["squirrelSlots"] = newSquirrelSlots
            self.currentGroup!["usersOnLastVisit"] = newUsersOnLastVisit
            self.currentGroup!.save()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //Since there appears to be the possibility that somehow a user can be added to a group with a missing field (rarely), this function goes through all of the group's user fields, and if the user's data is missing from it, it updates the group's field to include it. If the user's data was missing on any of the fields, it saves the new information afterwords
    func verifyNoNullFields() {
        var needToChangeData = false
        if userDataExists(currentGroup!["acorns"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):750", forKey: "acorns")
        } else if userDataExists(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            var numOfUsers = (currentGroup!["users"] as! [String]).count
            let squirrelSlots = (numOfUsers - 1) + 3
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):\(squirrelSlots)", forKey: "squirrelSlots")
        } else if userDataExists(currentGroup!["cumulativeDays"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):\(1)", forKey: "lastVisits")
        } else if userDataExists(currentGroup!["usersOnLastVisit"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            var numOfUsers = (currentGroup!["users"] as! [String]).count
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):\(numOfUsers)", forKey: "usersOnLastVisit")
        } else if userDataExists(currentGroup!["lastVisits"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            let today = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.stringFromDate(today)
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):\(todayString)", forKey: "lastVisits")
        } else if userDataExists(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!) == false {
            needToChangeData = true
            currentGroup!.addObject("\(PFUser.currentUser()!.username!):0", forKey: "rerates")
        }
        if needToChangeData == true {
            currentGroup!.save()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if shouldReload == true {
            shouldReload = false
            reload()
        } else {
            updateLables()
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Since it appears there is a chance that a user can not have a data field, for now we do a double check and create any relevant fields for them in the group instance if they don't have them
        verifyNoNullFields()
        //Check to see if there are new users
        updateSquirrelSlots()
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prepareForReload", name: reloadNotificationKey, object: nil)
        //Listen for when silent push notification alerts user that data has changed
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prepareForReload", name: reloadSquirrels, object: nil)
        //Set the addSquirrelButton to 'fa-plus-circle'
        addSquirrelButton!.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        addSquirrelButton!.title = "\u{f055}"
        addSquirrelButton!.tintColor = UIColor.orangeColor()
        //Set the tradeOfferButton to 'fa-user-secret'
        tradeOfferButton!.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        tradeOfferButton!.title = "\u{f21b}"
        tradeOfferButton!.tintColor = UIColor.orangeColor()
        tradeOfferButton!.enabled = true
        
        self.navigationController!.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        //Check to see if we need to show a new user tutorial screens
        if PFUser.currentUser()!["newSquirrelTab"] as! Bool == true {
            //If new user, show them the tutorial screens, but we only want to present these screens from the main squirrel tab
            performSegueWithIdentifier("NewUserScreens", sender: self)
        }
    }
    
    //Delegate function is called for squirrelDetailViewController so that we can reload after a user has rated a squirrel
    func reloadParent(controller: NewSquirrelDetailsViewController, usedRerate: Bool) {
        if usedRerate == true {
            //Then the user used their rerate and it needs to be set back to false
            var newRerates = getNewArrayToSave(currentGroup!["rerates"] as! [String], PFUser.currentUser()!.username!, "0")
            currentGroup!["rerates"] = newRerates
            currentGroup!.save()
        }
        reload()
    }
    
    //Should also be made into its own extension
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString) {
        
        var newSquirrel = PFObject(className:"Squirrel")
        newSquirrel["first_name"] = firstName
        newSquirrel["last_name"] = lastName
        newSquirrel["owner"] = PFUser.currentUser()!
        newSquirrel["raters"] = []
        newSquirrel["ratings"] = []
        newSquirrel["avg_rating"] = 0
        newSquirrel["group"] = PFUser.currentUser()!["currentGroup"]
        newSquirrel["ownerUsername"] = PFUser.currentUser()!.username
        newSquirrel["dropVotes"] = 0
        newSquirrel["droppers"] = []
        let picture = UIImage(named: "Squirrel_Profile_Pic")
        let imageData = UIImagePNGRepresentation(picture)
        let imageFile = PFFile(name: "Squirrel_Profile_Pic", data: imageData)
        newSquirrel["picture"] = imageFile
        
        newSquirrel.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                var group = PFUser.currentUser()!["currentGroup"] as! PFObject
                group.addObject(newSquirrel.objectId!, forKey: "squirrels")
                
                
                //LOGGED_IN_USER_SQUIRREL_SLOTS already has one squirrel slot subtracted from in AddSquirrelViewController
                LOGGED_IN_USER_SQUIRREL_SLOTS -= 1
                let newSquirrelSlots = getNewArrayToSave(group["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_SQUIRREL_SLOTS))
                group["squirrelSlots"] = newSquirrelSlots
                group.save()
                self.reload()
                self.dismissViewControllerAnimated(true, completion: nil)
            }
    
        }
    }
    
    //should be made into its own extension
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}

