//
//  FeedbackViewController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 9/13/15.
//  Copyright © 2015 Frenvu Inc. All rights reserved.
//

import UIKit

class FeedbackViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var feedbackField: UITextView!
    
    
    @IBAction func save(sender: AnyObject) {
        let feedback = PFObject(className: "Feedback")
        feedback["username"] = PFUser.currentUser()!.username!
        feedback["feedback"] = feedbackField.text
        let alertController = UIAlertController(title: "Feedback Sent", message: "Thanks so much taking the time to let us know your thoughts. Everyone at Squirrel List appreciates it!", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                feedback.save()
                self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Feedback"
        //We want it to be obvious that the button is not enabled at first
        sendButton.alpha = 0.5
        feedbackField.delegate = self
        //So we can detect what the user is typing and whether or not to enable the save button
        //Give save button rounded edges
        sendButton.layer.cornerRadius = 5
        sendButton.layer.masksToBounds = true
    }
    
    
    //For getting "done" button to dismiss keyboard on the report explanation textView
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
            //Make it so that pressing "done" dismisses the kayboard
            if text == "\n" {
                feedbackField.resignFirstResponder()
                return false
            }
            let oldInfo: NSString = feedbackField.text
            var newInfo: NSString = ""
            newInfo = oldInfo.stringByReplacingCharactersInRange(range, withString: text)
            if newInfo.length > 0 {
                sendButton.enabled = true
                sendButton.alpha = 1
            } else {
                sendButton.enabled = false
                sendButton.alpha = 0.5
            }
            return true
    }

}
