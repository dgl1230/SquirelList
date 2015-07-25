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
                    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                }
            }
            
            let currentGroupData = PFUser.currentUser()!["currentGroupData"] as! PFObject
            currentGroupData.fetch()
            let acorns  = currentGroupData["acorns"] as! Int
            let offeredAcorns = acornTextField.text.toInt()
            if offeredAcorns > acorns {
                let title = "You don't have that many acorns!"
                let message = ":("
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            } else {
                tradeProposal["offeredAcorns"] = offeredAcorns
            }
        }
        
       
        tradeProposal.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                let owner = self.desiredSquirrelOwner!["username"] as! String
                let message = "You will be notified if \(owner) accepts your trade."
                let alert = UIAlertController(title: "Trade Offered!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler:  { (action: UIAlertAction!) in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                //Alert the desired Squirrel owner that a trade has been proposed
                let pushQuery = PFInstallation.query()
                let offeringUsername = PFUser.currentUser()!.username
                let desiredSquirrelName = "\(firstName) \(lastName)"
                pushQuery!.whereKey("userID", equalTo: self.desiredSquirrelOwner!.username!)
                let push = PFPush()
                push.setQuery(pushQuery)
                let proposal = "\(PFUser.currentUser()!.username!) has proposed a trade for \(desiredSquirrelName)!"
                let inviteMessage = proposal as NSString
                let pushDict = ["alert": inviteMessage, "badge":"increment", "sounds":"", "content-available": 1]
                push.setData(pushDict)
                push.sendPushInBackgroundWithBlock(nil)
                
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else {
                println(error)
            }
        }
    }
    @IBAction func selectSquirrel(sender: AnyObject) {
        self.performSegueWithIdentifier("userSquirrels", sender: self)
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
        super.viewDidLoad()
        var firstName = desiredSquirrel!["first_name"] as? String
        var lastName = desiredSquirrel!["last_name"] as? String
        desiredSquirrelLabel.text = "\(firstName!) \(lastName!)"
        
        //Check whether we should be displaying the "choose a squirrel to offer" button
        if offeredSquirrel != nil {
            //The user has already selected a squirrel for trading
            var firstName = offeredSquirrel!["first_name"] as? String
            var lastName = offeredSquirrel!["last_name"] as? String
            offeredSquirrelLabel.text = "\(firstName!) \(lastName!)"
            selectSquirrelButton.hidden = true
            proposeTradeButton.enabled = true
        } else if count(acornTextField.text) != 0 {
            //We need to first display the select squirrel button and hide the trade button, since there is no offered squirrel and no proposed acorns
            offeredSquirrelLabel.hidden = true
            proposeTradeButton.enabled = true
        } else {
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
