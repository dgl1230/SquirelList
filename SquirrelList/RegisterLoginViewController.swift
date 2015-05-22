//
//  RegisterViewController.swift
//  SquirelList
//
//  Created by Denis Geary Lopez on 1/25/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class RegisterLoginViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    //Login IBOutlets
    @IBOutlet weak var usernameLogin: UITextField!
    @IBOutlet weak var passwordLogin: UITextField!
    
    //Registering IBOutlets 
    @IBOutlet weak var emailRegister: UITextField!
    @IBOutlet weak var usernameRegister: UITextField!
    @IBOutlet weak var passwordRegister: UITextField!
    @IBOutlet weak var verifyPasswordRegister: UITextField!
    
    
    @IBAction func login(sender: AnyObject) {
        var error = ""
    
        if usernameLogin.text == "" || passwordLogin.text == "" {
            println("login error")
            error = "We need your username and password to login"
        }
        
        if error != "" {
            println(error)
            displayErrorAlert("Whoops! We had a problem", message: error)
        } else {
            displayLoadingAnimator()
 
            PFUser.logInWithUsernameInBackground(usernameLogin.text, password:passwordLogin.text) {
                (user: PFUser?, signupError: NSError?) -> Void in
                    self.resumeInteractionEvents()
                    if signupError ==  nil {
                        if PFUser.currentUser()!["currentGroup"] == nil {
                            //Then they need to be directed just to the more tab
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            let mainStoryboard = UIStoryboard(name: "More", bundle: nil)
                            let moreController = mainStoryboard.instantiateViewControllerWithIdentifier("More") as! MoreTableViewController
                            moreController.isNewUser = true
                            let navigationController = UINavigationController(rootViewController: moreController)
                            navigationController.navigationBar.barTintColor = UIColor(red: 0, green: 50, blue: 255, alpha: 1)
                            appDelegate.window!.rootViewController = navigationController
                            appDelegate.window!.makeKeyAndVisible()
                        } else {
                            self.performSegueWithIdentifier("jumpToHome", sender: self)
                        }
                    } else {
                        if let errorString = signupError!.userInfo?["error"] as? String {
                            error = errorString
                        } else {
                            error = "There was a random bug :( Please try again"
                        }
                        self.displayErrorAlert("Whoops! We had a problem", message: error)
                    }
            }
        }
    }
    
    
    
    
    @IBAction func register(sender: AnyObject) {
        var error = ""
        var title = ""
        var username = usernameRegister.text
        var usernameLower = username.lowercaseString
        var usernameQuery = PFUser.query()
        //We want to make sure a user can't signup with an exact username that's taken or a username that differs in case
        usernameQuery?.whereKey("lowerUsername", equalTo: usernameLower)
        var usernameCheck = usernameQuery?.getFirstObject()
        if usernameCheck != nil {
            title = "That username is taken!"
            error = "Sorry but someone already has that username"
        } else if count(username) <= 2 {
            title = "That username is too short!"
            error = "Please have it be at least three characters"
        } else if count(username) >= 15 {
            title = "That username is too short!"
            error = "Please have it be at least three characters"
        } else if emailRegister.text == "" || usernameRegister.text == "" || passwordRegister == "" || verifyPasswordRegister == "" {
            title = "Whoa there cowboy!"
            error = "Please make sure you fill in all fields"
        } else if count(passwordRegister.text) <= 6 {
            title = "Whoa there cowboy!"
            error = "Your password needs to be at least 6 characters"
        } else if passwordRegister.text != verifyPasswordRegister.text {
            title = "Whoa there cowboy!"
            error = "Please make sure both passwords match"
        }
        
        if title != "" && error != ""{
            displayErrorAlert(title, message: error)
        } else {
            var user = PFUser()
            user.email = emailRegister.text
            user.password = passwordRegister.text
            user.username = usernameRegister.text
            //This field is so that we can check and prevent a user from signing up with the same username but different case sensitivity. We don't want two users with usernames "denis" and "Denis"
            user["lowerUsername"] = usernameRegister.text.lowercaseString
            user["num_of_squirrels"] = 0
            user["current_group"] = "first_group"
            user["friends"] = []
    
            displayLoadingAnimator()
    
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool, signupError: NSError?) -> Void in
                    self.resumeInteractionEvents()
            
                if signupError == nil {
                    //For push notifications/chat real time might cause an error right now. Not sure if user is already logged in at this point
                    let installation = PFInstallation.currentInstallation()
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
                    //self.performSegueWithIdentifier("jumpToHome", sender: self)
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
    
    
    

    
    /*
    What this does: Stops animating the activity indicator of self and calls endsIgnoringInteractionEvents()
    */
    
    func resumeInteractionEvents() {
        self.activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    
    }
    
    
    
    
    
    override func viewDidAppear(animated: Bool) {
        if PFUser.currentUser() != nil {
                self.performSegueWithIdentifier("jumpToHome", sender: self)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }


}
