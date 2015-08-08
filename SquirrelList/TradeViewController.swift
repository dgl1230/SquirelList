//
//  TradeOfferNewViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/24/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


//This view controller is for proposing trades to other users
import UIKit


class TradeViewController: PopUpViewController, UserSquirrelsPopUpViewControllerDelegate, UITextFieldDelegate {

    var desiredSquirrel: PFObject?
    var desiredSquirrelOwner: PFUser?
    var offeredSquirrel: PFObject?


    @IBOutlet weak var desiredSquirrelLabel: UILabel!
    @IBOutlet weak var offeredSquirrelLabel: UILabel!
    @IBOutlet weak var proposeTradeButton: UIButton!
    @IBOutlet weak var selectSquirrelButton: UIButton!
    @IBOutlet weak var acornTextField: UITextField!
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func proposeTrade(sender: AnyObject) {
        var tradeProposal = PFObject(className:"TradeProposal")
        tradeProposal["offeringUser"] = PFUser.currentUser()!
        tradeProposal["offeringUsername"] = PFUser.currentUser()!.username
        if offeredSquirrel != nil {
            tradeProposal["offeredSquirrelID"] = offeredSquirrel!.objectId
        }
        tradeProposal["receivingUser"] = desiredSquirrelOwner!
        //Would like to get rid of fetching
        desiredSquirrelOwner!.fetch()
        tradeProposal["receivingUsername"] = desiredSquirrelOwner!.username
        tradeProposal["proposedSquirrelID"] = desiredSquirrel!.objectId

        var firstName = desiredSquirrel!["first_name"] as! String
        var lastName = desiredSquirrel!["last_name"] as! String
        tradeProposal["desiredSquirrelName"] = "\(firstName) \(lastName)"
        tradeProposal["group"] = PFUser.currentUser()!["currentGroup"] as! PFObject
        
        if acornTextField.text != "" {
            //Then the user is offering acorns and we need to run some checks
            //First we need to check and make sure they only entered in digits
            let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            for char in acornTextField.text {
                if find(digits, String(char)) == nil {
                    let title = ""
                    let message = "Only enter in numbers! You weirdo."
                    displayErrorAlert(title, message: message)
                    return
                }
            }
            
            let currentGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
            currentGroupData.fetch()
            let acorns  = currentGroupData["acorns"] as! Int
            let offeredAcorns = acornTextField.text.toInt()
            //Next we check to make sure the user hasn't offered zero acorns 
            if offeredAcorns == 0 {
                let title = ""
                let message = "Offer at least one acorn you swindler!"
                displayErrorAlert(title, message: message)
            }
            if offeredAcorns > acorns {
                let title = "You don't have that many acorns!"
                let message = ":("
                displayErrorAlert(title, message: message)
                return
            } else {
                tradeProposal["offeredAcorns"] = offeredAcorns
            }
        }
        
       
        tradeProposal.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                //Check to see whether we should prompt the user to enable push notifications
                let hasProposedTrade = PFUser.currentUser()!["hasProposedTrade"] as! Bool
                let hasBeenAskedForPush = PFUser.currentUser()!["hasBeenAskedForPush"] as! Bool
                if (hasBeenAskedForPush == false) && (hasProposedTrade == false) {
                    //This is the first type that the user has proposed a trade and they haven't enabled push notification, so we can   prompt them
                    let title = "Let Squirrel List Access Notifications?"
                    let message = "You'll be alerted if \(self.desiredSquirrelOwner!.username!) accepts your trade."
                    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Not Now", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                        alert.dismissViewControllerAnimated(true, completion: nil)
                        PFUser.currentUser()!["hasProposedTrade"] = true
                        PFUser.currentUser()!.save()
                    }))
                    alert.addAction(UIAlertAction(title: "Give Access", style: .Default, handler: { (action: UIAlertAction!) -> Void in
                        //We ask the user for push notification permission in chat because it's easier to explain why they might need it
                        alert.dismissViewControllerAnimated(true, completion: nil)
                        let notificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
                        let notificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        
                        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                        PFUser.currentUser()!["hasProposedTrade"] = true
                        PFUser.currentUser()!["hasBeenAskedForPush"] = true
                        PFUser.currentUser()!.save()
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    //Show the usual trade alert
                    let owner = self.desiredSquirrelOwner!["username"] as! String
                    let message = "You will be notified if \(owner) accepts your trade."
                    let alert = UIAlertController(title: "Trade Offered!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            
                let pushQuery = PFInstallation.query()
                let offeringUsername = PFUser.currentUser()!.username
                let desiredSquirrelName = "\(firstName) \(lastName)"
                pushQuery!.whereKey("username", equalTo: self.desiredSquirrelOwner!.username!)
                let push = PFPush()
                push.setQuery(pushQuery)
                let proposal = "\(PFUser.currentUser()!.username!) has proposed a trade for \(desiredSquirrelName)!"
                let inviteMessage = proposal as NSString
                let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
                
                
            } else {
                println(error)
            }
        }
    }
    
    
    @IBAction func selectSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("userSquirrels", sender: self)
    }
    
    
    /* Parameters: error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "userSquirrels" {
            let controller = segue.destinationViewController as! UserSquirrelsPopUpViewController
            controller.desiredSquirrel = desiredSquirrel
            controller.desiredSquirrelOwner = desiredSquirrelOwner
            controller.delegate = self
        }
    }
    
    
    override func viewDidLoad() {
        println("VIEW DID LOAD")
        super.viewDidLoad()
        var firstName = desiredSquirrel!["first_name"] as? String
        var lastName = desiredSquirrel!["last_name"] as? String
        desiredSquirrelLabel.text = "\(firstName!) \(lastName!)"
        
        //Check whether we should be displaying the "choose a squirrel to offer" button
        if offeredSquirrel != nil {
            println(12)
            //The user has already selected a squirrel for trading
            var firstName = offeredSquirrel!["first_name"] as? String
            var lastName = offeredSquirrel!["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            selectSquirrelButton.hidden = true
            proposeTradeButton.enabled = true
        } else if count(acornTextField.text) != 0 {
            println(34)
            //We need to first display the select squirrel button and hide the trade button, since there is no offered squirrel and no proposed acorns
            offeredSquirrelLabel.hidden = true
            proposeTradeButton.enabled = true
        } else {
            println(56)
            //The user hasn't offered anything
            proposeTradeButton.enabled = false
            proposeTradeButton.alpha = 0.5
            offeredSquirrelLabel.hidden = true
        }
        //Make the buttons have rounded edges
        proposeTradeButton.layer.cornerRadius = 5
        proposeTradeButton.layer.masksToBounds = true
        selectSquirrelButton.layer.cornerRadius = 5
        selectSquirrelButton.layer.masksToBounds = true
        //For UITextFieldDelegate
        acornTextField.delegate = self
        
    }
    
    //Should be its own extension
    func userSquirrelsPopUpViewControllerDelegate(controller: UserSquirrelsPopUpViewController, selectedSquirrel: PFObject, wantedSquirrelOwner: PFUser, wantedSquirrel: PFObject) {
            //Ghetto way of transfering this info back from previous controller, might be able to get rid of it
            desiredSquirrel = wantedSquirrel
            desiredSquirrelOwner = wantedSquirrelOwner
            offeredSquirrel = selectedSquirrel
        
            var firstName = selectedSquirrel["first_name"] as? String
            var lastName = selectedSquirrel["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            offeredSquirrelLabel.hidden = false
            proposeTradeButton.hidden = false
            //Make it obvious that the button is now enabled
            proposeTradeButton.alpha = 1
            proposeTradeButton.enabled = true
            selectSquirrelButton.hidden = true
        
    }
    
    //For dismissing the keyboard after pressing "done"
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    //UITextFieldDelate used for seeing whether the user has proposed acorns, and if they have,to show the trade button
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            println(string)
            if count(string) > 0 || count(acornTextField.text) >= 2 {
                proposeTradeButton.alpha = 1
                proposeTradeButton.enabled = true
            } else if offeredSquirrel == nil {
                proposeTradeButton.alpha = 0.5
                proposeTradeButton.enabled = false
            }
            return true 
    }

   
}
