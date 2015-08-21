//
//  FlagContentController.swift
//  SquirrelList
//
//  Created by Denis Geary Lopez on 8/10/15.
//  Copyright (c) 2015 Frenvu Inc. All rights reserved.
//


class FlagContentController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var reportTextView: UITextView!
    
    //Variable for storing if there is a squirrel owner
    var owner = ""
    //Variable for storing the squirrel id
    var squirrelID = ""
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func report(sender: AnyObject) {
        let report = PFObject(className: "Report")
        if owner != "" {
            report["offendingUsername"] = owner
        }
        report["explanation"] = reportTextView.text + "***Squirrel ID is \(squirrelID)"
        report["offendedUser"] = PFUser.currentUser()!.username!
        let alertController = UIAlertController(title: "Reported!", message: "We will review this and remove the offending content if it violates our Terms of Service.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            report.save()
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the close button icon to 'fa-times'
        closeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        closeButton.setTitle("\u{f00d}", forState: .Normal)
        //Set the report button to have rounded edges
        reportButton.layer.cornerRadius = 5
        reportButton.layer.masksToBounds = true
        //Make it obvious report button isn't initally enabled
        reportButton.alpha = 0.5
        reportTextView.delegate = self
    }
    
    
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
            //Make it so that pressing "done" dismisses the kayboard
            if text == "\n" {
                reportTextView.resignFirstResponder()
                return false
            }
            var oldInfo: NSString = reportTextView.text
            var newInfo: NSString = ""
            newInfo = oldInfo.stringByReplacingCharactersInRange(range, withString: text)
            if count(String(newInfo)) > 0  {
                reportButton.enabled = true
                reportButton.alpha = 1
            } else {
                reportButton.enabled = false
                reportButton.alpha = 0.5
            }
            return true
    }
 
    
}
