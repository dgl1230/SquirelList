//
//  SquirrelDetailNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

protocol SquirrelDetailViewControllerDelegate: class {
    func squirrelDetailViewController(controller: SquirrelDetailViewController)
}

class SquirrelDetailViewController: PopUpViewController, UITextFieldDelegate {

    //Bool that determines if the logged in user has room to pick up another squirrel
    var canClaimSquirrel: Bool?
    weak var delegate: SquirrelViewController?
    var ratedSquirrel: PFObject?
    var squirrelOwner: PFUser?
    var didRateSquirrel: Bool?
    //Optional for keeping track up how many squirrel slots the user has
    var squirrelSlots: Int?
    //Optional for keeping track of first names of squirrels

    
    
    
    @IBOutlet weak var claimSquirrelButton: UIButton!
    @IBOutlet weak var squirrelNameLabel: UILabel!
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    //Label that says "owner:" doesn't actually say the owner's name
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var rateNumberTextField: UITextField!
    //Label that displays the owners name
    @IBOutlet weak var squirrelOwnerLabel: UILabel!
    @IBOutlet weak var tradeButton: UIButton!
    //This label displays the user's actual rating
    @IBOutlet weak var userRatingLabel: UILabel!
    //The label that says "Your Rating" - it does not actually display the rating
    @IBOutlet weak var yourRatingLabel: UILabel!
    
    
    
    @IBAction func claimSquirrel(sender: AnyObject) {
        ratedSquirrel!["owner"] = PFUser.currentUser()!
        if didRateSquirrel == true {
            removeOwnerRating(ratedSquirrel!)
            ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as! [String])
        }
        ratedSquirrel!.save()
        //Alert SquirrelViewController to reload data
        NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        //check if ["raters"] is nil. If it is, we create it
        var rater = PFUser.currentUser()!["username"] as! String
        if let check: AnyObject = ratedSquirrel!["raters"] {
           ratedSquirrel!["raters"]!.addObject(rater)
        } else {
            ratedSquirrel!["raters"] = [rater]
        }
        //check if ["ratings"] is nil. If it is, we create it
        if let check: AnyObject = ratedSquirrel!["ratings"] {
            ratedSquirrel!["ratings"]!.addObject(rateNumberTextField.text)
        } else {
            ratedSquirrel!["ratings"] = [rateNumberTextField.text]
        }
        ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as! [String])
        ratedSquirrel!.save()
        //Alert SquirrelViewController to reload data
        NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    @IBAction func tradeSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("tradeSquirrel", sender: self)
    }
    
    

    func calculateAverageRating(ratings:[String]) -> Double {
        var numOfRatings = ratings.count
        if numOfRatings == 0 {
            return 0
        }
        var sum = 0.0

        for rating in ratings {
            var rating1 = rating as NSString
            sum += rating1.doubleValue
        }
        var unroundedRating = Double(sum)/Double(numOfRatings)
        return round((10 * unroundedRating)) / 10


    }
    
    //Returns true if the user can claim the squirrel, else it returns false
    func canGetSquirrel() -> Bool {
        if (ratedSquirrel!["owner"] == nil) || (squirrelSlots > 0) {
            return true
        }
        return false
    }
    
    
    func checkIfUserRatedSquirrel(username:String, raters: [String]) -> Bool {
        if (find(raters, username) == nil) {
            return false
        }
        return true
    }
    
    
    func getUserRating(username:String, raters:[String], ratings:[String]) -> String {
        if (find(raters, username) == nil) {
            return "No rating"
        }
        var index = find(raters, username)
        return ratings[index!]
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "tradeSquirrel" {
            let controller = segue.destinationViewController as! TradeViewController
            controller.desiredSquirrelOwner = squirrelOwner!
            controller.desiredSquirrel = ratedSquirrel!
        }

    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    
     //Removes the user's username from the squirrel's "raters" field and their rating from the squirrel's "ratings" field
    func removeOwnerRating(squirrel: PFObject) -> Void {
        var ownerIndex = find(squirrel["raters"] as! [String], PFUser.currentUser()!.username!)
        squirrel.removeObject(PFUser.currentUser()!.username!, forKey: "raters")
        var ratings = squirrel["ratings"] as? [String]
        ratings!.removeAtIndex(ownerIndex!)
        squirrel["ratings"] = ratings
        squirrel.save()
    }


    func validRating(rating: String) -> Bool {
        var validRatings = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        if contains(validRatings, rating) {
            return true
        }
        return false
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var firstName = ratedSquirrel!["first_name"] as! String
        var lastName = ratedSquirrel!["last_name"] as! String
        squirrelNameLabel.text = "\(firstName) \(lastName)"
        
        //Check if the squirrel has an average rating 
        if ratedSquirrel!["avg_rating"] != nil {
            //We have to cast the rating as an Int first, because casting it directly as a String produces nil
            var averageRating = ratedSquirrel!["avg_rating"] as? Int
            avgRatingLabel.text = String(averageRating!)
        } else {
            avgRatingLabel.text = "No Ratings"
        }
        didRateSquirrel = checkIfUserRatedSquirrel(PFUser.currentUser()!["username"] as! String, raters: ratedSquirrel!["raters"] as! [String])
        
        //Check if the user has rated the squirrel
        if didRateSquirrel == true {
            yourRatingLabel.text = getUserRating(PFUser.currentUser()!["username"]! as! String, raters: ratedSquirrel!["raters"]! as! [String], ratings: ratedSquirrel!["ratings"]! as! [String])
            rateNumberTextField.hidden = true
            rateButton.hidden = true
        } else {
            //The user did not rate the squirrel 
            yourRatingLabel.hidden = true
            userRatingLabel.hidden = true
        }
        
        //Check if the squirrel has an owner to propose a trade with
        var owner = ratedSquirrel!["owner"] as? PFUser
        if owner == nil {
            tradeButton.hidden = true
            ownerLabel.hidden = true
            squirrelOwnerLabel.hidden = true
            claimSquirrelButton.enabled = canClaimSquirrel!
        } else if owner?.objectId == PFUser.currentUser()!.objectId {
            //Have to compare ID's - comparing the actual objects will never evaluate as true 
            tradeButton.hidden = true
            ownerLabel.hidden = false
            squirrelOwnerLabel.text = "me"
            claimSquirrelButton.hidden = true
            rateButton.hidden = true
            rateNumberTextField.hidden = true
        } else {
            //Squirrel does have an owner
            ownerLabel.hidden = false
            var owner = ratedSquirrel!["owner"] as! PFUser
            owner.fetch()
            squirrelOwnerLabel.text = owner.username!
            claimSquirrelButton.hidden = true
        }
        rateButton.enabled = false
        rateNumberTextField.delegate = self
        
    }
    
    
    
    //Should be its own extension 
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var oldRating: NSString = ""
            var newRating: NSString = ""
        
        
            oldRating = rateNumberTextField.text
            newRating = oldRating.stringByReplacingCharactersInRange(range, withString: string)
        
            if validRating(newRating as String) == true {
                rateButton.enabled = true
            } else {
                rateButton.enabled = false
            }
            return true 
    }
}
