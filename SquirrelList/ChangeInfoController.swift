//
//  ChangeInfoViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/6/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.


//Manages controllers in the Settings section where the user can change their display name, email address, or password

import UIKit

//Delegate so that SettingsViewController can reload with the information that the user just changed

protocol ChangeInfoViewControllerDelegate: class {
    func finishedSaving(controller: ChangeInfoController)
}


class ChangeInfoController: UIViewController, UITextFieldDelegate {
    
    //Optional for determing what kind of info the user is changing. Will either be "name" or "email" or "report"
    var infoBeingChanged: String?
    //Variable for storing initial value to check if user has changed their value in the infoField
    var placeholder : NSString?
    weak var delegate: ChangeInfoViewControllerDelegate?
    
    
    @IBOutlet weak var infoField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var reportExplanationField: UITextView?
    
    @IBAction func save(sender: AnyObject) {
        if infoBeingChanged == "name" {
            if count(infoField.text) > 15 {
                displayErrorAlert("That name is too long!", message: "Please keep it to under 15 characters. Amateur.")
                return
            }
            PFUser.currentUser()!["name"] = infoField.text
            PFUser.currentUser()!.save()
            self.navigationController?.popViewControllerAnimated(true)
            //Reloads the SettingsViewContrller with the new name
            delegate!.finishedSaving(self)
        } else if infoBeingChanged == "email" {
            if count(infoField.text) > 30 {
                displayErrorAlert("That email is too long!", message: "Please keep it to under 30 characters. Amateur.")
                return
            }
            PFUser.currentUser()!.email = infoField.text
            //Users will get an email by dint of us changing their email field
            let alertController = UIAlertController(title: "Email Sent!", message: "Please check your email to verify your address", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //We duplicate this code from above because we only want these actions to occur after the user has pressed OK
                    PFUser.currentUser()!.save()
                    self.navigationController?.popViewControllerAnimated(true)
                    //Reloads the SettingsViewContrller with the new email
                    self.delegate!.finishedSaving(self)
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else if infoBeingChanged == "report" {
            let report = PFObject(className: "Report")
            report["offendingUsername"] = infoField.text
            report["explanation"] = reportExplanationField!.text
            report["offendedUser"] = PFUser.currentUser()!.username!
            let alertController = UIAlertController(title: "Report sent!", message: "Thanks for letting us know. We'll get to the bottom of this quickly.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //We duplicate this code from above because we only want these actions to occur after the user has pressed OK
                    report.save()
                    self.navigationController?.popViewControllerAnimated(true)
                    //Reloads the SettingsViewContrller
            }))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    /* Parameters: error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if infoBeingChanged == "name" {
            infoField.text = PFUser.currentUser()!["name"] as? String
            placeholder = PFUser.currentUser()!["name"] as? String
            self.title = "My Name"
        } else if infoBeingChanged == "email" {
            //For some reason accessing email via currentUser()!.email results in an error
            let email = PFUser.currentUser()!["email"] as? String
            if email!.rangeOfString("squirrellist") != nil {
                //This is our rachet, fake email for all users and we should not display it
                infoField.text = ""
            } else {
                infoField.text = PFUser.currentUser()!.email
            }
            placeholder = email
            self.title = "My Email"
        } else if infoBeingChanged == "report" {
            self.title = "Support"
            saveButton.setTitle("Report", forState: UIControlState.Normal)
        }
        //So we can detect what the user is typing and whether or not to enable the save button
        infoField.delegate = self
        //Give save button rounded edges
        saveButton.layer.cornerRadius = 5
        saveButton.layer.masksToBounds = true
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var oldInfo: NSString = infoField.text
            var newInfo: NSString = ""
            newInfo = oldInfo.stringByReplacingCharactersInRange(range, withString: string)
            if newInfo.length > 0 && newInfo != placeholder {
                saveButton.enabled = true
            } else {
                saveButton.enabled = false
            }
            return true 
    }
    

}
