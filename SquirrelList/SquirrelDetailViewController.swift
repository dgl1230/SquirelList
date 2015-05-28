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
    //Variable for checking if the user is pressing the claimTradeButton for claiming a squirrel or proposing a trade
    var claimOrTrade = ""
    

    
    
    
    @IBOutlet weak var claimTradeButton: UIButton!
    @IBOutlet weak var squirrelNameLabel: UILabel!
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    //Label that says "owner:" doesn't actually say the owner's name
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var rateNumberTextField: UITextField!
    //Label that displays the owners name
    @IBOutlet weak var squirrelOwnerLabel: UILabel!
    //This label displays the user's actual rating
    @IBOutlet weak var userRatingLabel: UILabel!
    //The label that says "Your Rating" - it does not actually display the rating
    @IBOutlet weak var yourRatingLabel: UILabel!
    
    
    
    
    @IBAction func claimOrTrade(sender: AnyObject) {
        if claimOrTrade == "claim" {
            ratedSquirrel!["owner"] = PFUser.currentUser()!
            ratedSquirrel!["ownerUsername"] = PFUser.currentUser()!.username
            if didRateSquirrel == true {
                removeOwnerRating(ratedSquirrel!)
                ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as! [String])
            }
            ratedSquirrel!.save()
            //Alert SquirrelViewController to reload data
            NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.performSegueWithIdentifier("tradeSquirrel", sender: self)
        }
    }

    
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        //check if ["raters"] is nil. If it is, we create it
        var rater = PFUser.currentUser()!.username
        if let check: AnyObject = ratedSquirrel!["raters"] {
           ratedSquirrel!["raters"]!.addObject(rater!)
        } else {
            ratedSquirrel!["raters"] = [rater!]
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
        var validRatings = ["1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9", "9.5", "10"]
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
            var averageRating = ratedSquirrel!["avg_rating"] as! Double
            avgRatingLabel.text = "\(averageRating)"
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
            if ratedSquirrel!["ownerUsername"] as? String == PFUser.currentUser()!.username {
                yourRatingLabel.text = "N/A"
            } else {
                yourRatingLabel.text = "No Rating"
            }
        }
        
        //Check if the squirrel has an owner to propose a trade with
        var owner = ratedSquirrel!["ownerUsername"] as? String
        if owner == nil {
            ownerLabel.text = "No one :("
            var canClaim = canClaimSquirrel!
            println(canClaim)
            if canClaim == true {
                claimTradeButton.setTitle("Claim Squirrel", forState: UIControlState.Normal)
                claimTradeButton.enabled = true
                claimOrTrade = "claim"
            } else {
                claimTradeButton.hidden = true
            }
        } else if owner == PFUser.currentUser()!.username {
            squirrelOwnerLabel.text = "me"
            claimTradeButton.hidden = true
            rateButton.hidden = true
            rateNumberTextField.hidden = true
        } else {
            //Squirrel does have an owner
            ownerLabel.hidden = false
            var owner = ratedSquirrel!["ownerUsername"] as! String
            squirrelOwnerLabel.text = owner
            claimTradeButton.setTitle("Propose Trade", forState: UIControlState.Normal)
            claimOrTrade = "trade"
        }
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
