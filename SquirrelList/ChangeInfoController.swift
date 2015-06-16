//
//  ChangeInfoViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/6/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

//Manages controllers in the Settings section where the user can change their display name, email address, or password


import UIKit

class ChangeInfoController: UIViewController, UITextFieldDelegate {
    
    //Optional for determing what kind of info the user is changing. Will either be "name" "email" or "password"
    var infoBeingChanged: String?
    //Variable for storing initial value to check if user has changed their value in the infoField
    var placeholder : NSString?
    
    @IBOutlet weak var infoField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func save(sender: AnyObject) {
        if infoBeingChanged == "name" {
            PFUser.currentUser()!["name"] = infoField.text
        } else if infoBeingChanged == "email" {
            PFUser.currentUser()!.email = infoField.text
        } else if infoBeingChanged == "password" {
            PFUser.currentUser()!.password = infoField.text
        }
        PFUser.currentUser()!.save()
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
        infoField.delegate = self
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
