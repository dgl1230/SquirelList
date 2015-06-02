//
//  LoginViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 5/28/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    

    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func login(sender: AnyObject) {
        println("clicked")
        var error = ""
    
        if usernameTextField.text == "" || passwordTextField.text == "" {
            error = "We need your username and password to login"
        }
        
        if error != "" {
            displayErrorAlert("Whoops! We had a problem", message: error)
        } else {
            displayLoadingAnimator()
 
            PFUser.logInWithUsernameInBackground(usernameTextField.text, password:passwordTextField.text) {
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
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            //Present the tab bar with all the tabs
                            appDelegate.window!.rootViewController = HomeTabViewController()
                            appDelegate.window!.makeKeyAndVisible()
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
        if sender?.identifier == "register" {
            let controller = segue.destinationViewController as! RegisterViewController
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
    }
   

}
