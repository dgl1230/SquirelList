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
            error = "We need your email and password to login"
        }
        
        if error != "" {
            displayErrorAlert(error)
        } else {
            displayLoadingAnimator()
 
            PFUser.logInWithUsernameInBackground(usernameLogin.text, password:passwordLogin.text) {
                (user: PFUser!, signupError: NSError!) -> Void in
                    self.resumeInteractionEvents()
                    if signupError ==  nil {
                        self.performSegueWithIdentifier("jumpToHome", sender: self)
                    } else {
                        if let errorString = signupError.userInfo?["error"] as? String {
                            error = errorString
                        } else {
                            error = "There was a random bug :( Please try again"
                        }
                        self.displayErrorAlert(error)
                    }
            }
        }
    }
    
    
    
    
    @IBAction func register(sender: AnyObject) {
        var error = ""
        
        if emailRegister.text == "" || usernameRegister.text == "" || passwordRegister == "" || verifyPasswordRegister == "" {
            error = "Please make sure you fill in all fields"
        } else if passwordRegister.text != verifyPasswordRegister.text {
            error = "Please make sure both passwords match"
        }
        
        if error != "" {
            displayErrorAlert(error)
        } else {
            var user = PFUser()
            user.email = emailRegister.text
            user.password = passwordRegister.text
            user.username = usernameRegister.text
            user["num_of_squirrels"] = 0
    
            displayLoadingAnimator()
    
            user.signUpInBackgroundWithBlock {
                (succeeded: Bool!, signupError: NSError!) -> Void in
                    self.resumeInteractionEvents()
            
                if signupError == nil {
                    self.performSegueWithIdentifier("jumpToHome", sender: self)
                } else {
                    if let errorString = signupError.userInfo?["error"] as? String {
                        error = errorString
                    } else {
                        error = "There was a random bug :( Please try again"
                    }
                    self.displayErrorAlert(error)
                }
            }
        }
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
    
    
    
    
    
    override func viewDidAppear(animated: Bool)  {
        if PFUser.currentUser() != nil {
                self.performSegueWithIdentifier("jumpToHome", sender: self)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    

    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
