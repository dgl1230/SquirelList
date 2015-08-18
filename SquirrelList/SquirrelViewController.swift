//
//  SquirrelNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//Unique string for reloading when user has dropped a squirrel or picked up one
let reloadSquirrels = "com.denis.reloadSquirrelViewController"
let droppedSquirrel = "com.denis.droppedSquirrel"

import UIKit

//For passing back squirrel information when a user is selecting a squirrel to propose a trade to 
@objc protocol SquirrelViewControllerDelegate: class {

    optional func SquirrelTradeDelegate(controller: SquirrelViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject)
}

class SquirrelViewController: PFQueryTableViewController, AddSquirrelViewControllerDelegate, SquirrelDetailViewControllerDelegate {

    deinit {
        //We remove the observer for reloading the controller
        NSNotificationCenter.defaultCenter().removeObserver(self, name: reloadSquirrels, object: nil)

    }
    
    //Optional value for determing if we're viewing someone else's squirrels, who's squirrels they are
    var selectedUser: PFUser?
    //Optional for determing if the user has room to add a Squirrel. Also passed along to SquirrelDetailViewController to allow them to pick up a Squirrel
    var canPickUpSquirrel: Bool?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    //Optional for keeping track of how many squirrel slots the user has available
    var squirrelSlots: Int?
    //Variable for storing an individualGroupData instance - holds acorn info, last group visit, and other gamification factors
    var individualGroupData: PFObject?
    //Variable for storing the logged in user's current group
    var currentGroup: PFObject?
    
    weak var delegate: SquirrelViewControllerDelegate?
    
    //Optional values for if the user is currently trying to trade - this to to pass back the relevant data to TradeOfferViewController after the user has selected a squirrel of theirs to offer in the trade 
    
        //Optional value for determining if user is going through their Squirrels to select a trade
        var currentlyTrading: Bool?
        //Squirrel that the logged in user wants in return for one of their squirrels
        var desiredSquirrel: PFObject?
        //The owner of the squirrel that the logged in user wants
        var desiredSquirrelOwner: PFUser?
    
    //Optional for keeping track of squirrel names to transfer to AddSquirrelViewController to make sure a Squirrel can't be duplicated. Each object in the array is "firstName LastName"
    var squirrelNames: [String]?
    
    @IBOutlet weak var acornsLabel: UILabel?
    @IBOutlet weak var squirrelSlotsLabel: UILabel?
    @IBOutlet weak var teamRatingLabel: UILabel!
    @IBOutlet weak var addSquirrelButton: UIBarButtonItem?
    @IBOutlet weak var tradeOfferButton: UIBarButtonItem!
    
    
    @IBAction func addSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("AddSquirrel", sender: self)
    }
    
    
    @IBAction func viewTradeOffers(sender: AnyObject) {
        self.performSegueWithIdentifier("TradeOffers", sender: self)
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
        if currentlyTrading == true {
            self.pullToRefreshEnabled = false
        } else {
            self.pullToRefreshEnabled = true
        }
        self.paginationEnabled = false
    }
    
    
    //Calculates the average, given an array of numbers
    func calculateAverageRating(ratings:[Double]) -> Double {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 999
        }
        numOfRatings = 0
        var sum = 0.0
        for rating in ratings {
            sum += rating
            numOfRatings += 1
        }
        var unroundedRating = Double(sum)/Double(numOfRatings)
        return round((10 * unroundedRating)) / 10
    }
    
    
    //Calculates the color that the Squirrel name should be shown in, given the Squirrel's average rating
    func calculateColor(avg_rating: Double) -> UIColor {
        if avg_rating >= 8.5 {
            return UIColor.redColor()
        } else if avg_rating >= 7 {
            return UIColor.orangeColor()
        } else if avg_rating >= 5 {
            return UIColor.yellowColor()
        }
        //Else we return white
        return UIColor.whiteColor()
    }
    
    
    //Calculates the average rating of Squirrells owned by a user
    func calculateTeamRating(username:String) -> Double {
        var teamRatings: [Double] = []
        for squirrel in self.objects! {
            var owner = squirrel["ownerUsername"] as? String
            if squirrel["avg_rating"] === 0 {
                //Weird parse bug, can only check if nil by using ===
            } else if (owner == username){
                teamRatings.append(squirrel["avg_rating"] as! Double)
            }
        }
        var teamRating = calculateAverageRating(teamRatings as [Double])
        return teamRating
    }
    
    
    //Goes through the list of raters a Squirrel has and if the username of said user is found, returns false. Else it returns true
    func didUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (find(raters, username) == nil) {
            return false
        }
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddSquirrel" {
            let controller = segue.destinationViewController as! AddSquirrelViewController
            //we need to transer the array of names so that we can make sure the user isn't creating a duplicate squirrel
            controller.squirrelNames = squirrelNames!
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as! SquirrelDetailViewController
            controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            //controller.squirrelSlots = individualGroupData!["squirrelSlots"] as? Int
            if squirrelSlots > 0 {
                controller.canClaimSquirrel = true
            } else {
                controller.canClaimSquirrel = false
            }
            let canRerate = individualGroupData!["canRerate"] as! Bool
            controller.canRerate = canRerate
            if sender!["owner"] != nil {
                var user = sender!["owner"] as? PFUser
                controller.squirrelOwner = user 
            } else {
                //The Squirrel doesn't have an owner
                controller.canClaimSquirrel = canPickUpSquirrel!
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
    
    
    override func objectsDidLoad(error: NSError!) {
        super.objectsDidLoad(error)
        //Team ratings and squirrel slots are calculated here
        //Team ratings need to be calculated here because the query hasn't been calculated yet in viewDidLoad
        if (self.selectedUser != nil) {
            //We need to calculate the team rating
            var teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            //If rating is 999.0, then no one has rated their team
            if teamRating == 999.0 && selectedUser!.objectId == PFUser.currentUser()!.objectId {
                teamRatingLabel.text = "No one has rated your team"
            } else if teamRating == 999.0 {
                teamRatingLabel.text = "No one has rated their team"
            }else {
                teamRatingLabel.text = "Team Rating: \(teamRating)"
            }
        }
        //Need to get an array of all the Squirrel names to send to AddSquirrelViewController so that dulicate squirrels can't be created
        squirrelNames = []
        for squirrel in self.objects! {
            //We save the names as lowercase, so that when a squirrel name is being created, users can't duplicate a squirrel by using a different casing
            let firstName = squirrel["first_name"] as! String
            let lastName = squirrel["last_name"] as! String
            let name = "\(firstName.lowercaseString) \(lastName.lowercaseString)"
            squirrelNames!.append(name)
        }
        

    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        var query = PFQuery(className: "Squirrel")
        query.whereKey("objectId", containedIn: currentGroup!["squirrels"] as! [String])
        if currentlyTrading == true {
            query.whereKey("owner", equalTo: PFUser.currentUser()!)
        } else if selectedUser != nil {
            query.whereKey("owner", equalTo: selectedUser!)
        }
        query.orderByDescending("avg_rating")
        return query
    }
    
    
    //Responds to NSNotication when user has changed their current group
    /*
    func reloadWithNewGroup() {
        self.viewDidLoad()
    }
    */
    
    func reloadWithNewGroupTest() {
        println("RELOADING WITH NEW GROUP TEST")
        shouldReLoad == true
    }
    
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Squirrels can only be deleted if the user is going through their own squirrels
        if selectedUser?.objectId == PFUser.currentUser()!.objectId {
            return true
        } else if selectedUser == nil {
            return true
        }
        return false
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
        
            if avgRating != 0 && avgRating >= 8 {
                ratingLabel.text = "\(avgRating)"
                var color = calculateColor(avgRating)
                cell.backgroundColor = color
            } else {
                //For some reason not setting unrated squirrels color to black, leads to them sometimes being other colors, despite 
                ratingLabel.text = ""
                cell.backgroundColor = UIColor.yellowColor()
            }
            return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if selectedUser != nil {
                //The logged in user is trying to drop a squirrel
                var message = "Are you sure you want to drop your squirrel? Your friends may claim it!"
                var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                    alert.dismissViewControllerAnimated(true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Drop Squirrel", style: .Default, handler:  { (action: UIAlertAction!) in
            
                    let squirrel = self.objects![indexPath.row] as! PFObject
                    squirrel.removeObjectForKey("owner")
                    squirrel.removeObjectForKey("ownerUsername")
                    squirrel.save()
                    var teamRating = self.calculateTeamRating(self.selectedUser!["username"] as! String)
                    self.teamRatingLabel.text = "Team Rating: \(teamRating)"
                    //Give the user a squirrel slot
                    self.individualGroupData = PFUser.currentUser()!["currentGroupData"] as? PFObject
                    //self.individualGroupData?.fetch()
                    var squirrelSlots = self.individualGroupData!["squirrelSlots"] as! Int
                    squirrelSlots += 1
                    self.individualGroupData!["squirrelSlots"] = squirrelSlots
                    self.individualGroupData!.save()
                    ///Alert SquirrelViewController to reload data
                    NSNotificationCenter.defaultCenter().postNotificationName(droppedSquirrel, object: self)
                    self.loadObjects()
                    //Need to delete all TradeProposals where the dropped squirrel is offered or desired
                    let query1 = PFQuery(className: "TradeProposal")
                    query1.whereKey("proposedSquirrelID", equalTo: squirrel.objectId!)
                    let query2 = PFQuery(className: "TradeProposal")
                    query2.whereKey("offeredSquirrelID", equalTo: squirrel.objectId!)
                    let query = PFQuery.orQueryWithSubqueries([query1, query2])
                    query.findObjectsInBackgroundWithBlock { (trades: [AnyObject]?, error: NSError?) -> Void in
                        if error == nil {
                            var tradeOffers = trades as? [PFObject]
                            if tradeOffers?.count >= 1 {
                                for trade in tradeOffers! {
                                    trade.delete()
                                }
                            }
                            
                        }
                    }
                    
                    
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            // Else the user is trying to delete a squirrel from the group
            let squirrel = objects![indexPath.row] as! PFObject
            var message = ""
            var owner = squirrel["ownerUsername"] as? String
            //Users need to drop their own squirrels before they delete them
            if owner == PFUser.currentUser()!.username! {
                message = "Whoa there! If you want to delete your squirrel, drop them from your team first"
                var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler:  { (action: UIAlertAction!) in
                    return
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            //Users can't delete squirrels with an owner
            if squirrel["ownerUsername"] != nil  {
                message = "Only squirrels that are ownerless can be deleted! This is someone's beloved squirrel. What's wrong with you?"
                var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "My bad", style: .Cancel, handler:  { (action: UIAlertAction!) in
                    return
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            //Check to see if the user already voted to drop the Squirrel
            let droppers = squirrel["droppers"] as! [String]
            if find(droppers, PFUser.currentUser()!.username!) != nil {
                message = "You already voted to delete this squirrel! Just leave it alone."
                var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "My bad", style: .Cancel, handler:  { (action: UIAlertAction!) in
                    return
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
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
                alert.addAction(UIAlertAction(title: "Delete Squirrel", style: .Default, handler:  { (action: UIAlertAction!) in
                        squirrel.delete()
                        self.loadObjects()
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            //Else user is casting their vote to delete the squirrel, but a majority of the users haven't voted for this option yet
            message = "Are you sure you want to vote to delete this squirrel? If the majority of users in this group vote to delete it, then it will be removed from the group."
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
        let squirrel = objects![indexPath.row] as! PFObject
        if currentlyTrading == true {
            //Then the delegate will store the selected Squirrel and other trade information and pass it back to the UsersSquirrelsViewController
            delegate?.SquirrelTradeDelegate!(self, selectedSquirrel: objects![indexPath.row] as! PFObject, wantedSquirrelOwner:desiredSquirrelOwner!, wantedSquirrel: desiredSquirrel!)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.performSegueWithIdentifier("SquirrelDetails", sender: objects![indexPath.row])
        }
    }
    
    //Customize the delete button on swipe left
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var title = ""
        if selectedUser != nil {
            //The user is going through their squirrels and can potentially drop them
            title = "Drop"
        } else {
            //Else the user is going through all squirrels and can potentially delete them
            title = "Delete"
        }
        var deleteButton = UITableViewRowAction(style: .Default, title: title, handler: { (action, indexPath) in
            self.tableView.dataSource?.tableView?(
                self.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: indexPath
            )
        })
        return [deleteButton]
    }
    
    //Updates the user's squirrel slots for when a new user (or users) have joined the group
    func updateSquirrelSlots() {
        let currentGroup = PFUser.currentUser()!["currentGroup"] as! PFObject
        let numOfUsers = (currentGroup["users"] as! [String]).count
        let oldNumOfUsers = individualGroupData!["numOfGroupUsers"] as! Int
        //Then new users have joined the group
        let numOFNewUsers = numOfUsers - oldNumOfUsers
        squirrelSlots = individualGroupData!["squirrelSlots"] as? Int
        squirrelSlots! += numOFNewUsers
        //Show popup
        var message = ""
        if numOFNewUsers == 1 {
            message = "One new user has joined, so enjoy one more Squirrel Slot!"
        } else {
            message = "\(numOFNewUsers) have joined, so enjoy \(numOFNewUsers) squirrel slots!"
        }
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
            self.individualGroupData!["numOfGroupUsers"] = numOfUsers
            self.individualGroupData!["squirrelSlots"] = self.squirrelSlots!
            self.squirrelSlotsLabel!.text = "Squirrel Slots: \(self.squirrelSlots!)"
            self.individualGroupData!.save()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.viewDidLoad()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check to see if we need to show a new user tutorial screens first
        if currentlyTrading == true {
            //We don't need to load or calculate anything else if we're just displaying the user's squirrels to offer for a trade
            return
        }
        //Get the UserGroupData instance
        individualGroupData = PFUser.currentUser()!["currentGroupData"] as? PFObject
        individualGroupData?.fetch()

        if PFUser.currentUser()!["newSquirrelTab"] as! Bool == true && selectedUser == nil {
            //If new user, show them the tutorial screens, but we only want to present these screens from the main squirrel tab
            performSegueWithIdentifier("NewUserScreens", sender: self)
        }
        
        let name = selectedUser?["name"] as? String
        if selectedUser == nil && currentlyTrading == nil {
            //We are in the main Squirrels tab
            //Set the addSquirrelButton to 'fa-plus-circle'
            addSquirrelButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            addSquirrelButton?.title = "\u{f055}"
            addSquirrelButton?.tintColor = UIColor.orangeColor()
            //Set the tradeOfferButton to 'fa-user-secret'
            tradeOfferButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            tradeOfferButton?.title = "\u{f21b}"
            tradeOfferButton?.tintColor = UIColor.orangeColor()
            let groupName = PFUser.currentUser()!["currentGroup"]!["name"] as! String
            //Setting self.title here for some reason change's the squirrel tab's title as well
            self.navigationItem.title = "\(groupName) Squirrels"
            //Set the number of rerates 
            let userAcorns = individualGroupData!["acorns"] as! Int
            acornsLabel?.text = "\(userAcorns)"
            
            var groupUsers = currentGroup!["users"] as? [String]
            var numOfUsers = groupUsers!.count
            
            
            let oldNumOfUsers = individualGroupData!["numOfGroupUsers"] as! Int

            //Set the number of squirrel slots to display
            squirrelSlots = individualGroupData!["squirrelSlots"] as? Int
            
            if squirrelSlots == 0 {
                squirrelSlotsLabel!.text = "Squirrel Slots: 0"
                addSquirrelButton!.enabled = false
            } else if numOfUsers == 1 {
                squirrelSlotsLabel!.text = "You need at least two users!"
                addSquirrelButton!.enabled = false
            }
            else {
                squirrelSlotsLabel!.text = "Squirrel Slots: \(squirrelSlots!)"
                addSquirrelButton!.enabled = true
            }
            
            //See if new users have been added to the group, and if they have been, update their squirrel slots and alert them
            if numOfUsers > oldNumOfUsers {
                updateSquirrelSlots()
            }
            
        }
        else if selectedUser!.username == PFUser.currentUser()!.username {
            self.title = "My Squirrels"
        } else if name != nil {
            self.title = "\(name!)'s Squirrels"
        } else {
            self.teamRatingLabel.text = "\(selectedUser!.username!)'s Squirrels"
        }
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "BebasNeueBold", size: 26)!,  NSForegroundColorAttributeName: UIColor.whiteColor()]

        //Set notification to "listen" for when the the user has picked up a squirrel or dropped one of theirs
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroupTest", name: reloadSquirrels, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }
   
   
    //should be made into its own extension
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController) {
        dismissViewControllerAnimated(true, completion: nil)
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
                group.save()
                
                //Need to subtract one Squirrel Slot from their group data
                var squirrelSlots = self.individualGroupData!["squirrelSlots"] as! Int
                squirrelSlots -= 1
                self.individualGroupData!["squirrelSlots"] = squirrelSlots
                self.individualGroupData!.save()
                
                
                
                self.dismissViewControllerAnimated(true, completion: nil)
                self.viewDidLoad()
                
            }
        }
    }
    
    //Delegate function is called for squirrelDetailViewController so that we can reload after a user has rated a squirrel
    func squirrelDetailViewController(controller: SquirrelDetailViewController, usedRerate: Bool) {
        if usedRerate == true {
            //Then the user used their rerate and it needs to be set back to false
            let userGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
            userGroupData["canRerate"] = false
            userGroupData.save()
        }
        self.viewDidLoad()
    }

}

