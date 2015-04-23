//
//  AddSquirrelViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 2/4/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

protocol AddSquirrelViewControllerDelegate: class {
    func addSquirrelViewControllerDidCancel(controller: AddSquirrelViewController)
    func addSquirrelViewController(controller: AddSquirrelViewController, didFinishAddingFirstName firstName: NSString, didFinishAddingLastName lastName: NSString)
}


class AddSquirrelViewController: UITableViewController, UITextFieldDelegate {
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    weak var delegate: AddSquirrelViewControllerDelegate?

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    
    @IBAction func done() {
        let first = firstName.text as NSString
        let last = lastName.text as NSString
        delegate?.addSquirrelViewController(self, didFinishAddingFirstName: first, didFinishAddingLastName: last)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    /* Parameters: error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(error: String) {
        var alert = UIAlertController(title: "Woops! We had a problem", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        firstName.becomeFirstResponder()
        lastName.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        //Set the doneBarButton to 'fa-check-circle'
        doneBarButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "FontAwesome", size: 30)!], forState: UIControlState.Normal)
        doneBarButton.title = "\u{f058}"
        doneBarButton.tintColor = UIColor.whiteColor()
    }
    
    //Should be its own extension 
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
            var untouchedName: NSString = ""
            var oldName: NSString = ""
            var newName: NSString = ""
            if textField.tag == 1 {
                //they are typing in the first name field
                untouchedName = lastName.text
                oldName = firstName.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            } else {
                //they are typing in the last name field 
                untouchedName = firstName.text
                oldName = lastName.text
                newName = oldName.stringByReplacingCharactersInRange(range, withString: string)
            }
        
            if newName.length > 0 && untouchedName.length > 0 {
                doneBarButton.enabled = true
            } else {
                doneBarButton.enabled = false
            }
            return true 
    }


    
}
