//
//  SquirrelDetailNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/23/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

//For telling SquirrelViewController to reload after updating Squirrel information
protocol NewSquirrelDetailslViewControllerDelegate: class {
    func reloadParent(controller: NewSquirrelDetailsViewController, usedRerate: Bool)
}

class NewSquirrelDetailsViewController: PopUpViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    

    weak var delegate: NewSquirrelDetailslViewControllerDelegate?
    var ratedSquirrel: PFObject?
    var squirrelOwner: PFUser?
    var didRateSquirrel: Bool?
    //Variable for checking if the user is pressing the claimTradeButton for claiming a squirrel or proposing a trade or uploading a picture
    //Value can be either "claim", "trade", or "uploadPicture"
    var claimOrTradeOrPicture = ""
    //Optional for keeping track of if the user can rerate the squirrel - accessed from the UserGroupData model
    var canRerate = false
    //Optional for keeping track up how many squirrel slots the user has
    var squirrelSlots: Int?

    

    
    
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
            self.claimSquirrel()
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

    @IBAction func flagContent(sender: AnyObject) {
        performSegueWithIdentifier("flagContent", sender: self)
    }
    
    
    @IBAction func rateSquirrel(sender: AnyObject) {
        ratedSquirrel!.fetch()
        var rater = PFUser.currentUser()!.username
        //They are re-rating the squirrel
        //Not efficient, look into way to not duplicate code
        if didRateSquirrel == true {
            //Set the global variable back to zero
            LOGGED_IN_USER_RERATES = 0
            var raters = ratedSquirrel!["raters"] as! [String]
            var raterIndex = find(raters, PFUser.currentUser()!.username!)
            raters.removeAtIndex(raterIndex!)
            raters.append(PFUser.currentUser()!.username!)
            var ratings = removeRating(ratedSquirrel!)
            ratings.append(rateNumberTextField.text)
            ratedSquirrel!["ratings"] = ratings
            ratedSquirrel!["raters"] = raters
            ratedSquirrel!["avg_rating"] = calculateAverageRating(ratedSquirrel!["ratings"] as! [String])
            ratedSquirrel!.save()
            //Since the user already rated the squirrel, they had to have purchased a rerate in order to do this, so we need to set userGroupDate["canRerate"] to false
            delegate!.reloadParent(self, usedRerate: true)
            //Alert SquirrelStoreController that Rerate was used, so that it can reload
            NSNotificationCenter.defaultCenter().postNotificationName("didUseRerate", object: nil)
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        //check if ["raters"] is nil. If it is, we create it
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
        delegate!.reloadParent(self, usedRerate: false)
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
        if (ratedSquirrel!["owner"] == nil) && (LOGGED_IN_USER_SQUIRREL_SLOTS > 0) {
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
    
    
    //Assumes that user has already been given permission to claim it  - updates the Squirrel and the logged in user's info to reflect claiming of said squirrel. Assumes that there is a loading animation occuring and that we should stop it after everything has been saved.
    func claimSquirrel() {
        //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
        let viewsArray = displayLoadingAnimator(self.view)
        let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
        let container = viewsArray[1] as! UIView
        let loadingView = viewsArray[2] as! UIView
        ratedSquirrel!.fetch()
        let currentGroup = PFUser.currentUser()!["currentGroup"] as? PFObject
        currentGroup!.fetch()
        let firstName = (ratedSquirrel!["first_name"] as! String).lowercaseString
        let lastName = (ratedSquirrel!["last_name"] as! String).lowercaseString
        let squirrelName = "\(firstName) \(lastName)"
        let squirrelNames = currentGroup!["squirrelFullNames"] as! [String]
        println("SQUIRREL NAME IS \(squirrelName)")
        println(squirrelNames)
        for name in squirrelNames {
            println(name)
            if name == squirrelName {
                println("IT SHOULD BE WORKING")
            }
        }
        //Make sure the squirrel hasn't been deleted  - if it has been, we can still fetch it, but it's fields won't have any values 
        if contains(squirrelNames, squirrelName) == false {
            //Global function that stops the loading animation and dismisses the views it is attached to
            resumeInteractionEvents(activityIndicatorView, container, loadingView)
            var alert = UIAlertController(title: "Whoops", message: "That Squirrel was just deleted! You can re-add it though :)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                //Need to reload squirrel view
                self.delegate!.reloadParent(self, usedRerate: false)
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        if ratedSquirrel!["ownerUsername"] != nil {
            //Global function that stops the loading animation and dismisses the views it is attached to
            resumeInteractionEvents(activityIndicatorView, container, loadingView)
            var alert = UIAlertController(title: "Oops", message: "That Squirrel was just claimed :(", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                //Need to reload squirrel view
                self.delegate!.reloadParent(self, usedRerate: false)
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        //Else there were no errors and we asychonously finish everything up
        dispatch_async(dispatch_get_main_queue()) {
            self.ratedSquirrel!["owner"] = PFUser.currentUser()!
            self.ratedSquirrel!["ownerUsername"] = PFUser.currentUser()!.username
            if self.didRateSquirrel == true {
                var ratings = self.removeRating(self.ratedSquirrel!)
                self.ratedSquirrel!["avg_rating"] = self.calculateAverageRating(ratings)
                self.ratedSquirrel!["ratings"] = ratings
                self.ratedSquirrel!.removeObject(PFUser.currentUser()!.username!, forKey: "raters")
            }
            //var squirrelSlots = getUserInfo(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!).toInt()
            LOGGED_IN_USER_SQUIRREL_SLOTS -= 1
            let newSquirrelSlots = getNewArrayToSave(currentGroup!["squirrelSlots"] as! [String], PFUser.currentUser()!.username!, String(LOGGED_IN_USER_SQUIRREL_SLOTS))
            currentGroup!["squirrelSlots"] = newSquirrelSlots
            currentGroup!.save()
            self.ratedSquirrel!.save()
            //We don't want to send push notifications to the logged in user, since the delegate is reloading the Squirrels tab for them
            let users = (currentGroup!["users"] as! [String]).filter{ $0 != PFUser.currentUser()!.username! }
            //Send silent push notifications for other users to have their Squirrel tab refresh
            sendPushNotifications(0, "", "reloadSquirrels", users)
            //Reload main squirrel view
            self.delegate!.reloadParent(self, usedRerate: false)
            //Global function that stops the loading animation and dismisses the views it is attached to
            resumeInteractionEvents(activityIndicatorView, container, loadingView)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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
        if segue.identifier == "flagContent" {
            let controller = segue.destinationViewController as! FlagContentController
            if squirrelOwner != nil {
                squirrelOwner!.fetch()
                controller.owner = squirrelOwner!.username!
            }
            controller.squirrelID = ratedSquirrel!.objectId!
        }

    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    
    //Removes the user's rating from the squirrel's "ratings" field
    func removeRating(squirrel: PFObject) -> [String] {
        var ownerIndex = find(squirrel["raters"] as! [String], PFUser.currentUser()!.username!)
        var ratings = squirrel["ratings"] as? [String]
        ratings!.removeAtIndex(ownerIndex!)
        return ratings!
    }


    func validRating(rating: String) -> Bool {
        var validRatings = ["1", "1.0", "1.5", "2", "2.0", "2.5", "3", "3.0", "3.5", "4", "4.0", "4.5", "5", "5.0", "5.5", "6", "6.0", "6.5", "7", "7.0", "7.5", "8", "8.0", "8.5", "9", "9.0", "9.5", "10", "10.0"]
        if contains(validRatings, rating) {
            return true
        }
        return false
    }
    
    override func viewDidAppear(animated: Bool) {
        //We need to present the potential alert controller here, because if we try presenting it in viewDidLoad() we get a "view is not in window hierarchy" error
        let ratingAlert = PFUser.currentUser()!["newRatingAlert"] as! Bool
        if ratingAlert == true {
            //The user is new and we need to give them an alert about what ratings they can use and then update their "newRatingAlert" field
            let message = "Rate Squirrels starting at 1 and in increments of 0.5, up to 10."
            var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                    //We only want to show this alert to users once, so we update their "newRatingAlert" field afterwards
                    PFUser.currentUser()!["newRatingAlert"] = false
                    PFUser.currentUser()!.save()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        var firstName = ratedSquirrel!["first_name"] as! String
        var lastName = ratedSquirrel!["last_name"] as! String
        squirrelNameLabel.text = "\(firstName) \(lastName)"
        let squirrelRating = ratedSquirrel!["avg_rating"] as? Double
        
        //Check if the squirrel has an average rating 
        if squirrelRating != 0 && squirrelRating >= 8 {
            //We have to cast the rating as an Int first, because casting it directly as a String produces nil
            avgRatingLabel.text = "Squirrel Score:  \(squirrelRating!)"
        } else  {
            //The squirrel has a rating, but it is too low to show or the squirrel has no rating
            avgRatingLabel.text = "Squirrel Score: ???"
        }
        
        //Check if the user has rated the squirrel
        didRateSquirrel = checkIfUserRatedSquirrel(PFUser.currentUser()!["username"] as! String, raters: ratedSquirrel!["raters"] as! [String])
        if didRateSquirrel == true {
            var rating = getUserRating(PFUser.currentUser()!["username"]! as! String, raters: ratedSquirrel!["raters"]! as! [String], ratings: ratedSquirrel!["ratings"]! as! [String])
            rateNumberTextField.placeholder = "Your rating: \(rating)"
            if canRerate == true {
                rateButton.setTitle("Rerate", forState: UIControlState.Normal)
            }
            rateButton.enabled = false
            //We want it to be obvious that they can't use the rate button
            rateButton.alpha = 0.5

        } else {
            rateButton.enabled = false
            //We want it to be obvious that they can't use the rate button
            rateButton.alpha = 0.5
        }
        //Check if the squirrel has an owner to propose a trade with and if they have a unique picture
        let pic = ratedSquirrel!["picture"] as! PFFile
        var owner = ratedSquirrel!["ownerUsername"] as? String
        if owner == nil {
            squirrelOwnerLabel.text = "Squirreler:  No one :("
            claimOrTradeOrPicture = "claim"
            claimTradePictureButton.setTitle("Claim Squirrel", forState: UIControlState.Normal)
            if canGetSquirrel() == true {
                claimTradePictureButton.enabled = true
            } else {
                claimTradePictureButton.enabled = false
                claimTradePictureButton.alpha = 0.5
            }
            
        } else if owner == PFUser.currentUser()!.username {
            squirrelOwnerLabel.text = "Squirreler:  me"
            //Check if the squirrel has a default picture
            if pic.name.rangeOfString("Squirrel_Profile_Pic") != nil {
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
            squirrelOwnerLabel.text = "Squirreler:  \(owner)"
            claimTradePictureButton.setTitle("Propose Trade", forState: UIControlState.Normal)
            claimOrTradeOrPicture = "trade"
        }

        //Fetch picture file
        pic.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    let image = UIImage(data: imageData!)
                    self.squirrelPic!.image = image
                    //Make the pic have rounded corners 
                    self.squirrelPic!.layer.cornerRadius = 5
                    self.squirrelPic!.layer.masksToBounds = true
                }
        })
        
        //Give the buttons rounded corners
        claimTradePictureButton.layer.cornerRadius = 5
        claimTradePictureButton.layer.masksToBounds = true
        rateButton.layer.cornerRadius = 5
        rateButton.layer.masksToBounds = true
        //We only need to know what the user is entering in the rateNumberTextField if they can rate the squirrel
        if didRateSquirrel == false || canRerate == true {
            rateNumberTextField.delegate = self
        }
    }
    
    
    
    //TextField Extension to make sure user can't subit a blank or invalid Squirrel rating
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var oldRating: NSString = ""
            var newRating: NSString = ""
        
            oldRating = rateNumberTextField.text
            newRating = oldRating.stringByReplacingCharactersInRange(range, withString: string)
        
            if validRating(newRating as String) == true {
                rateButton.enabled = true
                rateButton.alpha = 1
            } else {
                rateButton.enabled = false
                rateButton.alpha = 0.5
            }
            return true 
    }
    
    //For dismissing the keyboard after pressing "done"
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
        let viewsArray = displayLoadingAnimator(picker.view)
        let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
        let container = viewsArray[1] as! UIView
        let loadingView = viewsArray[2] as! UIView
        
        dispatch_async(dispatch_get_main_queue()) {
            let picture = info[UIImagePickerControllerEditedImage] as! UIImage
            let imageData = picture.lowestQualityJPEGNSData
            let imageFile = PFFile(data: imageData)
            self.ratedSquirrel!.setObject(imageFile, forKey: "picture")
            self.ratedSquirrel!.saveInBackgroundWithBlock { (succeeded: Bool, error: NSError?) -> Void in
                if error == nil {
                    //We need to reload the popup with the new picture
                    self.viewDidLoad()
                    //Global function that stops the loading animation and dismisses the views it is attached to
                    resumeInteractionEvents(activityIndicatorView, container, loadingView)
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    //There was an error and display it
                    //Global function that stops the loading animation and dismisses the views it is attached to
                    resumeInteractionEvents(activityIndicatorView, container, loadingView)
                    displayAlert(self, "Ooops", "There was an error. Would you mind trying again?")
                    
                }
            }

            
        }
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


//Extending the UIImage class so we can save pictures in much lower quality (which is much faster)
extension UIImage {
    var highestQualityJPEGNSData:NSData { return UIImageJPEGRepresentation(self, 1.0) }
    var highQualityJPEGNSData:NSData    { return UIImageJPEGRepresentation(self, 0.75)}
    var mediumQualityJPEGNSData:NSData  { return UIImageJPEGRepresentation(self, 0.5) }
    var lowQualityJPEGNSData:NSData     { return UIImageJPEGRepresentation(self, 0.25)}
    var lowestQualityJPEGNSData:NSData  { return UIImageJPEGRepresentation(self, 0.0) }
}


