//
//  ForgotPasswordViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 6/15/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//



import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func sendEmail(sender: AnyObject) {
        let email = emailTextField.text
        PFUser.requestPasswordResetForEmail(email!)
        PFUser.requestPasswordResetForEmailInBackground(email!, block: { (succeeded: Bool, error: NSError?) -> Void in
            if succeeded == true {
                let alertController = UIAlertController(title: "Email Sent!", message: "Please check your email to reset your password", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }))
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                //There was an error
                let alertController = UIAlertController(title: "We had an error!", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //Give send button rounded edges
        sendButton.layer.cornerRadius = 5
        sendButton.layer.masksToBounds = true

    }


}
