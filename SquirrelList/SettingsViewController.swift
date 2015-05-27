//
//  SettingsViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 3/29/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {


    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    func emailDidBeginEditing() {
        emailTextField.text = PFUser.currentUser()!.email
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.placeholder = PFUser.currentUser()!.email
        emailTextField.adjustsFontSizeToFitWidth = true
        usernameLabel.text = PFUser.currentUser()!.username

        //emailTextField.addTarget(self, action: "emailDidBegingEditing", forControlEvents: UIControlEvents.EditingDidBegin)
        }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.tag == 69 {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginController = mainStoryboard.instantiateViewControllerWithIdentifier("LoginRegisterViewController") as! RegisterLoginViewController
            appDelegate.window!.rootViewController = loginController
            appDelegate.window!.makeKeyAndVisible()
            PFUser.logOut()
        }
        
    
    }
    


   

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
