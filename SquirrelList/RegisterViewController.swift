//
//  RegisterViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 5/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func privacyPolicy(sender: AnyObject) {
        self.performSegueWithIdentifier("privacyPolicy", sender: self)
    }
    
    @IBAction func termsOfService(sender: AnyObject) {
        self.performSegueWithIdentifier("termsOfService", sender: self)
    }
    
    


    @IBAction func register(sender: AnyObject) {
        var error = ""
        var title = ""
        var username = usernameTextField.text
        var usernameLower = username.lowercaseString
        var usernameQuery = PFUser.query()
        //We want to make sure a user can't signup with an exact username that's taken or a username that differs in case
        //Change this, don't want to be getting query error for no results matching if this is what is supposed to happen
        usernameQuery?.whereKey("lowerUsername", equalTo: usernameLower)
        var usernameCheck = usernameQuery?.getFirstObject()
        if usernameCheck != nil {
            title = "That username is taken!"
            error = "Sorry but someone already has that username"
        } else if usernameTextField.text == "" || passwordTextField == "" || verifyPasswordTextField == "" {
            title = "Whoa there cowboy!"
            error = "Please make sure you fill in all fields"
        } else if count(username) <= 2 {
            title = "That username is too short!"
            error = "Please have it be at least three characters"
        } else if count(username) >= 20 {
            title = "That username is too long"
            error = "Please have it be no greater than 20 characters"
        } else if count(passwordTextField.text) <= 6 {
            title = "Whoa there cowboy!"
            error = "Your password needs to be at least 6 characters"
        } else if passwordTextField.text != verifyPasswordTextField.text {
            title = "Whoa there cowboy!"
            error = "Please make sure both passwords match"
        }
        
        if title != "" && error != ""{
            displayErrorAlert(title, message: error)
        } else {
            var user = PFUser()
            user.password = passwordTextField.text
            user.username = usernameTextField.text
            //This field is so that we can check and prevent a user from signing up with the same username but different case sensitivity. We don't want two users with usernames "denis" and "Denis"
            user["lowerUsername"] = usernameTextField.text.lowercaseString
            user["friends"] = []
            user["pendingFriends"] = []
            user["newUserTab"] = true
            user["newSquirrelTab"] = true
            user["newMoreTab"] = true
            user["strikes"] = 0
            user["recentStrike"] = false
            //Give user a fake, unique email address to fill space until they change it in their settings
            let randomNumer = Int(arc4random_uniform(1000))
            let emailName = "\(username)\(randomNumer)"
            user.email = "\(emailName)@squirrellist.com"
    
            displayLoadingAnimator()
    
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, signupError: NSError?) -> Void in
                    self.resumeInteractionEvents()
            
                if signupError == nil {
                    //For push notifications/chat real time might cause an error right now. Not sure if user is already logged in at this point
                    let installation = PFInstallation.currentInstallation()
                    installation["userID"] = PFUser.currentUser()!.username
                    installation["user"] = PFUser.currentUser()!
                    installation.saveInBackgroundWithBlock(nil)
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
                    let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
                    moreController.isNewUser = true
                    let navigationController = UINavigationController(rootViewController: moreController)
                    navigationController.navigationBar.barTintColor = UIColor(red: 0, green: 50, blue: 255, alpha: 1)
                    appDelegate.window!.rootViewController = navigationController
                    appDelegate.window!.makeKeyAndVisible()
                    //Make keyboard disappear
                    self.view.endEditing(true)
                } else {
                    if let errorString = signupError!.userInfo?["error"] as? String {
                        error = errorString
                    } else {
                        error = "There was a random bug :( Please try again"
                    }
                    self.displayErrorAlert("Whoops! We had an error", message: error)
                }
            }
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
    
    /*
    What this does: Creates a loading spinner in the center of the view that disables all Interaction events. To enable
    interaction events, the function resumeInteractionEvents() musts be called
    */
    
    func displayLoadingAnimator() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "privacyPolicy" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy = "Privacy Policy"
        } else if segue.identifier == "termsOfService" {
            let controller = segue.destinationViewController as! PoliciesViewController
            controller.policy = "Terms of Service"
        }
    }
    
    
    /*
    What this does: Stops animating the activity indicator of self and calls endsIgnoringInteractionEvents()
    */
    
    func resumeInteractionEvents() {
        self.activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the close button icon to 'fa-times'
        closeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        closeButton.setTitle("\u{f00d}", forState: .Normal)
        //Set the register button to have rounded edges
        registerButton.layer.cornerRadius = 5
        registerButton.layer.masksToBounds = true

    }




}
