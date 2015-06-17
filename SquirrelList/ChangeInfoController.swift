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
    
    //Optional for determing what kind of info the user is changing. Will either be "name" or "email"
    var infoBeingChanged: String?
    //Variable for storing initial value to check if user has changed their value in the infoField
    var placeholder : NSString?
    weak var delegate: ChangeInfoViewControllerDelegate?
    
    
    @IBOutlet weak var infoField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func save(sender: AnyObject) {
        if infoBeingChanged == "name" {
            PFUser.currentUser()!["name"] = infoField.text
            PFUser.currentUser()!.save()
            self.navigationController?.popViewControllerAnimated(true)
            //Reloads the SettingsViewContrller
            delegate!.finishedSaving(self)
        } else if infoBeingChanged == "email" {
            PFUser.currentUser()!.email = infoField.text
            let alertController = UIAlertController(title: "Email Sent!", message: "Please check your email to verify your address", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    //We duplicate this code from above because we only want these actions to occur after the user has pressed OK
                    PFUser.currentUser()!.save()
                    self.navigationController?.popViewControllerAnimated(true)
                    //Reloads the SettingsViewContrller
                    self.delegate!.finishedSaving(self)
            }))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if infoBeingChanged == "name" {
            infoField.text = PFUser.currentUser()!["name"] as? String
            placeholder = PFUser.currentUser()!["name"] as? String
            self.title = "My Name"
        } else if infoBeingChanged == "email" {
            infoField.text = PFUser.currentUser()!.email
            placeholder = infoField.text
            self.title = "My Email"
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
