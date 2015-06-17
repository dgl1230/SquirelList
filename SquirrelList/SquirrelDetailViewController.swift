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

class SquirrelDetailViewController: PopUpViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //Bool that determines if the logged in user has room to pick up another squirrel
    var canClaimSquirrel: Bool?
    weak var delegate: SquirrelViewController?
    var ratedSquirrel: PFObject?
    var squirrelOwner: PFUser?
    var didRateSquirrel: Bool?
    //Optional for keeping track up how many squirrel slots the user has
    var squirrelSlots: Int?
    //Variable for checking if the user is pressing the claimTradeButton for claiming a squirrel or proposing a trade or uploading a picture
    //Value can be either "claim", "trade", or "uploadPicture"
    var claimOrTradeOrPicture = ""
    

    
    
    //Button that handles claiming a squirrel, trading a squirrel, uploading a squirrel picture, or changing a squirrel picture
    @IBOutlet weak var claimTradePictureButton: UIButton!
    @IBOutlet weak var squirrelNameLabel: UILabel!
    @IBOutlet weak var avgRatingLabel: UILabel!
    
    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var rateNumberTextField: UITextField!
    //Label that displays the owners name
    @IBOutlet weak var squirrelOwnerLabel: UILabel!
    
    @IBOutlet weak var squirrelPic: UIImageView?
    

    
    @IBAction func claimOrTradeOrUploadPicture(sender: AnyObject) {
        if claimOrTradeOrPicture == "claim" {
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
        } else if claimOrTradeOrPicture == "trade" {
            self.performSegueWithIdentifier("tradeSquirrel", sender: self)
        } else if claimOrTradeOrPicture == "uploadPicture" {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }

    
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        println("rating squirrel being called")
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
        //NSNotificationCenter.defaultCenter().postNotificationName(reloadSquirrels, object: self)
        //delegate?.squirrelDetailViewController(self)
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
     //Look into changing this up so that it returns the new ratings array and saves the squirrel else where
    func removeOwnerRating(squirrel: PFObject) -> Void {
        var ownerIndex = find(squirrel["raters"] as! [String], PFUser.currentUser()!.username!)
        squirrel.removeObject(PFUser.currentUser()!.username!, forKey: "raters")
        var ratings = squirrel["ratings"] as? [String]
        ratings!.removeAtIndex(ownerIndex!)
        squirrel["ratings"] = ratings
        squirrel.save()
    }


    func validRating(rating: String) -> Bool {
        var validRatings = ["1", "1.0", "1.5", "2", "2.0", "2.5", "3", "3.0", "3.5", "4", "4.0", "4.5", "5", "5.0", "5.5", "6", "6.0", "6.5", "7", "7.0", "7.5", "8", "8.0", "8.5", "9", "9.0", "9.5", "10", "10.0"]
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
            avgRatingLabel.text = "Squirrel Score:  \(averageRating)"
        } else {
            avgRatingLabel.text = "No Squirrel Score"
        }
        didRateSquirrel = checkIfUserRatedSquirrel(PFUser.currentUser()!["username"] as! String, raters: ratedSquirrel!["raters"] as! [String])
        
        //Check if the user has rated the squirrel
        if didRateSquirrel == true {
            var rating = getUserRating(PFUser.currentUser()!["username"]! as! String, raters: ratedSquirrel!["raters"]! as! [String], ratings: ratedSquirrel!["ratings"]! as! [String])
            rateNumberTextField.placeholder = "Your rating: \(rating)"
            rateButton.setTitle("Rerate", forState: UIControlState.Normal)
        }
        //Check if the squirrel has an owner to propose a trade with
        var owner = ratedSquirrel!["ownerUsername"] as? String
        if owner == nil {
            squirrelOwnerLabel.text = "Owner:  No one :("
            var canClaim = canClaimSquirrel!
            if canClaim == true {
                claimTradePictureButton.setTitle("Claim Squirrel", forState: UIControlState.Normal)
                claimOrTradeOrPicture = "claim"
            } else {
                claimTradePictureButton.hidden = true
            }
        } else if owner == PFUser.currentUser()!.username {
            squirrelOwnerLabel.text = "Owner:  me"
            if ratedSquirrel!["picture"] == nil {
                claimTradePictureButton.setTitle("Upload Picture", forState: UIControlState.Normal)
            } else {
                claimTradePictureButton.setTitle("Change Picture", forState: UIControlState.Normal)
            }
            claimOrTradeOrPicture = "uploadPicture"
            //Owners can't rate or rerate squirrel
            rateButton.hidden = true
            rateButton.enabled = false
            rateNumberTextField.hidden = true
        } else {
            //Squirrel does have an owner that's not the logged in user
            var owner = ratedSquirrel!["ownerUsername"] as! String
            squirrelOwnerLabel.text = "Owner:  \(owner)"
            claimTradePictureButton.setTitle("Propose Trade", forState: UIControlState.Normal)
            claimOrTradeOrPicture = "trade"
        }
        rateNumberTextField.delegate = self
        if ratedSquirrel!["picture"] != nil {
            let pic = ratedSquirrel!["picture"] as! PFFile
            pic.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    let image = UIImage(data: imageData!)
                    self.squirrelPic!.image = image
                    //Make the pic have rounded corners 
                    self.squirrelPic!.layer.cornerRadius = 5
                    self.squirrelPic!.layer.masksToBounds = true
                }
            })
            
        }
        //Give the buttons rounded corners
        claimTradePictureButton.layer.cornerRadius = 5
        claimTradePictureButton.layer.masksToBounds = true
        rateButton.layer.cornerRadius = 5
        rateButton.layer.masksToBounds = true
        
    }
    
    
    
    //TextField Extension to make sure user can't subit a blank or invalid Squirrel rating
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
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        let picture = info[UIImagePickerControllerEditedImage] as? UIImage
        let imageData = UIImagePNGRepresentation(picture)
        let imageFile = PFFile(data: imageData)
        ratedSquirrel!.setObject(imageFile, forKey: "picture")
        ratedSquirrel!.save()
        self.dismissViewControllerAnimated(true, completion: nil)
        //We need to reload the popup with the new picture
        self.viewDidLoad()
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
