//
//  RegisterViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 5/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {

    
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
        let username = usernameTextField.text
        let usernameLower = username!.lowercaseString
        let usernameQuery = PFUser.query()
        //We want to make sure a user can't signup with an exact username that's taken or a username that differs in case
        //Change this, don't want to be getting query error for no results matching if this is what is supposed to happen
        usernameQuery?.whereKey("lowerUsername", equalTo: usernameLower)
        let usernameCheck = usernameQuery?.getFirstObject()
        let whitespace = NSCharacterSet.whitespaceCharacterSet()
        if usernameCheck != nil {
            title = "That username is taken!"
            error = "Please try a different username"
        } else if usernameTextField.text == "" || passwordTextField == "" || verifyPasswordTextField == "" {
            title = "Whoa there cowboy!"
            error = "Please make sure you fill in all fields"
        } else if username!.characters.count <= 2 {
            title = "That username is too short!"
            error = "Please have it be at least three characters"
        } else if username!.characters.count >= 15 {
            title = "That username is too long"
            error = "Please have it be no greater than 15 characters"
        } else if passwordTextField.text!.characters.count <= 6 {
            title = "Whoa there cowboy!"
            error = "Your password needs to be at least 6 characters"
        } else if passwordTextField.text != verifyPasswordTextField.text {
            title = "Whoa there cowboy!"
            error = "Please make sure both passwords match"
        } else if (username!.rangeOfCharacterFromSet(whitespace, options: [], range: nil) != nil) {
            title = "Whoa there cowboy!"
            error = "Please don't have any whitespaces in your username"
        } else if (passwordTextField.text!.rangeOfCharacterFromSet(whitespace, options: [], range: nil)) != nil {
            title = "Whoa there cowboy!"
            error = "Please don't have any whitespaces in your password"
        }
        
        if title != "" && error != ""{
            displayErrorAlert(title, message: error)
        } else {
            let user = PFUser()
            user.password = passwordTextField.text
            user.username = usernameTextField.text
            //This field is so that we can check and prevent a user from signing up with the same username but different case sensitivity. We don't want two users with usernames "denis" and "Denis"
            user["lowerUsername"] = usernameTextField.text!.lowercaseString
            user["newUserTab"] = true
            user["newSquirrelTab"] = true
            user["newMoreTab"] = true
            user["newRatingAlert"] = true
            user["hasFriended"] = false
            user["hasProposedTrade"] = false
            user["hasSeenChat"] = false
            user["hasSeenMoreTab"] = false
            user["hasBeenAskedForPush"] = false
            user["strikes"] = 0
            user["recentStrike"] = false
            //Create a UserFriendsData instance and have user "userFriendsData" field point to it 
            let userFriendsData = PFObject(className: "UserFriendsData")
            userFriendsData["username"] = usernameTextField.text
            userFriendsData["friends"] = []
            userFriendsData["pendingInviters"] = []
            userFriendsData["pendingInvitees"] = []
            userFriendsData["groupInvites"] = 0
            userFriendsData["friendAdded"] = false
            userFriendsData["lowerUsername"] = usernameTextField.text!.lowercaseString
            user["friendData"] = userFriendsData
            //Give user a fake, unique email address to fill space until they change it in their settings
            let randomNumer = Int(arc4random_uniform(1000))
            let emailName = "\(username!)\(randomNumer)"
            user.email = "\(emailName)@squirrellist.com"
            //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
            let viewsArray = displayLoadingAnimator(self.view)
            let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
            let container = viewsArray[1] as! UIView
            let loadingView = viewsArray[2] as! UIView
    
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, signupError: NSError?) -> Void in
                    //Function found in GlobalFunctions file - suspends loading animation
                    //resumeInteractionEvents(self.activityIndicatorView!)
            
                    if signupError == nil {
                        //For push notifications/chat real time might cause an error right now. Not sure if user is already logged in at this point
                        let installation = PFInstallation.currentInstallation()
                        installation["username"] = self.usernameTextField.text
                        installation.saveInBackgroundWithBlock(nil)
                        //We only want to save the UserFriendsData instance if the user successfully registered
                        userFriendsData.save()
                    
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
                        let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
                        moreController.isNewUser = true
                        let navigationController = UINavigationController(rootViewController: moreController)
                        let blue = UIColor(red: 0, green: 191/255, blue: 1, alpha: 1)
                        navigationController.navigationBar.barTintColor = blue
                    
                        appDelegate.window!.rootViewController = navigationController
                        appDelegate.window!.makeKeyAndVisible()
                    } else {
                        if let errorString = signupError!.userInfo["error"] as? String {
                            error = errorString
                        } else {
                            error = "There was a random bug :( Please try again"
                        }
                        self.displayErrorAlert("Whoops! We had an error", message: error)
                    }
                //Global function that stops the loading animation and dismisses the views it is attached to
                resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
            }
        }
    }
    

    
    
    /* Parameters: error, which is the error that the user should see in the UIAlertController
    What this does: displays a UIAlertController with a specified error and dismisses it when they press OK
    */
    func displayErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the close button icon to 'fa-times'
        closeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        closeButton.setTitle("\u{f00d}", forState: .Normal)
        //Set the register button to have rounded edges
        registerButton.layer.cornerRadius = 5
        registerButton.layer.masksToBounds = true
        //So we can dismiss the keyboards by pressing "done"
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        verifyPasswordTextField.delegate = self
    }
    
    
    //For dismissing the keyboard after pressing "done"
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    




}
