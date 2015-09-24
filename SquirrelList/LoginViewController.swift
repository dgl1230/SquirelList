//
//  LoginViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 5/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!

    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func login(sender: AnyObject) {
        var error = ""
    
        if usernameTextField.text == "" || passwordTextField.text == "" {
            error = "We need your username and password to login"
        }
        let username = usernameTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if error != "" {
            displayErrorAlert("Whoops! We had a problem", message: error)
        } else {
            //Global function that starts the loading animation and returns an array of [NVAcitivtyIndicatorView, UIView, UIView] so that we can pass these views into resumeInterActionEvents() later to suspend animation and dismiss the views
            let viewsArray = displayLoadingAnimator(self.view)
            let activityIndicatorView = viewsArray[0] as! NVActivityIndicatorView
            let container = viewsArray[1] as! UIView
            let loadingView = viewsArray[2] as! UIView
            PFUser.logInWithUsernameInBackground(username, password:passwordTextField.text!) {
                (user: PFUser?, signupError: NSError?) -> Void in
                    if signupError ==  nil {
                        //Global function that stops the loading animation and dismisses the views it is attached to
                        resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                        if PFUser.currentUser()!["currentGroup"] == nil {
                            //Then they need to be directed just to the more tab
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
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            //Present the tab bar with all the tabs
                            appDelegate.window!.rootViewController = HomeTabViewController()
                            appDelegate.window!.makeKeyAndVisible()
                            //Make keyboard disappear
                            self.view.endEditing(true)
                        }
                    } else {
                        if let errorString = signupError!.userInfo["error"] as? String {
                            error = errorString
                        } else {
                            error = "There was a random bug :( Please try again"
                        }
                        resumeInteractionEvents(activityIndicatorView, container: container, loadingView: loadingView)
                        self.displayErrorAlert("Whoops! We had a problem", message: error)
                    }
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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the close button icon to 'fa-times'
        closeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        closeButton.setTitle("\u{f00d}", forState: .Normal)
        //Set the login button to have rounded edges
        loginButton.layer.cornerRadius = 5
        loginButton.layer.masksToBounds = true
        //So we can dismiss the kayboards after pressing "done"
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    //For dismissing the keyboard after pressing "done"
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
   

}
