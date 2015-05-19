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

@objc protocol SquirrelViewControllerDelegate: class {

    optional func SquirrelTradeDelegate(controller: SquirrelViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject)
}

class SquirrelViewController: PFQueryTableViewController, AddSquirrelViewControllerDelegate, SquirrelDetailViewControllerDelegate {



    //Optional value for determing if we're viewing someone else's squirrels, who's squirrels they are
    var selectedUser: PFUser?
    //Optional for determing if the user has room to add a Squirrel. Also passed along to SquirrelDetailViewController to allow them to pick up a Squirrel
    var canPickUpSquirrel: Bool?
    //Optional for storing whether the viewcontroller should reload (if the user changed their currentGroup)
    var shouldReLoad: Bool?
    //Optional for keeping track of how many squirrel slots the user has available
    var squirrelSlots: Int?
    
    weak var delegate: SquirrelViewControllerDelegate?
    
    //Optional values for if the user is currently trying to trade
    
    //Optional value for determining if user is going through their Squirrels to select a trade
    var currentlyTrading: Bool?
    //Squirrel that the logged in user wants in return for one of their squirrels
    var desiredSquirrel: PFObject?
    //The owner of the squirrel that the logged in user wants
    var desiredSquirrelOwner: PFUser?
    
    //Optionals for keeping track of squirrel names to transfer to AddSquirrelViewController to make sure a Squirrel can't be duplicated
    var firstNames: [String]?
    var lastNames: [String]?
    
    
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
    func calculateAverageRating(ratings:[Int]) -> Int {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 999
        }
        numOfRatings = 0
        var sum = 0
        for rating in ratings {
            sum += rating
            numOfRatings += 1
        }
        return Int(sum/numOfRatings)
    }
    
    
    //Calculates the color that the Squirrel name should be shown in, given the Squirrel's average rating
    func calculateColor(avg_rating: Double) -> UIColor {
        if avg_rating >= 9 {
            return UIColor.redColor()
        } else if avg_rating >= 8 {
            //Return fuschia
            return UIColor(red: 255, green: 0, blue: 255, alpha: 1)
        } else if avg_rating >= 7 {
            return UIColor.orangeColor()
        } else if avg_rating >= 5 {
            return UIColor.yellowColor()
        }
        //Else we return white
        return UIColor.whiteColor()
    }
    
    
    //Calculates the average rating of Squirrells owned by a user
    func calculateTeamRating(username:String) -> Int {
        var teamRatings: [Int] = []
        for squirrel in self.objects! {
            var owner = squirrel["owner"] as? PFUser
            //Not sure how efficient fetching is all the time, probably should change this to just checking a string or something
            owner?.fetch()
            println(owner)
            //For some reason a nil check always passes, but converting "avg_rating" to a string and then checking works
            if squirrel["avg_rating"] === 0 {
                //Weird parse bug, can only check if nil by using ===
            } else if (owner?.username == username){
                teamRatings.append(squirrel["avg_rating"] as! Int)
            }
        }
        var teamRating = calculateAverageRating(teamRatings as [Int])
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
            controller.firstNames = firstNames!
            controller.lastNames = lastNames!
            controller.delegate = self
            
        }
        if segue.identifier == "SquirrelDetails" {
            let controller = segue.destinationViewController as! SquirrelDetailViewController
            //controller.delegate = self
            controller.ratedSquirrel = sender as? PFObject
            controller.squirrelSlots = squirrelSlots!
            if squirrelSlots > 0 {
                controller.canClaimSquirrel = true
            } else {
                controller.canClaimSquirrel = false
            }

            if sender!["owner"] != nil {
                var user = sender!["owner"] as? PFUser
                controller.squirrelOwner = user 
            } else {
                //The Squirrel doesn't have an owner
                println(canPickUpSquirrel)
                controller.canClaimSquirrel = canPickUpSquirrel!
            }
        }
        if segue.identifier == "TradeOffers" {
            let controller = segue.destinationViewController as! NotificationsViewController
        }
    }
    
    override func objectsDidLoad(error: NSError!) {
        super.objectsDidLoad(error)
        //Team ratings need to be calculated here because the query hasn't been calculated yet in viewDidLoad
        if (self.selectedUser != nil) {
            //We need to calculate the team rating
            var teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            if teamRating == 999 {
                teamRatingLabel.text = "Their Squirrels haven't been rated :("
            } else {
                teamRatingLabel.text = "Team Rating: \(String(teamRating))"
            }
        }
        //Also need to calculate if the user can add a squirrel, because the query hasn't been calculated yet in viewDidLoad
        var groupUserIds = PFUser.currentUser()!["currentGroup"]!["userIDs"] as? [String]
        var numOfUsers = groupUserIds!.count
        var yourNumSquirrels = 0
        firstNames = []
        lastNames = []
        for squirrel in self.objects! {
            //We save the names as lowercase, so that when a squirrel name is being created, users can't duplicate a squirrel by using a different casing
            let firstName = squirrel["first_name"] as! String
            let lastName = squirrel["last_name"] as! String

            firstNames!.append(firstName.lowercaseString)
            lastNames!.append(lastName.lowercaseString)
            
            var owner = squirrel["owner"] as? PFUser
            if owner?.objectId == PFUser.currentUser()!.objectId {
                yourNumSquirrels += 1
            }
        }
        
        if yourNumSquirrels > numOfUsers + 4 || yourNumSquirrels == 15 {
            squirrelSlotsLabel?.text = "You're Squirrel Team is full!"
            addSquirrelButton?.enabled = false
            squirrelSlots = 0
        } else if numOfUsers == 1 {
            squirrelSlotsLabel?.text = "You need at least two users to start squirreling!"
            addSquirrelButton?.enabled = false
            squirrelSlots = 0
        }
        else {
            squirrelSlots = (numOfUsers + 4) - yourNumSquirrels
            squirrelSlotsLabel?.text = "\(squirrelSlots!) squirrel slots remaining"
            addSquirrelButton?.enabled = true
        }

    }
    
    // Define the query that will provide the data for the table view
    override func queryForTable() -> PFQuery {
        
        var query = PFQuery(className: "Squirrel")
        query.whereKey("group", equalTo: PFUser.currentUser()!["currentGroup"]!)
        if currentlyTrading == true {
            query.whereKey("owner", equalTo: PFUser.currentUser()!)
        } else if selectedUser != nil {
            query.whereKey("owner", equalTo: selectedUser!)
        }
        query.orderByDescending("avg_rating")
        return query
    }
    
    
    //Responds to NSNotication when user has changed their current group
    func reloadWithNewGroup() {
        shouldReLoad = true
    }
    
    func reloadWithNewGroupTest() {
        self.viewDidLoad()
    }
    
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Squirrels can only be deleted if the user is going through their own squirrels
        if selectedUser?.objectId == PFUser.currentUser()!.objectId {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath, object: PFObject?) -> PFTableViewCell? {
            var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! PFTableViewCell
            var first = cell.viewWithTag(1) as! UILabel
            first.text = object!["first_name"]!.capitalizedString
            //For some reason 2 is already being used as another tag
            var last = cell.viewWithTag(5) as! UILabel
            last.text = object!["last_name"]!.capitalizedString
            var ratingLabel = cell.viewWithTag(3) as! UILabel
            var avgRating = object!["avg_rating"] as! Double
            if avgRating != 0 {
                ratingLabel.text = "\(avgRating)"
                var color = calculateColor(avgRating)
                cell.backgroundColor = color
            } else {
                //For some reason not setting unrated squirrels color to black, leads to them sometimes being other colors, despite 
                // the squirrel's avgRating not passing the if statemtnt
                ratingLabel.text = ""
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let squirrel = objects![indexPath.row] as! PFObject
            squirrel.removeObjectForKey("owner")
            squirrel.save()
            var teamRating = calculateTeamRating(selectedUser!["username"] as! String)
            teamRatingLabel.text = "Team Rating: \(String(teamRating))"
            ///Alert SquirrelViewController to reload data
            NSNotificationCenter.defaultCenter().postNotificationName(droppedSquirrel, object: self)
            self.loadObjects()
        }
    }

    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if currentlyTrading == true {
            //dismissViewControllerAnimated(true, completion: nil)
            //Then the delegate will store the selected Squirrel and other trade information 
            delegate?.SquirrelTradeDelegate!(self, selectedSquirrel: objects![indexPath.row] as! PFObject, wantedSquirrelOwner:desiredSquirrelOwner!, wantedSquirrel: desiredSquirrel!)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.performSegueWithIdentifier("SquirrelDetails", sender: objects![indexPath.row])
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedUser == nil {
            //Set the addSquirrelButton to 'fa-plus-circle'
            addSquirrelButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            addSquirrelButton?.title = "\u{f055}"
            addSquirrelButton?.tintColor = UIColor.whiteColor()
            //Set the tradeOfferButton to 'fa-user-secret'
            tradeOfferButton?.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
            tradeOfferButton?.title = "\u{f21b}"
            tradeOfferButton?.tintColor = UIColor.whiteColor()
        }
        //Set notification to "listen" for when the the user has changed their currentGroup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: reloadNotificationKey, object: nil)
        //Set notification to "listen" for when the the user has picked up a squirrel or dropped one of theirs
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroupTest", name: reloadSquirrels, object: nil)
        //Set notification to "listen" for when the the user has dropped a squirrel
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadWithNewGroup", name: droppedSquirrel, object: nil)
        //Customize navigation controller back button to my only the back symbol
        let backItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        if shouldReLoad == true {
            shouldReLoad = false
            self.viewDidLoad()
        }
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
        newSquirrel["dtd"] = false
        newSquirrel["out"] = false
        newSquirrel["avg_rating"] = 0
        newSquirrel["group"] = PFUser.currentUser()!["currentGroup"]
        newSquirrel.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                
                self.dismissViewControllerAnimated(true, completion: nil)
                self.viewDidLoad()
                
            } else {
                println(error)
            }
        }

        
    }
    
    //Should be its own extension 
    func squirrelDetailViewController(controller: SquirrelDetailViewController) {
            self.tableView.reloadData()
    }

}

